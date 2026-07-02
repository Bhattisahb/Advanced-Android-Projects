import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/index.dart';
import '../services/music_service.dart';

enum AudioRepeatMode { none, one, all }

enum LibrarySort { title, artist, album, newest, duration }

enum PlaybackContext { library, mostPlayed, userQueue, playlist }

/// Minimum listen to count toward score: 30s or 50% of track length.
const int _kMinListenMs = 30000;

const double _kMinListenFraction = 0.5;

const double _kCompletionFraction = 0.7;

const double _kManualSessionBase = 3;

const double _kAutoplaySessionBase = 1;

const double _kCompletionBonus = 2;

const int _kMostPlayedLimit = 10;

class MusicProvider extends ChangeNotifier {
  static const String _favoritesKey = 'favorite_song_keys';
  static const String _engagementKey = 'song_engagement_v1';
  static const String _legacyRecentlyPlayedKey = 'recently_played_song_keys';
  static const String _playlistsKey = 'user_playlists_v1';

  final AudioPlayer _audioPlayer = AudioPlayer();

  List<Song> _songs = [];
  List<Song> _filteredSongs = [];
  List<Song> _queue = [];
  List<Song> _playbackQueue = [];
  List<Song>? _queueBeforeShuffle;
  final Map<String, SongEngagement> _engagement = {};
  List<Song> _mostPlayed = [];
  PlaybackContext _playbackContext = PlaybackContext.library;
  String? _activePlaylistId;
  Song? _sessionSong;
  bool _sessionManual = false;
  int _currentIndex = 0;
  bool _isPlaying = false;
  bool _isLoading = false;
  int _scanFoundCount = 0;
  String _scanStatus = 'Preparing your library...';
  Duration _currentDuration = Duration.zero;
  Duration _totalDuration = Duration.zero;
  final Map<String, bool> _favorites = {};
  final List<Playlist> _playlists = [];
  bool _isShuffle = false;
  bool _autoPlay = true;
  AudioRepeatMode _repeatMode = AudioRepeatMode.none;
  String? _errorMessage;
  String? _snackMessage;
  String _searchQuery = '';
  bool _isInitialized = false;
  LibrarySort _librarySort = LibrarySort.title;

  // Getters
  List<Song> get songs => _filteredSongs.isEmpty ? _songs : _filteredSongs;
  List<Song> get allSongs => _songs;
  List<Song> get searchResults => _filteredSongs;
  List<Song> get mostPlayed => List.unmodifiable(_mostPlayed);
  bool isInMostPlayed(Song song) {
    final stats = _engagement[_favoriteKey(song)];
    return stats != null && stats.score > 0;
  }

  List<Song> get queue => _queue;
  String? get currentSongId => currentSong?.id;
  int get favoriteCount => getFavorites().length;
  List<Playlist> get playlists => List.unmodifiable(_playlists);
  int get playlistCount => _playlists.length;
  Song? get currentSong => _currentIndex >= 0 && _currentIndex < _playbackQueue.length
      ? _playbackQueue[_currentIndex]
      : null;
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  int get scanFoundCount => _scanFoundCount;
  String get scanStatus => _scanStatus;
  Duration get currentDuration => _currentDuration;
  Duration get totalDuration => _totalDuration;
  bool get isShuffle => _isShuffle;
  bool get autoPlay => _autoPlay;
  AudioRepeatMode get repeatMode => _repeatMode;
  int get currentIndex => _currentIndex;
  String? get errorMessage => _errorMessage;
  String? get snackMessage => _snackMessage;
  String get searchQuery => _searchQuery;
  LibrarySort get librarySort => _librarySort;
  List<String> get artists => _uniqueMetadata((song) => song.artist);
  List<String> get albums => _uniqueMetadata((song) => song.album);
  bool get scanComplete => !_isLoading;

  MusicProvider() {
    _setupAudioPlayer();
  }

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
    await _loadFavorites();
    await _loadEngagement();
    await _loadPlaylists();
  }

  void _setupAudioPlayer() {
    _audioPlayer.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      if (state.processingState == ProcessingState.completed) {
        _finalizeListeningSession(completed: true);
        unawaited(_onTrackCompleted());
      }
      notifyListeners();
    });

    _audioPlayer.positionStream.listen((duration) {
      _currentDuration = duration;
      notifyListeners();
    });

    _audioPlayer.durationStream.listen((duration) {
      _totalDuration = duration ?? Duration.zero;
      notifyListeners();
    });

    _audioPlayer.currentIndexStream.listen((index) {
      if (index == null || index < 0) return;
      if (index >= _playbackQueue.length) return;
      if (_currentIndex == index) return;
      _finalizeListeningSession();
      _currentIndex = index;
      _beginListeningSession(_playbackQueue[index], manual: false);
      notifyListeners();
    });
  }

  /// Builds the list used for [ConcatenatingAudioSource] and notification skip.
  /// User [queue] can be short; playback includes following library tracks when needed.
  void _syncCurrentIndexFromPlayer() {
    final playerIndex = _audioPlayer.currentIndex;
    if (playerIndex == null) return;
    if (playerIndex >= 0 && playerIndex < _playbackQueue.length) {
      _currentIndex = playerIndex;
    }
  }

  void _refreshPlaybackQueue({Song? anchor}) {
    if (_playbackContext == PlaybackContext.mostPlayed ||
        _playbackContext == PlaybackContext.playlist) {
      _playbackQueue = List.from(_queue);
      return;
    }

    if (_queue.length > 1 && _playbackContext == PlaybackContext.userQueue) {
      _playbackQueue = List.from(_queue);
      return;
    }

    if (_queue.isEmpty) {
      _playbackQueue = [];
      return;
    }

    final active = anchor ?? currentSong ?? _queue.first;

    if (!_autoPlay) {
      _playbackQueue = [active];
      return;
    }

    final sorted = sortedSongs();
    final startIndex = sorted.indexWhere((song) => song.id == active.id);
    if (startIndex == -1) {
      _playbackQueue = List.from(_queue);
      return;
    }

    var tail = sorted.sublist(startIndex);
    if (_isShuffle && tail.length > 1) {
      final current = tail.first;
      final rest = tail.sublist(1)..shuffle();
      tail = [current, ...rest];
    }
    _playbackQueue = tail;
  }

  void setSongs(List<Song> newSongs) {
    _songs = newSongs;
    _filteredSongs = [];
    _syncQueueWithLibrary();
    _applyFavoriteState();
    _pruneEngagement();
    _rebuildMostPlayed();
    _isLoading = false;
    _scanFoundCount = _songs.length;
    _scanStatus = _songs.isEmpty
        ? 'Scan complete. No songs found.'
        : 'Scan complete. Found ${_songs.length} songs.';
    _errorMessage = null;
    _setSnack(
      _songs.isEmpty
          ? 'Scan complete. No songs found.'
          : 'Found ${_songs.length} songs.',
    );
    notifyListeners();
  }

  void startSongScan() {
    _isLoading = true;
    _scanFoundCount = 0;
    _scanStatus = 'Scanning your music...';
    _errorMessage = null;
    notifyListeners();
  }

  void finishSongScanWithError(String message) {
    _songs = [];
    _filteredSongs = [];
    _queue = [];
    _playbackQueue = [];
    _isLoading = false;
    _scanFoundCount = 0;
    _scanStatus = message;
    _errorMessage = message;
    _setSnack(message);
    notifyListeners();
  }

  Future<void> refreshLibrary() async {
    startSongScan();
    try {
      final songs = await MusicService.loadSongs();
      setSongs(songs);
    } catch (e) {
      finishSongScanWithError('Failed to scan songs: $e');
    }
  }

  Future<void> playSong(Song song) async {
    try {
      _errorMessage = null;
      debugPrint('Playing: ${song.title} from ${song.filePath}');

      final existingPlaybackIndex = _playbackQueue.indexWhere(
        (s) => s.id == song.id,
      );
      if (_audioPlayer.audioSource != null &&
          existingPlaybackIndex != -1 &&
          (_playbackContext == PlaybackContext.mostPlayed ||
              _playbackContext == PlaybackContext.playlist ||
              _playbackContext == PlaybackContext.userQueue)) {
        _finalizeListeningSession();
        await _seekToPlaybackIndex(existingPlaybackIndex);
        _beginListeningSession(song, manual: true);
        return;
      }

      _finalizeListeningSession();
      _activePlaylistId = null;
      _playbackContext = PlaybackContext.library;

      final queueIndex = _queue.indexWhere((s) => s.id == song.id);
      if (queueIndex == -1) {
        _queue = [song];
        _queueBeforeShuffle = null;
        _isShuffle = false;
      } else if (_queue.length > 1) {
        _playbackContext = PlaybackContext.userQueue;
      }

      _refreshPlaybackQueue(anchor: song);
      final playbackIndex = _playbackQueue.indexWhere((s) => s.id == song.id);
      _currentIndex = playbackIndex == -1 ? 0 : playbackIndex;

      await _setQueueAudioSource(refreshQueue: false);
      await _audioPlayer.play();
      _beginListeningSession(song, manual: true);

      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to play song: $e';
      notifyListeners();
    }
  }

  /// Plays within the top [_kMostPlayedLimit] list only; next/previous stay in that set.
  Future<void> playFromMostPlayed(Song song) async {
    try {
      _errorMessage = null;
      _finalizeListeningSession();

      final list = List<Song>.from(_mostPlayed);
      if (list.isEmpty) {
        await playSong(song);
        return;
      }

      _activePlaylistId = null;
      _playbackContext = PlaybackContext.mostPlayed;
      _queue = list;
      _playbackQueue = List.from(list);
      _queueBeforeShuffle = null;
      _isShuffle = false;

      var index = list.indexWhere((s) => s.id == song.id);
      if (index == -1) {
        index = 0;
      }
      _currentIndex = index;

      await _setQueueAudioSource(refreshQueue: false);
      await _audioPlayer.play();
      _beginListeningSession(list[index], manual: true);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to play song: $e';
      notifyListeners();
    }
  }

  /// Clears engagement stats so the song leaves [mostPlayed]. Does not delete the file.
  Future<void> removeFromMostPlayed(Song song) async {
    final key = _favoriteKey(song);
    if (!_engagement.containsKey(key)) {
      _setSnack('Not in most played');
      notifyListeners();
      return;
    }

    if (_sessionSong?.id == song.id) {
      _finalizeListeningSession();
    }

    _engagement.remove(key);
    await _saveEngagement();
    _rebuildMostPlayed();

    final wasMostPlayedContext = _playbackContext == PlaybackContext.mostPlayed;
    final wasCurrent = currentSong?.id == song.id;

    if (wasMostPlayedContext) {
      if (_mostPlayed.isEmpty) {
        await stop();
        _playbackContext = PlaybackContext.library;
        _queue = [];
        _playbackQueue = [];
        _currentIndex = 0;
      } else {
        _queue = List.from(_mostPlayed);
        _playbackQueue = List.from(_mostPlayed);
        if (_audioPlayer.audioSource != null) {
          if (wasCurrent) {
            _currentIndex = 0;
            await _setQueueAudioSource(refreshQueue: false);
            await _audioPlayer.play();
            _beginListeningSession(_mostPlayed.first, manual: true);
          } else {
            final playing = currentSong;
            _currentIndex = playing == null
                ? 0
                : _mostPlayed.indexWhere((s) => s.id == playing.id);
            if (_currentIndex < 0) _currentIndex = 0;
            await _setQueueAudioSource(refreshQueue: false);
            if (_isPlaying) {
              await _audioPlayer.play();
            }
          }
        }
      }
    }

    _setSnack('Removed from most played');
    notifyListeners();
  }

  Future<void> copySongPath(Song song) async {
    if (song.filePath.isEmpty) {
      _setSnack('No file path available');
      notifyListeners();
      return;
    }
    await Clipboard.setData(ClipboardData(text: song.filePath));
    _setSnack('Path copied');
    notifyListeners();
  }

  /// Permanently deletes the audio file and removes it from the in-app library.
  Future<bool> deleteSongFromDevice(Song song) async {
    if (song.filePath.isEmpty) {
      _setSnack('No file to delete');
      notifyListeners();
      return false;
    }

    if (_sessionSong?.id == song.id) {
      _finalizeListeningSession();
    }

    final wasCurrent = currentSong?.id == song.id;
    if (wasCurrent) {
      await stop();
    }

    final deleteResult = await MusicService.deleteSongFromDevice(song);

    switch (deleteResult) {
      case DeleteMediaResult.deleted:
        _purgeSongFromAppState(song);
        _setSnack('Deleted from device');
        notifyListeners();
        return true;
      case DeleteMediaResult.cancelled:
        _setSnack('Delete cancelled');
        notifyListeners();
        return false;
      case DeleteMediaResult.needAllFilesAccess:
        _setSnack(
          'Allow the delete prompt if shown, or enable All files access and retry',
        );
        notifyListeners();
        await MusicService.openAllFilesAccessSettings();
        return false;
      case DeleteMediaResult.failed:
        _setSnack(
          'Tap Allow on the system delete dialog, or enable All files access',
        );
        notifyListeners();
        if (!await MusicService.hasAllFilesAccess()) {
          await MusicService.openAllFilesAccessSettings();
        }
        return false;
    }
  }

  void _purgeSongFromAppState(Song song) {
    final key = _favoriteKey(song);
    _songs.removeWhere((item) => item.id == song.id);
    _filteredSongs.removeWhere((item) => item.id == song.id);
    _queue.removeWhere((item) => item.id == song.id);
    _playbackQueue.removeWhere((item) => item.id == song.id);
    _favorites.remove(key);
    _engagement.remove(key);
    for (final playlist in _playlists) {
      playlist.removeSongKey(key);
    }
    _rebuildMostPlayed();

    if (_playbackQueue.isEmpty) {
      _playbackContext = PlaybackContext.library;
      _currentIndex = 0;
    } else if (_currentIndex >= _playbackQueue.length) {
      _currentIndex = _playbackQueue.length - 1;
    }

    unawaited(_saveFavorites());
    unawaited(_saveEngagement());
    unawaited(_savePlaylists());
  }

  Playlist? playlistById(String id) {
    for (final playlist in _playlists) {
      if (playlist.id == id) return playlist;
    }
    return null;
  }

  List<Playlist> sortedPlaylists() {
    final copy = List<Playlist>.from(_playlists);
    copy.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return copy;
  }

  List<Song> songsInPlaylist(Playlist playlist) {
    final byKey = <String, Song>{
      for (final song in _songs) _favoriteKey(song): song,
    };
    return playlist.songKeys
        .map((key) => byKey[key])
        .whereType<Song>()
        .toList();
  }

  int songCountInPlaylist(String playlistId) {
    final playlist = playlistById(playlistId);
    if (playlist == null) return 0;
    return songsInPlaylist(playlist).length;
  }

  bool isSongInPlaylist(String playlistId, Song song) {
    final playlist = playlistById(playlistId);
    if (playlist == null) return false;
    return playlist.containsKey(_favoriteKey(song));
  }

  Future<Playlist?> createPlaylist(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      _setSnack('Enter a playlist name');
      notifyListeners();
      return null;
    }

    final playlist = Playlist(
      id: 'pl_${DateTime.now().millisecondsSinceEpoch}',
      name: trimmed,
    );
    _playlists.add(playlist);
    await _savePlaylists();
    _setSnack('Playlist created');
    notifyListeners();
    return playlist;
  }

  Future<void> renamePlaylist(String playlistId, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      _setSnack('Enter a playlist name');
      notifyListeners();
      return;
    }

    final playlist = playlistById(playlistId);
    if (playlist == null) return;

    playlist.name = trimmed;
    await _savePlaylists();
    _setSnack('Playlist renamed');
    notifyListeners();
  }

  Future<void> deletePlaylist(String playlistId) async {
    _playlists.removeWhere((p) => p.id == playlistId);
    await _savePlaylists();
    _setSnack('Playlist deleted');
    notifyListeners();
  }

  Future<void> addSongToPlaylist(String playlistId, Song song) async {
    final playlist = playlistById(playlistId);
    if (playlist == null) return;

    final key = _favoriteKey(song);
    if (playlist.containsKey(key)) {
      _setSnack('Already in ${playlist.name}');
      notifyListeners();
      return;
    }

    playlist.addSongKey(key);
    await _savePlaylists();
    _setSnack('Added to ${playlist.name}');
    notifyListeners();
  }

  Future<void> removeSongFromPlaylist(String playlistId, Song song) async {
    final playlist = playlistById(playlistId);
    if (playlist == null) return;

    playlist.removeSongKey(_favoriteKey(song));
    await _savePlaylists();
    _setSnack('Removed from ${playlist.name}');
    notifyListeners();
  }

  void reorderPlaylistSongs(String playlistId, int oldIndex, int newIndex) {
    final playlist = playlistById(playlistId);
    if (playlist == null) return;
    if (oldIndex < 0 || oldIndex >= playlist.songKeys.length) return;

    final key = playlist.songKeys.removeAt(oldIndex);
    var target = newIndex;
    if (target > oldIndex) target -= 1;
    playlist.songKeys.insert(
      target.clamp(0, playlist.songKeys.length),
      key,
    );
    unawaited(_savePlaylists());

    if (_activePlaylistId == playlistId &&
        _playbackContext == PlaybackContext.playlist) {
      final songs = songsInPlaylist(playlist);
      _queue = List.from(songs);
      _playbackQueue = List.from(songs);
      final playing = currentSong;
      if (playing != null) {
        final idx = _queue.indexWhere((s) => s.id == playing.id);
        if (idx != -1) _currentIndex = idx;
      }
      if (_audioPlayer.audioSource != null) {
        unawaited(_reloadQueueAudioSource());
      }
    }

    notifyListeners();
  }

  /// Plays songs in playlist order; next/previous stay within this playlist.
  Future<void> playFromPlaylist(Song song, Playlist playlist) async {
    try {
      _errorMessage = null;
      _finalizeListeningSession();

      final list = songsInPlaylist(playlist);
      if (list.isEmpty) {
        _setSnack('Playlist is empty');
        notifyListeners();
        return;
      }

      _activePlaylistId = playlist.id;
      _playbackContext = PlaybackContext.playlist;
      _queue = List.from(list);
      _playbackQueue = List.from(list);
      _queueBeforeShuffle = null;
      _isShuffle = false;

      var index = list.indexWhere((s) => s.id == song.id);
      if (index == -1) index = 0;
      _currentIndex = index;

      await _setQueueAudioSource(refreshQueue: false);
      _syncCurrentIndexFromPlayer();
      await _audioPlayer.play();
      _isPlaying = true;
      _beginListeningSession(list[index], manual: true);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to play song: $e';
      notifyListeners();
    }
  }

  Future<void> playPlaylist(Playlist playlist) async {
    final songs = songsInPlaylist(playlist);
    if (songs.isEmpty) {
      _setSnack('Playlist is empty');
      notifyListeners();
      return;
    }

    try {
      _errorMessage = null;
      _finalizeListeningSession();

      _activePlaylistId = playlist.id;
      _playbackContext = PlaybackContext.playlist;
      _queue = List.from(songs);
      _playbackQueue = List.from(songs);
      _queueBeforeShuffle = null;
      _isShuffle = false;
      _currentIndex = 0;

      await _setQueueAudioSource(refreshQueue: false);
      _syncCurrentIndexFromPlayer();
      await _audioPlayer.play();
      _isPlaying = true;
      _beginListeningSession(songs.first, manual: true);
      _setSnack('Playing ${playlist.name}');
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to play playlist: $e';
      notifyListeners();
    }
  }

  Future<void> _loadPlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_playlistsKey);
    _playlists.clear();
    if (raw == null || raw.isEmpty) {
      notifyListeners();
      return;
    }

    try {
      final list = jsonDecode(raw) as List<dynamic>;
      for (final item in list) {
        if (item is Map<String, dynamic>) {
          _playlists.add(Playlist.fromJson(item));
        } else if (item is Map) {
          _playlists.add(
            Playlist.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    } catch (e) {
      debugPrint('Failed to load playlists: $e');
    }
    notifyListeners();
  }

  Future<void> _savePlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_playlists.map((p) => p.toJson()).toList());
    await prefs.setString(_playlistsKey, encoded);
  }

  Future<void> play() async {
    try {
      _errorMessage = null;
      await _audioPlayer.play();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to play: $e';
      notifyListeners();
    }
  }

  Future<void> pause() async {
    try {
      await _audioPlayer.pause();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to pause: $e';
      notifyListeners();
    }
  }

  Future<void> next() async {
    if (_playbackQueue.isEmpty) {
      _refreshPlaybackQueue();
    }
    if (_playbackQueue.isEmpty) return;

    _syncCurrentIndexFromPlayer();

    if (!_autoPlay || _playbackQueue.length <= 1) {
      if (_isBoundedPlaybackContext) {
        await _skipInBoundedQueue(forward: true);
        return;
      }
      await _skipInLibrary(forward: true);
      return;
    }

    if (_audioPlayer.audioSource != null && _audioPlayer.hasNext) {
      await _audioPlayer.seekToNext();
      await _audioPlayer.play();
      _syncCurrentIndexFromPlayer();
      notifyListeners();
      return;
    }

    if (_repeatMode == AudioRepeatMode.all) {
      await _seekToPlaybackIndex(0);
    }
  }

  Future<void> previous() async {
    if (_playbackQueue.isEmpty) {
      _refreshPlaybackQueue();
    }
    if (_playbackQueue.isEmpty) return;

    _syncCurrentIndexFromPlayer();

    if (_currentDuration.inSeconds > 3) {
      await _audioPlayer.seek(Duration.zero);
      notifyListeners();
      return;
    }

    if (!_autoPlay || _playbackQueue.length <= 1) {
      if (_isBoundedPlaybackContext) {
        await _skipInBoundedQueue(forward: false);
        return;
      }
      await _skipInLibrary(forward: false);
      return;
    }

    if (_audioPlayer.audioSource != null && _audioPlayer.hasPrevious) {
      await _audioPlayer.seekToPrevious();
      await _audioPlayer.play();
      _syncCurrentIndexFromPlayer();
      notifyListeners();
      return;
    }

    if (_repeatMode == AudioRepeatMode.all) {
      await _seekToPlaybackIndex(_playbackQueue.length - 1);
    }
  }

  Future<void> _seekToPlaybackIndex(int index) async {
    if (_playbackQueue.isEmpty) return;

    final targetIndex = index.clamp(0, _playbackQueue.length - 1);
    try {
      _finalizeListeningSession();
      await _audioPlayer.seek(Duration.zero, index: targetIndex);
      await _audioPlayer.play();
      _syncCurrentIndexFromPlayer();
      if (_currentIndex >= 0 && _currentIndex < _playbackQueue.length) {
        _beginListeningSession(
          _playbackQueue[_currentIndex],
          manual: false,
        );
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to change track: $e';
      notifyListeners();
    }
  }

  bool get _isBoundedPlaybackContext =>
      _playbackContext == PlaybackContext.mostPlayed ||
      _playbackContext == PlaybackContext.playlist;

  Future<void> _skipInBoundedQueue({required bool forward}) async {
    if (_playbackQueue.isEmpty) return;

    _syncCurrentIndexFromPlayer();
    var index = _currentIndex;

    if (forward) {
      index++;
      if (index >= _playbackQueue.length) {
        if (_repeatMode == AudioRepeatMode.all) {
          index = 0;
        } else {
          return;
        }
      }
    } else {
      index--;
      if (index < 0) {
        if (_repeatMode == AudioRepeatMode.all) {
          index = _playbackQueue.length - 1;
        } else {
          return;
        }
      }
    }

    await _seekToPlaybackIndex(index);
  }

  Future<void> _skipInLibrary({required bool forward}) async {
    _syncCurrentIndexFromPlayer();

    if (_playbackQueue.length > 1 && _audioPlayer.audioSource != null) {
      if (forward) {
        if (_audioPlayer.hasNext) {
          await _audioPlayer.seekToNext();
        } else if (_repeatMode == AudioRepeatMode.all) {
          await _seekToPlaybackIndex(0);
        }
      } else if (_audioPlayer.hasPrevious) {
        await _audioPlayer.seekToPrevious();
      } else if (_repeatMode == AudioRepeatMode.all) {
        await _seekToPlaybackIndex(_playbackQueue.length - 1);
      }
      await _audioPlayer.play();
      _syncCurrentIndexFromPlayer();
      notifyListeners();
      return;
    }

    final sorted = sortedSongs();
    final playing = currentSong;
    if (playing == null || sorted.isEmpty) return;

    var index = sorted.indexWhere((song) => song.id == playing.id);
    if (index == -1) return;

    if (forward) {
      index++;
      if (index >= sorted.length) {
        if (_repeatMode == AudioRepeatMode.all) {
          index = 0;
        } else {
          return;
        }
      }
    } else {
      index--;
      if (index < 0) {
        if (_repeatMode == AudioRepeatMode.all) {
          index = sorted.length - 1;
        } else {
          return;
        }
      }
    }

    await playSong(sorted[index]);
  }

  Future<void> _onTrackCompleted() async {
    if (_repeatMode == AudioRepeatMode.one) return;

    if (!_autoPlay) {
      await pause();
      return;
    }

    // ConcatenatingAudioSource advances automatically when more tracks remain.
    if (_audioPlayer.hasNext) return;

    if (_repeatMode != AudioRepeatMode.all) {
      await pause();
    }
  }

  Future<void> toggleAutoPlay() async {
    _autoPlay = !_autoPlay;
    _setSnack(_autoPlay ? 'Autoplay on' : 'Autoplay off');

    if (currentSong != null && _audioPlayer.audioSource != null) {
      try {
        final position = _currentDuration;
        _refreshPlaybackQueue(anchor: currentSong);
        await _setQueueAudioSource(
          initialPosition: position,
          refreshQueue: false,
        );
        if (_isPlaying) {
          await _audioPlayer.play();
        }
        await _applyLoopMode();
      } catch (e) {
        _errorMessage = 'Failed to update autoplay: $e';
      }
    }

    notifyListeners();
  }

  Future<void> seek(Duration position) async {
    try {
      await _audioPlayer.seek(position);
    } catch (e) {
      _errorMessage = 'Failed to seek: $e';
      notifyListeners();
    }
  }

  void toggleShuffle() {
    if (_queue.isEmpty) {
      _isShuffle = !_isShuffle;
      notifyListeners();
      return;
    }

    final selectedSong = currentSong;
    _isShuffle = !_isShuffle;
    if (_isShuffle) {
      _queueBeforeShuffle = List.from(_queue);
      _queue.shuffle();
      _currentIndex = _queue.indexWhere((s) => s.id == selectedSong?.id);
    } else if (_queueBeforeShuffle != null) {
      _queue = List.from(_queueBeforeShuffle!);
      _queueBeforeShuffle = null;
      _currentIndex = _queue.indexWhere((s) => s.id == selectedSong?.id);
    }
    if (_currentIndex == -1) _currentIndex = 0;
    if (_playbackContext == PlaybackContext.playlist) {
      _playbackQueue = List.from(_queue);
    }
    if (_audioPlayer.audioSource != null) {
      _refreshPlaybackQueue(anchor: selectedSong);
      final playbackIndex = selectedSong == null
          ? _currentIndex
          : _playbackQueue.indexWhere((s) => s.id == selectedSong.id);
      if (playbackIndex != -1) {
        _currentIndex = playbackIndex;
      }
      unawaited(_reloadQueueAudioSource());
    }
    notifyListeners();
  }

  void _syncQueueWithLibrary() {
    if (_queue.isEmpty) return;

    final currentId = currentSong?.id;
    _queue = _queue
        .map((queued) {
          for (final song in _songs) {
            if (song.id == queued.id) return song;
          }
          return null;
        })
        .whereType<Song>()
        .toList();

    _queueBeforeShuffle = null;

    if (currentId != null) {
      final playbackIndex = _playbackQueue.indexWhere(
        (song) => song.id == currentId,
      );
      if (playbackIndex != -1) {
        _currentIndex = playbackIndex;
      } else {
        final queueIndex = _queue.indexWhere((song) => song.id == currentId);
        if (queueIndex != -1) {
          _currentIndex = queueIndex;
        }
      }
    }
    if (_currentIndex >= _playbackQueue.length) {
      _currentIndex = _playbackQueue.isEmpty ? 0 : _playbackQueue.length - 1;
    }
  }

  Future<void> toggleRepeatMode() async {
    _repeatMode = AudioRepeatMode
        .values[(_repeatMode.index + 1) % AudioRepeatMode.values.length];
    await _applyLoopMode();
    notifyListeners();
  }

  Future<void> _applyLoopMode() async {
    await _audioPlayer.setLoopMode(switch (_repeatMode) {
      AudioRepeatMode.none => LoopMode.off,
      AudioRepeatMode.one => LoopMode.one,
      AudioRepeatMode.all => LoopMode.all,
    });
  }

  Future<void> toggleFavorite(Song song) async {
    final key = _favoriteKey(song);
    final isNowFavorite = !(_favorites[key] ?? false);
    _favorites[key] = isNowFavorite;
    song.isFavorite = _favorites[key] ?? false;
    await _saveFavorites();
    _setSnack(
      isNowFavorite ? 'Added to liked songs' : 'Removed from liked songs',
    );
    notifyListeners();
  }

  bool isFavorite(Song song) => _favorites[_favoriteKey(song)] ?? false;

  List<Song> getFavorites() => _songs.where(isFavorite).toList();

  List<Song> sortedSongs([List<Song>? source]) {
    final sorted = List<Song>.from(source ?? _songs);
    switch (_librarySort) {
      case LibrarySort.title:
        sorted.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
      case LibrarySort.artist:
        sorted.sort(
          (a, b) => a.artist.toLowerCase().compareTo(b.artist.toLowerCase()),
        );
      case LibrarySort.album:
        sorted.sort(
          (a, b) => a.album.toLowerCase().compareTo(b.album.toLowerCase()),
        );
      case LibrarySort.newest:
        sorted.sort(
          (a, b) =>
              int.tryParse(b.id)?.compareTo(int.tryParse(a.id) ?? 0) ??
              b.id.compareTo(a.id),
        );
      case LibrarySort.duration:
        sorted.sort((a, b) => b.duration.compareTo(a.duration));
    }
    return sorted;
  }

  void setLibrarySort(LibrarySort sort) {
    _librarySort = sort;
    _setSnack('Sorted by ${_librarySortLabel(sort)}');
    notifyListeners();
  }

  void searchSongs(String query) {
    _searchQuery = query.trim();
    if (_searchQuery.isEmpty) {
      _filteredSongs = [];
    } else {
      final lowerQuery = _searchQuery.toLowerCase();
      _filteredSongs = _songs
          .where(
            (song) =>
                song.title.toLowerCase().contains(lowerQuery) ||
                song.artist.toLowerCase().contains(lowerQuery) ||
                song.album.toLowerCase().contains(lowerQuery),
          )
          .toList();
    }
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _filteredSongs = [];
    notifyListeners();
  }

  List<Song> songsByArtist(String artist) {
    return _songs.where((song) => song.artist == artist).toList();
  }

  List<Song> songsByAlbum(String album) {
    return _songs.where((song) => song.album == album).toList();
  }

  void setQueue(List<Song> newQueue) {
    _queue = newQueue;
    _currentIndex = 0;
    _playbackContext = newQueue.length > 1
        ? PlaybackContext.userQueue
        : PlaybackContext.library;
    _setSnack('Queue updated');
    notifyListeners();
  }

  void addToQueue(Song song) {
    _queue.add(song);
    _setSnack('Added to queue');
    notifyListeners();
  }

  void playNext(Song song) {
    final playing = currentSong;
    final queuePlayingIndex = playing == null
        ? -1
        : _queue.indexWhere((item) => item.id == playing.id);
    final insertIndex = _queue.isEmpty
        ? 0
        : (queuePlayingIndex == -1
                  ? _queue.length
                  : queuePlayingIndex + 1)
              .clamp(0, _queue.length)
              .toInt();
    _queue.removeWhere((item) => item.id == song.id);
    _queue.insert(insertIndex.clamp(0, _queue.length).toInt(), song);
    _setSnack('Playing next');
    if (_audioPlayer.audioSource != null) {
      unawaited(_reloadQueueAudioSource());
    }
    notifyListeners();
  }

  void reorderQueue(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _queue.length) return;

    final selectedSong = currentSong;
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    final movedSong = _queue.removeAt(oldIndex);
    final safeNewIndex = newIndex.clamp(0, _queue.length).toInt();
    _queue.insert(safeNewIndex, movedSong);

    if (selectedSong != null) {
      _currentIndex = _queue.indexWhere((song) => song.id == selectedSong.id);
      if (_currentIndex == -1) _currentIndex = 0;
    }

    if (_audioPlayer.audioSource != null) {
      unawaited(_reloadQueueAudioSource());
    }
    notifyListeners();
  }

  Future<void> _setQueueAudioSource({
    Duration initialPosition = Duration.zero,
    bool refreshQueue = true,
    Song? anchor,
  }) async {
    if (refreshQueue) {
      _refreshPlaybackQueue(anchor: anchor ?? currentSong);
    }
    if (_playbackQueue.isEmpty) return;

    _currentIndex = _currentIndex.clamp(0, _playbackQueue.length - 1);
    await _audioPlayer.setAudioSource(
      _buildQueueAudioSource(),
      initialIndex: _currentIndex,
      initialPosition: initialPosition,
    );
    await _applyLoopMode();
  }

  Future<void> _reloadQueueAudioSource() async {
    try {
      final wasPlaying = _isPlaying;
      final position = _currentDuration;
      await _setQueueAudioSource(
        initialPosition: position,
        refreshQueue: _playbackContext != PlaybackContext.playlist &&
            _playbackContext != PlaybackContext.mostPlayed,
      );
      if (wasPlaying) {
        await _audioPlayer.play();
      }
    } catch (e) {
      _errorMessage = 'Failed to update playback queue: $e';
      notifyListeners();
    }
  }

  ConcatenatingAudioSource _buildQueueAudioSource() {
    return ConcatenatingAudioSource(
      children: _playbackQueue.map(_songAudioSource).toList(),
    );
  }

  AudioSource _songAudioSource(Song song) {
    return AudioSource.uri(
      Uri.file(song.filePath),
      tag: MediaItem(
        id: _favoriteKey(song),
        title: song.title,
        artist: song.artist,
        album: song.album,
        duration: song.duration == Duration.zero ? null : song.duration,
        artUri: song.albumArt == null ? null : Uri.file(song.albumArt!),
      ),
    );
  }

  String _favoriteKey(Song song) {
    return song.filePath.isNotEmpty ? song.filePath : song.id;
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getStringList(_favoritesKey) ?? [];
    _favorites
      ..clear()
      ..addEntries(keys.map((key) => MapEntry(key, true)));
    _applyFavoriteState();
    notifyListeners();
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = _favorites.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
    await prefs.setStringList(_favoritesKey, keys);
  }

  void _applyFavoriteState() {
    for (final song in _songs) {
      song.isFavorite = isFavorite(song);
    }
  }

  void _beginListeningSession(Song song, {required bool manual}) {
    _sessionSong = song;
    _sessionManual = manual;
  }

  void _finalizeListeningSession({bool completed = false}) {
    final song = _sessionSong;
    if (song == null) return;

    final key = _favoriteKey(song);
    final stats = _engagement.putIfAbsent(key, SongEngagement.new);
    final listenedMs = _currentDuration.inMilliseconds;
    final durationMs = _effectiveDurationMs(song);

    if (_sessionManual) {
      stats.manualStarts++;
    } else {
      stats.autoplayStarts++;
    }

    final base = _sessionManual ? _kManualSessionBase : _kAutoplaySessionBase;
    final minListenMs = durationMs <= 0
        ? _kMinListenMs
        : math.min(_kMinListenMs, (durationMs * _kMinListenFraction).round());

    if (durationMs > 0 && listenedMs >= minListenMs) {
      final ratio = (listenedMs / durationMs).clamp(0.0, 1.0);
      stats.score += base * ratio;
      final completionThreshold = (durationMs * _kCompletionFraction).round();
      if (completed || listenedMs >= completionThreshold) {
        stats.score += _kCompletionBonus;
        stats.completedCount++;
      }
    } else {
      stats.skipCount++;
    }

    _sessionSong = null;
    unawaited(_persistEngagementAndRebuild());
  }

  int _effectiveDurationMs(Song song) {
    final playerMs = _totalDuration.inMilliseconds;
    if (playerMs > 0) return playerMs;
    return song.duration.inMilliseconds;
  }

  Future<void> _persistEngagementAndRebuild() async {
    await _saveEngagement();
    _rebuildMostPlayed();
    notifyListeners();
  }

  void _rebuildMostPlayed() {
    final ranked =
        <({Song song, double score, int completed, String title})>[];
    for (final song in _songs) {
      final stats = _engagement[_favoriteKey(song)];
      if (stats == null || stats.score <= 0) continue;
      ranked.add((
        song: song,
        score: stats.score,
        completed: stats.completedCount,
        title: song.title.toLowerCase(),
      ));
    }

    ranked.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      final byCompleted = b.completed.compareTo(a.completed);
      if (byCompleted != 0) return byCompleted;
      return a.title.compareTo(b.title);
    });

    _mostPlayed = ranked.take(_kMostPlayedLimit).map((e) => e.song).toList();
  }

  void _pruneEngagement() {
    final libraryKeys = _songs.map(_favoriteKey).toSet();
    _engagement.removeWhere((key, _) => !libraryKeys.contains(key));
  }

  Future<void> _loadEngagement() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_engagementKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        for (final entry in decoded.entries) {
          if (entry.value is Map<String, dynamic>) {
            _engagement[entry.key] = SongEngagement.fromJson(
              entry.value as Map<String, dynamic>,
            );
          }
        }
      } catch (e) {
        debugPrint('Failed to load engagement: $e');
      }
    }

    await _migrateLegacyRecentlyPlayed(prefs);
    _pruneEngagement();
    _rebuildMostPlayed();
    notifyListeners();
  }

  Future<void> _migrateLegacyRecentlyPlayed(SharedPreferences prefs) async {
    final legacy = prefs.getStringList(_legacyRecentlyPlayedKey);
    if (legacy == null || legacy.isEmpty) return;

    for (final key in legacy) {
      final stats = _engagement.putIfAbsent(key, SongEngagement.new);
      stats.score += 1.5;
      stats.manualStarts++;
    }
    await prefs.remove(_legacyRecentlyPlayedKey);
    await _saveEngagement();
  }

  Future<void> _saveEngagement() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = _engagement.map(
      (key, value) => MapEntry(key, value.toJson()),
    );
    await prefs.setString(_engagementKey, jsonEncode(payload));
  }

  String? takeSnackMessage() {
    final message = _snackMessage;
    _snackMessage = null;
    return message;
  }

  void _setSnack(String message) {
    _snackMessage = message;
  }

  String _librarySortLabel(LibrarySort sort) {
    return switch (sort) {
      LibrarySort.title => 'title',
      LibrarySort.artist => 'artist',
      LibrarySort.album => 'album',
      LibrarySort.newest => 'newest',
      LibrarySort.duration => 'duration',
    };
  }

  List<String> _uniqueMetadata(String Function(Song song) selector) {
    final values =
        _songs
            .map(selector)
            .where(
              (value) =>
                  value.trim().isNotEmpty &&
                  !value.toLowerCase().startsWith('unknown'),
            )
            .toSet()
            .toList()
          ..sort();
    return values;
  }

  Future<void> stop() async {
    _finalizeListeningSession();
    await _audioPlayer.stop();
  }

  @override
  void dispose() {
    _finalizeListeningSession();
    _audioPlayer.dispose();
    super.dispose();
  }
}

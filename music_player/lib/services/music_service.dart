import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/index.dart';
import 'file_actions_service.dart';

export 'file_actions_service.dart' show DeleteMediaResult;

class MusicService {
  static final OnAudioQuery _audioQuery = OnAudioQuery();

  static const List<String> audioExtensions = [
    '.mp3',
    '.m4a',
    '.wav',
    '.flac',
    '.aac',
    '.ogg',
    '.opus',
    '.wma',
    '.aiff',
  ];

  static const List<String> restrictedDirs = [
    'Android',
    '.android',
    'system',
    'proc',
    'sys',
    'lost+found',
    '.cache',
    'cache',
    '.Trash',
    'trash',
    'systemdata',
    '.systemdata',
    // Messaging apps
    'WhatsApp',
    'whatsapp',
    'Telegram',
    'telegram',
    'Signal',
    'signal',
    'Messenger',
    'messenger',
    'Viber',
    'viber',
    'Skype',
    'skype',
    'Discord',
    'discord',
    // Social media
    'TikTok',
    'tiktok',
    'Instagram',
    'instagram',
    'Snapchat',
    'snapchat',
    // Video/streaming apps
    'YouTube',
    'youtube',
    'Netflix',
    'netflix',
    'Spotify',
    'spotify',
    // Other
    'Downloads',
    'Temp',
    '.tmp',
  ];

  static Future<List<Song>> loadSongs() async {
    try {
      // Request permissions
      PermissionStatus status = await _requestPermissions();

      if (!status.isGranted) {
        debugPrint('Audio/Storage permission denied');
        return [];
      }

      debugPrint('Permissions granted, loading music metadata...');

      final mediaStoreSongs = await _loadSongsFromMediaStore();
      if (mediaStoreSongs.isNotEmpty) {
        debugPrint('MediaStore loaded ${mediaStoreSongs.length} songs');
        return mediaStoreSongs;
      }

      debugPrint(
        'No MediaStore songs found, starting comprehensive music scan...',
      );
      final songs = <Song>[];

      // Primary scan: /storage/emulated/0 (main external storage)
      final primaryPath = '/storage/emulated/0';
      debugPrint('Scanning primary storage: $primaryPath');
      _scanDirectoryRecursive(primaryPath, songs, depth: 0);

      // Fallback scan: /sdcard (if different)
      if (!primaryPath.contains('sdcard')) {
        final sdcardPath = '/sdcard';
        try {
          if (Directory(sdcardPath).existsSync()) {
            debugPrint('Scanning sdcard: $sdcardPath');
            _scanDirectoryRecursive(sdcardPath, songs, depth: 0);
          }
        } catch (e) {
          debugPrint('sdcard not accessible: $e');
        }
      }

      // Remove duplicates
      final uniqueSongs = <String, Song>{};
      for (var song in songs) {
        uniqueSongs[song.filePath] = song;
      }

      debugPrint('Scan complete! Found ${uniqueSongs.length} music files');
      return uniqueSongs.values.toList();
    } catch (e) {
      debugPrint('Error loading songs: $e');
      return [];
    }
  }

  static Future<PermissionStatus> _requestPermissions() async {
    // Try audio permission first (Android 13+)
    PermissionStatus status = await Permission.audio.request();
    if (status.isGranted) {
      await _audioQuery.permissionsRequest();
      await Permission.notification.request();
      return status;
    }

    // Fallback to storage permission
    status = await Permission.storage.request();
    if (status.isGranted) {
      await _audioQuery.permissionsRequest();
      await Permission.notification.request();
      return status;
    }

    // Last resort: manage external storage
    status = await Permission.manageExternalStorage.request();
    if (status.isGranted) {
      await _audioQuery.permissionsRequest();
      await Permission.notification.request();
    }
    return status;
  }

  static Future<List<Song>> _loadSongsFromMediaStore() async {
    try {
      final songs = await _audioQuery.querySongs(
        sortType: SongSortType.TITLE,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );

      return songs
          .where((song) => song.data.isNotEmpty && _isMusicFile(song.data))
          .map(
            (song) => Song(
              id: song.id.toString(),
              mediaId: song.id,
              title: song.title.trim().isEmpty ? 'Unknown Title' : song.title,
              artist: _cleanMetadata(song.artist, 'Unknown Artist'),
              album: _cleanMetadata(song.album, 'Unknown Album'),
              filePath: song.data,
              duration: Duration(milliseconds: song.duration ?? 0),
            ),
          )
          .toList();
    } catch (e) {
      debugPrint('MediaStore query failed: $e');
      return [];
    }
  }

  static String _cleanMetadata(String? value, String fallback) {
    if (value == null || value.trim().isEmpty || value == '<unknown>') {
      return fallback;
    }
    return value.trim();
  }

  static void _scanDirectoryRecursive(
    String path,
    List<Song> songs, {
    int depth = 0,
  }) {
    // Prevent infinite deep recursion
    if (depth > 10) return;

    try {
      final dir = Directory(path);
      if (!dir.existsSync()) return;

      List<FileSystemEntity> items;
      try {
        items = dir.listSync(followLinks: false);
      } catch (e) {
        debugPrint('Cannot read: $path ($e)');
        return;
      }

      for (var item in items) {
        try {
          // Skip restricted directories
          if (_isRestrictedPath(item.path)) {
            continue;
          }

          if (item is File) {
            // Check if it's an audio file
            if (_isMusicFile(item.path)) {
              final song = _createSongFromFile(item, songs.length);
              if (song != null) {
                songs.add(song);
                debugPrint('Found: ${song.title}');
              }
            }
          } else if (item is Directory) {
            // Recursively scan subdirectories
            _scanDirectoryRecursive(item.path, songs, depth: depth + 1);
          }
        } catch (e) {
          // Skip problematic items and continue
          continue;
        }
      }
    } catch (e) {
      debugPrint('Error scanning directory $path: $e');
    }
  }

  static bool _isRestrictedPath(String path) {
    final pathLower = path.toLowerCase();

    // Skip if inside Android/data or Android/media (system app directories)
    if (pathLower.contains('/android/data/') ||
        pathLower.contains('/android/media/') ||
        pathLower.contains('\\android\\data\\') ||
        pathLower.contains('\\android\\media\\')) {
      return true;
    }

    // Check against restricted directory list
    for (var restricted in restrictedDirs) {
      final restrictedLower = restricted.toLowerCase();
      if (pathLower.contains('/$restrictedLower') ||
          pathLower.contains('\\$restrictedLower') ||
          pathLower.endsWith('/$restrictedLower') ||
          pathLower.endsWith('\\$restrictedLower')) {
        return true;
      }
    }

    // Skip hidden files/folders (starting with .)
    if (path.split('/').last.startsWith('.')) {
      return true;
    }

    return false;
  }

  static bool _isMusicFile(String path) {
    final pathLower = path.toLowerCase();
    return audioExtensions.any((ext) => pathLower.endsWith(ext));
  }

  static Song? _createSongFromFile(File file, int index) {
    try {
      final filePath = file.path;
      final fileName = filePath.split('/').last;
      final nameWithoutExt = fileName
          .replaceAll(RegExp(r'\.[^.]*$'), '')
          .trim();

      // Parse title and artist from filename
      // Supports formats: "Artist - Title" or just "Title"
      String title = nameWithoutExt;
      String artist = 'Unknown Artist';

      if (nameWithoutExt.contains('-')) {
        final parts = nameWithoutExt.split('-');
        if (parts.length >= 2) {
          artist = parts[0].trim();
          title = parts.sublist(1).join('-').trim();
        }
      }

      // Extract album from directory structure if possible
      final dirParts = filePath.split('/');
      String album = 'Unknown Album';
      if (dirParts.length > 2) {
        album = dirParts[dirParts.length - 2];
      }

      return Song(
        id: index.toString(),
        mediaId: null,
        title: title.isEmpty ? fileName : title,
        artist: artist,
        album: album,
        filePath: filePath,
        duration: Duration.zero,
      );
    } catch (e) {
      debugPrint('Error creating song: $e');
      return null;
    }
  }

  /// Opens Android settings for "All files access" (not in the normal permission list).
  static Future<bool> openAllFilesAccessSettings() async {
    return FileActionsService.openAllFilesAccessSettings();
  }

  static Future<bool> hasAllFilesAccess() async {
    return FileActionsService.hasAllFilesAccess();
  }

  /// Permanently deletes the audio file from device storage (Android).
  static Future<DeleteMediaResult> deleteSongFromDevice(Song song) async {
    if (song.filePath.isEmpty) return DeleteMediaResult.failed;

    DeleteMediaResult result = DeleteMediaResult.failed;
    if (FileActionsService.isSupported) {
      result = await FileActionsService.deleteMediaFile(
        song.filePath,
        mediaId: song.mediaId,
      );
    } else {
      final file = File(song.filePath);
      if (file.existsSync()) {
        file.deleteSync();
        result = DeleteMediaResult.deleted;
      }
    }

    if (result == DeleteMediaResult.deleted) {
      try {
        await _audioQuery.scanMedia(song.filePath);
      } catch (e) {
        debugPrint('scanMedia after delete failed: $e');
      }
    }

    return result;
  }

}

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../models/index.dart';
import '../providers/music_provider.dart';
import '../theme/app_colors.dart';
import '../utils/format_helper.dart';
import '../widgets/empty_state.dart';
import '../widgets/song_artwork.dart';
import '../widgets/playlist_dialogs.dart';
import '../widgets/song_list_tile.dart';
import 'playlist_detail_screen.dart';

enum LibraryFilter { songs, liked, playlists, queue }

class LibraryScreen extends StatefulWidget {
  final LibraryFilter selectedFilter;

  const LibraryScreen({super.key, this.selectedFilter = LibraryFilter.songs});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  late LibraryFilter _filter = widget.selectedFilter;

  @override
  void didUpdateWidget(covariant LibraryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedFilter != oldWidget.selectedFilter) {
      _filter = widget.selectedFilter;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Consumer<MusicProvider>(
        builder: (context, musicProvider, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.accent,
                      ),
                      child: const Icon(
                        Icons.person,
                        color: AppColors.onAccent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Your Library',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    PopupMenuButton<LibrarySort>(
                      icon: const Icon(Icons.sort),
                      tooltip: 'Sort library',
                      initialValue: musicProvider.librarySort,
                      onSelected: musicProvider.setLibrarySort,
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: LibrarySort.title,
                          child: Text('Title'),
                        ),
                        PopupMenuItem(
                          value: LibrarySort.artist,
                          child: Text('Artist'),
                        ),
                        PopupMenuItem(
                          value: LibrarySort.album,
                          child: Text('Album'),
                        ),
                        PopupMenuItem(
                          value: LibrarySort.newest,
                          child: Text('Newest'),
                        ),
                        PopupMenuItem(
                          value: LibrarySort.duration,
                          child: Text('Duration'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 44,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  children: [
                    _FilterChipButton(
                      label: 'Songs',
                      selected: _filter == LibraryFilter.songs,
                      onTap: () =>
                          setState(() => _filter = LibraryFilter.songs),
                    ),
                    _FilterChipButton(
                      label: 'Liked Songs',
                      selected: _filter == LibraryFilter.liked,
                      onTap: () =>
                          setState(() => _filter = LibraryFilter.liked),
                    ),
                    _FilterChipButton(
                      label: 'Playlists',
                      selected: _filter == LibraryFilter.playlists,
                      onTap: () =>
                          setState(() => _filter = LibraryFilter.playlists),
                    ),
                    _FilterChipButton(
                      label: 'Queue',
                      selected: _filter == LibraryFilter.queue,
                      onTap: () =>
                          setState(() => _filter = LibraryFilter.queue),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: switch (_filter) {
                  LibraryFilter.songs => _SongList(
                    songs: musicProvider.sortedSongs(),
                    musicProvider: musicProvider,
                  ),
                  LibraryFilter.liked => _SongList(
                    songs: musicProvider.sortedSongs(
                      musicProvider.getFavorites(),
                    ),
                    musicProvider: musicProvider,
                    emptyMessage: 'No liked songs yet.',
                  ),
                  LibraryFilter.playlists => _PlaylistsList(
                    musicProvider: musicProvider,
                  ),
                  LibraryFilter.queue => _QueueList(
                    musicProvider: musicProvider,
                  ),
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: ChoiceChip(
        selected: selected,
        label: Text(label),
        selectedColor: AppColors.accent,
        backgroundColor: AppColors.surfaceLight,
        labelStyle: TextStyle(
          color: selected ? AppColors.onAccent : AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _SongList extends StatelessWidget {
  final List<Song> songs;
  final MusicProvider musicProvider;
  final String? emptyMessage;

  const _SongList({
    required this.songs,
    required this.musicProvider,
    this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (songs.isEmpty) {
      return _EmptyLibraryState(
        isLoading: musicProvider.isLoading,
        message: emptyMessage,
      );
    }

    return Selector<MusicProvider, String?>(
      selector: (_, provider) => provider.currentSongId,
      builder: (context, currentSongId, _) {
        return ListView.builder(
          itemCount: songs.length,
          itemBuilder: (context, index) {
            final song = songs[index];
            return SongListTile(
              song: song,
              isCurrent: song.id == currentSongId,
            );
          },
        );
      },
    );
  }
}

class _PlaylistsList extends StatelessWidget {
  final MusicProvider musicProvider;

  const _PlaylistsList({required this.musicProvider});

  @override
  Widget build(BuildContext context) {
    final playlists = musicProvider.sortedPlaylists();

    return Stack(
      children: [
        if (playlists.isEmpty)
          const _EmptyLibraryState(
            isLoading: false,
            message: 'Create a playlist to organize your music.',
          )
        else
          ListView.builder(
            padding: const EdgeInsets.only(bottom: 88),
            itemCount: playlists.length,
            itemBuilder: (context, index) {
              final playlist = playlists[index];
              final count = musicProvider.songCountInPlaylist(playlist.id);

              return ListTile(
                leading: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.divider, width: 0.5),
                  ),
                  child: const Icon(
                    Icons.queue_music,
                    color: AppColors.accent,
                  ),
                ),
                title: Text(
                  playlist.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '$count ${count == 1 ? 'song' : 'songs'}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.play_circle_outline),
                  color: AppColors.accent,
                  onPressed: count == 0
                      ? null
                      : () => musicProvider.playPlaylist(playlist),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          PlaylistDetailScreen(playlistId: playlist.id),
                    ),
                  );
                },
              );
            },
          ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            onPressed: () async {
              final name = await showCreatePlaylistDialog(context);
              if (name == null || name.isEmpty) return;
              final playlist = await musicProvider.createPlaylist(name);
              if (playlist == null || !context.mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => PlaylistDetailScreen(playlistId: playlist.id),
                ),
              );
            },
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.onAccent,
            icon: const Icon(Icons.add),
            label: const Text('New playlist'),
          ),
        ),
      ],
    );
  }
}

class _QueueList extends StatelessWidget {
  final MusicProvider musicProvider;

  const _QueueList({required this.musicProvider});

  @override
  Widget build(BuildContext context) {
    final queue = musicProvider.queue;
    if (queue.isEmpty) {
      return const _EmptyLibraryState(
        isLoading: false,
        message: 'Your queue is empty.',
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.only(bottom: 8),
      buildDefaultDragHandles: false,
      itemCount: queue.length,
      onReorder: musicProvider.reorderQueue,
      itemBuilder: (context, index) {
        final song = queue[index];
        final isCurrent = musicProvider.currentIndex == index;

        return KeyedSubtree(
          key: ValueKey('library-queue-${song.id}'),
          child: ListTile(
            leading: Stack(
              clipBehavior: Clip.none,
              children: [
                SongArtwork(
                  song: song,
                  size: 52,
                  borderRadius: 4,
                  accentColor: isCurrent ? AppColors.accent : AppColors.textSecondary,
                ),
                Positioned(
                  right: -5,
                  bottom: -5,
                  child: CircleAvatar(
                    radius: 11,
                    backgroundColor: isCurrent
                        ? AppColors.accent
                        : AppColors.surface,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: isCurrent
                            ? AppColors.onAccent
                            : AppColors.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            title: Text(
              song.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isCurrent ? AppColors.accent : AppColors.textPrimary,
                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            subtitle: Text(
              song.artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  formatDuration(song.duration),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 12),
                ReorderableDragStartListener(
                  index: index,
                  child: const Icon(
                    Icons.drag_handle,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            selected: isCurrent,
            selectedTileColor: AppColors.selectedTint,
            onTap: () {
              musicProvider.playSong(song);
            },
          ),
        );
      },
    );
  }
}

class _EmptyLibraryState extends StatelessWidget {
  final bool isLoading;
  final String? message;

  const _EmptyLibraryState({required this.isLoading, this.message});

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicProvider>(
      builder: (context, musicProvider, _) {
        return EmptyState(
          isLoading: isLoading,
          icon: isLoading ? Icons.search : Icons.library_music,
          title: isLoading ? 'Scanning your library' : 'Nothing here yet',
          message:
              message ??
              (isLoading
                  ? musicProvider.scanStatus
                  : 'No songs found. Check permissions or add audio files.'),
          primaryLabel: isLoading ? null : 'Rescan library',
          onPrimary: isLoading ? null : musicProvider.refreshLibrary,
          secondaryLabel: isLoading ? null : 'Open settings',
          onSecondary: isLoading ? null : openAppSettings,
        );
      },
    );
  }
}

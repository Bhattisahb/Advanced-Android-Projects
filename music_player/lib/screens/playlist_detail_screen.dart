import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/music_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/body_with_mini_player.dart';
import '../widgets/empty_state.dart';
import '../widgets/playlist_dialogs.dart';
import '../widgets/song_list_tile.dart';

class PlaylistDetailScreen extends StatelessWidget {
  final String playlistId;

  const PlaylistDetailScreen({super.key, required this.playlistId});

  void _openAddSongs(BuildContext context) {
    showAddSongsToPlaylistSheet(
      context: context,
      playlistId: playlistId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicProvider>(
      builder: (context, musicProvider, _) {
        final playlist = musicProvider.playlistById(playlistId);
        if (playlist == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Playlist')),
            body: const BodyWithMiniPlayer(
              child: EmptyState(
                icon: Icons.playlist_remove,
                title: 'Playlist gone',
                message: 'This playlist was deleted.',
              ),
            ),
          );
        }

        final songs = musicProvider.songsInPlaylist(playlist);
        final hasMiniPlayer = musicProvider.currentSong != null;
        final listBottomPadding =
            (hasMiniPlayer ? BodyWithMiniPlayer.miniPlayerHeight : 0.0) + 88.0;

        return Scaffold(
          appBar: AppBar(
            title: Text(playlist.name),
            actions: [
              IconButton(
                tooltip: 'Add songs',
                onPressed: () => _openAddSongs(context),
                icon: const Icon(Icons.playlist_add),
              ),
              if (songs.isNotEmpty)
                IconButton(
                  tooltip: 'Play all',
                  onPressed: () => musicProvider.playPlaylist(playlist),
                  icon: const Icon(Icons.play_arrow),
                ),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  switch (value) {
                    case 'rename':
                      await showRenamePlaylistDialog(
                        context: context,
                        playlist: playlist,
                      );
                    case 'delete':
                      final confirmed = await _confirmDelete(context);
                      if (confirmed == true && context.mounted) {
                        await musicProvider.deletePlaylist(playlist.id);
                        if (context.mounted) Navigator.pop(context);
                      }
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'rename', child: Text('Rename')),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      'Delete playlist',
                      style: TextStyle(color: Color(0xFFB3261E)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          floatingActionButton: songs.isEmpty
              ? Padding(
                  padding: EdgeInsets.only(
                    bottom: hasMiniPlayer
                        ? BodyWithMiniPlayer.miniPlayerHeight
                        : 0,
                  ),
                  child: FloatingActionButton.extended(
                    onPressed: () => _openAddSongs(context),
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.onAccent,
                    icon: const Icon(Icons.add),
                    label: const Text('Add songs'),
                  ),
                )
              : null,
          body: BodyWithMiniPlayer(
            child: songs.isEmpty
                ? EmptyState(
                    icon: Icons.music_off,
                    title: 'Empty playlist',
                    message:
                        'Add songs from your library to start this playlist.',
                    primaryLabel: 'Add songs',
                    onPrimary: () => _openAddSongs(context),
                  )
                : ReorderableListView.builder(
                    padding: EdgeInsets.only(bottom: listBottomPadding),
                    itemCount: songs.length,
                    onReorder: (oldIndex, newIndex) {
                      musicProvider.reorderPlaylistSongs(
                        playlist.id,
                        oldIndex,
                        newIndex,
                      );
                    },
                    itemBuilder: (context, index) {
                      final song = songs[index];
                      return SongListTile(
                        key: ValueKey('playlist-${playlist.id}-${song.id}'),
                        song: song,
                        isCurrent: musicProvider.currentSongId == song.id,
                        onTap: () =>
                            musicProvider.playFromPlaylist(song, playlist),
                        trailing: IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          color: AppColors.textSecondary,
                          onPressed: () =>
                              musicProvider.removeSongFromPlaylist(
                            playlist.id,
                            song,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        );
      },
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete playlist?'),
        content: const Text(
          'Songs stay in your library. Only this playlist is removed.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Color(0xFFB3261E)),
            ),
          ),
        ],
      ),
    );
  }
}

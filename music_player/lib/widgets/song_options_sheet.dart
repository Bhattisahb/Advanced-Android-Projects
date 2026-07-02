import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/index.dart';
import '../providers/music_provider.dart';
import '../services/file_actions_service.dart';
import '../theme/app_colors.dart';
import 'playlist_dialogs.dart';
import 'song_artwork.dart';

Future<void> showSongOptionsSheet({
  required BuildContext context,
  required Song song,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => _SongOptionsSheet(song: song),
  );
}

class _SongOptionsSheet extends StatelessWidget {
  final Song song;

  const _SongOptionsSheet({required this.song});

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicProvider>(
      builder: (context, musicProvider, _) {
        final isFavorite = musicProvider.isFavorite(song);
        final inMostPlayed = musicProvider.isInMostPlayed(song);
        final hasPath = song.filePath.isNotEmpty;
        final canUseFileActions = hasPath && FileActionsService.isSupported;

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              0,
              16,
              16 + MediaQuery.paddingOf(context).bottom,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${song.artist} • ${song.album}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  if (hasPath) ...[
                    const SizedBox(height: 14),
                    const Text(
                      'File location',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.insert_drive_file_outlined,
                            size: 20,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              song.filePath,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 12,
                                fontFamily: 'monospace',
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    _SheetAction(
                      icon: Icons.copy,
                      label: 'Copy file path',
                      onTap: () {
                        Navigator.pop(context);
                        musicProvider.copySongPath(song);
                      },
                    ),
                  ],
                  const SizedBox(height: 8),
                  const Divider(color: AppColors.divider, height: 1),
                  const SizedBox(height: 4),
                  _SheetAction(
                    icon: Icons.play_arrow,
                    label: 'Play now',
                    onTap: () {
                      Navigator.pop(context);
                      musicProvider.playSong(song);
                    },
                  ),
                  _SheetAction(
                    icon: Icons.queue_play_next,
                    label: 'Play next',
                    onTap: () {
                      Navigator.pop(context);
                      musicProvider.playNext(song);
                    },
                  ),
                  _SheetAction(
                    icon: Icons.playlist_add,
                    label: 'Add to queue',
                    onTap: () {
                      Navigator.pop(context);
                      musicProvider.addToQueue(song);
                    },
                  ),
                  _SheetAction(
                    icon: Icons.playlist_play,
                    label: 'Add to playlist',
                    onTap: () {
                      Navigator.pop(context);
                      showPlaylistPickerSheet(context: context, song: song);
                    },
                  ),
                  _SheetAction(
                    icon: isFavorite ? Icons.favorite : Icons.favorite_border,
                    label: isFavorite
                        ? 'Remove from liked songs'
                        : 'Add to liked songs',
                    onTap: () {
                      Navigator.pop(context);
                      musicProvider.toggleFavorite(song);
                    },
                  ),
                  if (inMostPlayed)
                    _SheetAction(
                      icon: Icons.remove_circle_outline,
                      label: 'Remove from most played',
                      onTap: () {
                        Navigator.pop(context);
                        musicProvider.removeFromMostPlayed(song);
                      },
                    ),
                  _SheetAction(
                    icon: Icons.person,
                    label: 'View artist',
                    onTap: () => _showRelatedSongs(
                      context: context,
                      title: song.artist,
                      songs: musicProvider.songsByArtist(song.artist),
                    ),
                  ),
                  _SheetAction(
                    icon: Icons.album,
                    label: 'View album',
                    onTap: () => _showRelatedSongs(
                      context: context,
                      title: song.album,
                      songs: musicProvider.songsByAlbum(song.album),
                    ),
                  ),
                  if (canUseFileActions) ...[
                    const SizedBox(height: 4),
                    _SheetAction(
                      icon: Icons.delete_forever,
                      label: 'Delete from device',
                      isDestructive: true,
                      onTap: () => _confirmDeleteFromDevice(
                        context: context,
                        song: song,
                        musicProvider: musicProvider,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDeleteFromDevice({
    required BuildContext context,
    required Song song,
    required MusicProvider musicProvider,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text(
            'Delete from device?',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            '“${song.title}” will be permanently removed from your device. '
            'This cannot be undone.\n\n'
            'Android may show a system prompt to allow delete. '
            'If delete fails, enable All files access for this app under '
            'Settings → Apps → Music Player → Special app access.',
            style: const TextStyle(color: AppColors.textSecondary),
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
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    Navigator.pop(context);
    await musicProvider.deleteSongFromDevice(song);
  }

  void _showRelatedSongs({
    required BuildContext context,
    required String title,
    required List<Song> songs,
  }) {
    Navigator.pop(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: songs.length,
                  itemBuilder: (context, index) {
                    final relatedSong = songs[index];
                    return Consumer<MusicProvider>(
                      builder: (context, musicProvider, _) {
                        return ListTile(
                          leading: SongArtwork(
                            song: relatedSong,
                            size: 48,
                            borderRadius: 4,
                          ),
                          title: Text(
                            relatedSong.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            relatedSong.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            musicProvider.playSong(relatedSong);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SheetAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _SheetAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive
        ? const Color(0xFFB3261E)
        : AppColors.textPrimary;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
      onTap: onTap,
    );
  }
}

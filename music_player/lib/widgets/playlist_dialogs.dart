import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/index.dart';
import '../providers/music_provider.dart';
import '../theme/app_colors.dart';
import 'song_artwork.dart';

Future<String?> showCreatePlaylistDialog(BuildContext context) async {
  final result = await showDialog<String>(
    context: context,
    useRootNavigator: true,
    builder: (dialogContext) => const _PlaylistNameDialog(
      title: 'New playlist',
      hint: 'Playlist name',
      confirmLabel: 'Create',
    ),
  );
  final trimmed = result?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}

Future<void> showRenamePlaylistDialog({
  required BuildContext context,
  required Playlist playlist,
}) async {
  final newName = await showDialog<String>(
    context: context,
    useRootNavigator: true,
    builder: (dialogContext) => _PlaylistNameDialog(
      title: 'Rename playlist',
      initialName: playlist.name,
      confirmLabel: 'Save',
    ),
  );
  final trimmed = newName?.trim();
  if (trimmed == null || trimmed.isEmpty || !context.mounted) return;
  context.read<MusicProvider>().renamePlaylist(playlist.id, trimmed);
}

class _PlaylistNameDialog extends StatefulWidget {
  final String title;
  final String? initialName;
  final String hint;
  final String confirmLabel;

  const _PlaylistNameDialog({
    required this.title,
    this.initialName,
    this.hint = '',
    required this.confirmLabel,
  });

  @override
  State<_PlaylistNameDialog> createState() => _PlaylistNameDialogState();
}

class _PlaylistNameDialogState extends State<_PlaylistNameDialog> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    Navigator.pop(context, _controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(
        widget.title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w800,
        ),
      ),
      content: TextField(
        controller: _controller,
        focusNode: _focusNode,
        autofocus: true,
        decoration: InputDecoration(
          hintText: widget.hint.isEmpty ? null : widget.hint,
          border: const OutlineInputBorder(),
        ),
        textCapitalization: TextCapitalization.sentences,
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _submit,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}

Future<void> showPlaylistPickerSheet({
  required BuildContext context,
  required Song song,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    backgroundColor: AppColors.surface,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) {
      return Consumer<MusicProvider>(
        builder: (context, musicProvider, _) {
          final playlists = musicProvider.sortedPlaylists();

          return SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                0,
                16,
                16 + MediaQuery.paddingOf(sheetContext).bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add to playlist',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    leading: const Icon(Icons.add, color: AppColors.accent),
                    title: const Text(
                      'Create new playlist',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    onTap: () async {
                      final name = await showCreatePlaylistDialog(sheetContext);
                      if (name == null) return;
                      final playlist = await musicProvider.createPlaylist(name);
                      if (playlist == null) return;
                      await musicProvider.addSongToPlaylist(playlist.id, song);
                      if (sheetContext.mounted) {
                        Navigator.pop(sheetContext);
                      }
                    },
                  ),
                  if (playlists.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No playlists yet. Create one above.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: playlists.length,
                        itemBuilder: (context, index) {
                          final playlist = playlists[index];
                          final inPlaylist =
                              musicProvider.isSongInPlaylist(playlist.id, song);
                          return ListTile(
                            leading: Icon(
                              inPlaylist
                                  ? Icons.playlist_add_check
                                  : Icons.queue_music,
                              color: inPlaylist
                                  ? AppColors.accent
                                  : AppColors.textSecondary,
                            ),
                            title: Text(playlist.name),
                            subtitle: Text(
                              '${musicProvider.songCountInPlaylist(playlist.id)} songs',
                            ),
                            trailing: inPlaylist
                                ? TextButton(
                                    onPressed: () {
                                      musicProvider.removeSongFromPlaylist(
                                        playlist.id,
                                        song,
                                      );
                                    },
                                    child: const Text('Remove'),
                                  )
                                : null,
                            onTap: () async {
                              if (inPlaylist) {
                                await musicProvider.removeSongFromPlaylist(
                                  playlist.id,
                                  song,
                                );
                              } else {
                                await musicProvider.addSongToPlaylist(
                                  playlist.id,
                                  song,
                                );
                                if (sheetContext.mounted) {
                                  Navigator.pop(sheetContext);
                                }
                              }
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

Future<void> showAddSongsToPlaylistSheet({
  required BuildContext context,
  required String playlistId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    backgroundColor: AppColors.surface,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return _AddSongsToPlaylistSheet(
            playlistId: playlistId,
            scrollController: scrollController,
          );
        },
      );
    },
  );
}

class _AddSongsToPlaylistSheet extends StatefulWidget {
  final String playlistId;
  final ScrollController scrollController;

  const _AddSongsToPlaylistSheet({
    required this.playlistId,
    required this.scrollController,
  });

  @override
  State<_AddSongsToPlaylistSheet> createState() =>
      _AddSongsToPlaylistSheetState();
}

class _AddSongsToPlaylistSheetState extends State<_AddSongsToPlaylistSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Song> _filterSongs(List<Song> songs) {
    if (_query.isEmpty) return songs;
    final lower = _query.toLowerCase();
    return songs
        .where(
          (song) =>
              song.title.toLowerCase().contains(lower) ||
              song.artist.toLowerCase().contains(lower) ||
              song.album.toLowerCase().contains(lower),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicProvider>(
      builder: (context, musicProvider, _) {
        final playlist = musicProvider.playlistById(widget.playlistId);
        if (playlist == null) {
          return const Center(child: Text('Playlist not found'));
        }

        final allSongs = musicProvider.sortedSongs();
        final visibleSongs = _filterSongs(allSongs);

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add songs to ${playlist.name}',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search your library',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppColors.textSecondary,
                      ),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: AppColors.textSecondary,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                            )
                          : null,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (value) => setState(() => _query = value.trim()),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: allSongs.isEmpty
                  ? const Center(
                      child: Text(
                        'No songs in your library yet.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : visibleSongs.isEmpty
                  ? const Center(
                      child: Text(
                        'No matching songs.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : ListView.builder(
                      controller: widget.scrollController,
                      itemCount: visibleSongs.length,
                      itemBuilder: (context, index) {
                        final song = visibleSongs[index];
                        final inPlaylist = musicProvider.isSongInPlaylist(
                          playlist.id,
                          song,
                        );

                        return ListTile(
                          leading: SongArtwork(
                            song: song,
                            size: 48,
                            borderRadius: 4,
                          ),
                          title: Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            song.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Icon(
                            inPlaylist
                                ? Icons.check_circle
                                : Icons.add_circle_outline,
                            color: inPlaylist
                                ? AppColors.accent
                                : AppColors.textSecondary,
                          ),
                          onTap: () async {
                            if (inPlaylist) {
                              await musicProvider.removeSongFromPlaylist(
                                playlist.id,
                                song,
                              );
                            } else {
                              await musicProvider.addSongToPlaylist(
                                playlist.id,
                                song,
                              );
                            }
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

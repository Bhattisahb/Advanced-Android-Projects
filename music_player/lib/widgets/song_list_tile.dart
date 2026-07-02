import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/index.dart';
import '../providers/music_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/format_helper.dart';
import 'song_options_sheet.dart';
import 'song_artwork.dart';

class SongListTile extends StatelessWidget {
  final Song song;
  final bool isCurrent;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? accentColor;
  final bool showFavorite;

  const SongListTile({
    super.key,
    required this.song,
    this.isCurrent = false,
    this.trailing,
    this.onTap,
    this.accentColor,
    this.showFavorite = true,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = accentColor ?? AppColors.accent;
    final musicProvider = context.read<MusicProvider>();

    return RepaintBoundary(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        leading: SongArtwork(
          song: song,
          size: 52,
          borderRadius: AppTheme.radiusSm,
          accentColor: isCurrent ? activeColor : AppColors.textSecondary,
        ),
        title: Row(
          children: [
            if (isCurrent) ...[
              Icon(Icons.equalizer, size: 18, color: activeColor),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: Text(
                song.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isCurrent ? activeColor : AppColors.textPrimary,
                  fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          song.artist,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        trailing:
            trailing ??
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  formatDuration(song.duration),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                if (showFavorite) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.more_horiz),
                    color: AppColors.textSecondary,
                    onPressed: () {
                      showSongOptionsSheet(context: context, song: song);
                    },
                  ),
                ],
              ],
            ),
        selected: isCurrent,
        selectedTileColor: AppColors.selectedTint,
        onTap: onTap ?? () => musicProvider.playSong(song),
        onLongPress: () {
          showSongOptionsSheet(context: context, song: song);
        },
      ),
    );
  }
}

/// Rebuilds list rows only when the current song or list contents change.
class SongSliverList extends StatelessWidget {
  final List<Song> songs;
  final void Function(Song song)? onSongTap;
  final Future<void> Function(Song song)? onSongDismissed;

  const SongSliverList({
    super.key,
    required this.songs,
    this.onSongTap,
    this.onSongDismissed,
  });

  @override
  Widget build(BuildContext context) {
    return Selector<MusicProvider, String?>(
      selector: (_, provider) => provider.currentSongId,
      builder: (context, currentSongId, _) {
        return SliverList.builder(
          itemCount: songs.length,
          itemBuilder: (context, index) {
            final song = songs[index];
            final tile = SongListTile(
              song: song,
              isCurrent: song.id == currentSongId,
              onTap: onSongTap == null ? null : () => onSongTap!(song),
            );

            if (onSongDismissed == null) {
              return tile;
            }

            return Dismissible(
              key: ValueKey('most_played_${song.id}'),
              direction: DismissDirection.endToStart,
              background: const _DismissRemoveBackground(),
              onDismissed: (_) => onSongDismissed!(song),
              child: tile,
            );
          },
        );
      },
    );
  }
}

class _DismissRemoveBackground extends StatelessWidget {
  const _DismissRemoveBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      color: const Color(0xFFB3261E),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(Icons.remove_circle_outline, color: Colors.white),
          SizedBox(width: 8),
          Text(
            'Remove',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Same as [SongSliverList] for regular scroll views.
class SongListView extends StatelessWidget {
  final List<Song> songs;

  const SongListView({super.key, required this.songs});

  @override
  Widget build(BuildContext context) {
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

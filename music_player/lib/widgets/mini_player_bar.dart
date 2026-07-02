import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/music_provider.dart';
import '../screens/now_playing_screen.dart';
import '../theme/app_colors.dart';
import 'song_artwork.dart';

class MiniPlayerBar extends StatelessWidget {
  const MiniPlayerBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicProvider>(
      builder: (context, musicProvider, _) {
        final song = musicProvider.currentSong;
        if (song == null) {
          return const SizedBox.shrink();
        }

        final totalSeconds = musicProvider.totalDuration.inSeconds;
        final progress = totalSeconds <= 0
            ? null
            : (musicProvider.currentDuration.inSeconds / totalSeconds).clamp(
                0.0,
                1.0,
              );

        return Material(
          color: AppColors.surface,
          elevation: 6,
          shadowColor: AppColors.shadow,
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const NowPlayingScreen(),
                  fullscreenDialog: true,
                ),
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (progress != null)
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 2,
                    backgroundColor: AppColors.divider,
                    valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      SongArtwork(
                        song: song,
                        size: 44,
                        borderRadius: 8,
                        iconSize: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              song.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              song.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: musicProvider.isPlaying ? 'Pause' : 'Play',
                        icon: Icon(
                          musicProvider.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                        ),
                        color: AppColors.textPrimary,
                        onPressed: () {
                          if (musicProvider.isPlaying) {
                            musicProvider.pause();
                          } else {
                            musicProvider.play();
                          }
                        },
                      ),
                      IconButton(
                        tooltip: 'Next',
                        icon: const Icon(Icons.skip_next_rounded),
                        color: AppColors.textPrimary,
                        onPressed: musicProvider.next,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

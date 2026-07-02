import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/music_provider.dart';
import '../theme/app_colors.dart';
import '../utils/format_helper.dart';
import '../widgets/song_artwork.dart';
import '../widgets/song_options_sheet.dart';

class NowPlayingScreen extends StatelessWidget {
  const NowPlayingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<MusicProvider>(
        builder: (context, musicProvider, _) {
          final currentSong = musicProvider.currentSong;

          if (currentSong == null) {
            return SafeArea(
              child: Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.music_note,
                          size: 64,
                          color: AppColors.accent.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No song playing',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return SafeArea(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.accent.withValues(alpha: 0.18),
                    AppColors.background,
                  ],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.keyboard_arrow_down),
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                        const Text(
                          'Now Playing',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (value) {
                            switch (value) {
                              case 'autoplay':
                                musicProvider.toggleAutoPlay();
                              case 'options':
                                showSongOptionsSheet(
                                  context: context,
                                  song: currentSong,
                                );
                            }
                          },
                          itemBuilder: (context) => [
                            CheckedPopupMenuItem<String>(
                              value: 'autoplay',
                              checked: musicProvider.autoPlay,
                              child: const Text('Autoplay'),
                            ),
                            const PopupMenuItem<String>(
                              value: 'options',
                              child: Text('Song options'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Album Art
                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.shadow,
                            blurRadius: 20,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: SongArtwork(
                        song: currentSong,
                        size: 280,
                        borderRadius: 20,
                        iconSize: 120,
                      ),
                    ),
                  ),

                  // Song Info
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            Text(
                              currentSong.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              currentSong.artist,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currentSong.album,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // Favorite Button
                      const SizedBox(height: 24),
                      IconButton(
                        icon: Icon(
                          musicProvider.isFavorite(currentSong)
                              ? Icons.favorite
                              : Icons.favorite_border,
                        ),
                        color: musicProvider.isFavorite(currentSong)
                            ? AppColors.accent
                            : AppColors.textSecondary,
                        iconSize: 32,
                        onPressed: () {
                          musicProvider.toggleFavorite(currentSong);
                        },
                      ),
                    ],
                  ),

                  // Progress Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 12,
                            ),
                          ),
                          child: Slider(
                            value: musicProvider.currentDuration.inSeconds
                                .toDouble()
                                .clamp(
                                  0,
                                  musicProvider.totalDuration.inSeconds
                                      .toDouble(),
                                ),
                            max: musicProvider.totalDuration.inSeconds
                                .toDouble()
                                .clamp(1, double.infinity),
                            activeColor: AppColors.accent,
                            inactiveColor: AppColors.divider,
                            onChanged: (value) {
                              musicProvider.seek(
                                Duration(seconds: value.toInt()),
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                formatDuration(musicProvider.currentDuration),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                formatDuration(musicProvider.totalDuration),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Control Buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: Icon(
                            musicProvider.repeatMode == AudioRepeatMode.none
                                ? Icons.repeat
                                : musicProvider.repeatMode ==
                                      AudioRepeatMode.one
                                ? Icons.repeat_one
                                : Icons.repeat,
                          ),
                          iconSize: 28,
                          color:
                              musicProvider.repeatMode != AudioRepeatMode.none
                              ? AppColors.accent
                              : AppColors.textPrimary,
                          onPressed: () {
                            musicProvider.toggleRepeatMode();
                          },
                        ),

                        // Previous Button
                        IconButton(
                          icon: const Icon(Icons.skip_previous),
                          iconSize: 36,
                          color: AppColors.textPrimary,
                          onPressed: () {
                            musicProvider.previous();
                          },
                        ),

                        GestureDetector(
                          onTap: () {
                            if (musicProvider.isPlaying) {
                              musicProvider.pause();
                            } else {
                              musicProvider.play();
                            }
                          },
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.accent,
                                  AppColors.accentDark,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accent.withValues(
                                    alpha: 0.45,
                                  ),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                musicProvider.isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                size: 40,
                                color: AppColors.onAccent,
                              ),
                            ),
                          ),
                        ),

                        // Next Button
                        IconButton(
                          icon: const Icon(Icons.skip_next),
                          iconSize: 36,
                          color: AppColors.textPrimary,
                          onPressed: () {
                            musicProvider.next();
                          },
                        ),

                        IconButton(
                          icon: const Icon(Icons.shuffle),
                          iconSize: 28,
                          color: musicProvider.isShuffle
                              ? AppColors.accent
                              : AppColors.textPrimary,
                          onPressed: () {
                            musicProvider.toggleShuffle();
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

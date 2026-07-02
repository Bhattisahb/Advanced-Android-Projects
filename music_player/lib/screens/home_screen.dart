import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../models/index.dart';
import '../providers/music_provider.dart';
import '../screens/library_screen.dart';
import '../theme/app_colors.dart';
import '../widgets/empty_state.dart';
import '../widgets/quick_access_tile.dart';
import '../widgets/song_list_tile.dart';

class _HomeSummary {
  final bool isLoading;
  final int songCount;
  final int favoriteCount;
  final int queueLength;
  final int playlistCount;
  final int albumCount;
  final List<Song> mostPlayed;
  final List<Song> suggestions;
  final String? errorMessage;

  const _HomeSummary({
    required this.isLoading,
    required this.songCount,
    required this.favoriteCount,
    required this.queueLength,
    required this.playlistCount,
    required this.albumCount,
    required this.mostPlayed,
    required this.suggestions,
    this.errorMessage,
  });

  @override
  bool operator ==(Object other) {
    return other is _HomeSummary &&
        other.isLoading == isLoading &&
        other.songCount == songCount &&
        other.favoriteCount == favoriteCount &&
        other.queueLength == queueLength &&
        other.playlistCount == playlistCount &&
        other.albumCount == albumCount &&
        other.mostPlayed == mostPlayed &&
        other.suggestions == suggestions &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode => Object.hash(
    isLoading,
    songCount,
    favoriteCount,
    queueLength,
    playlistCount,
    albumCount,
    mostPlayed,
    suggestions,
    errorMessage,
  );
}

class HomeScreen extends StatelessWidget {
  final ValueChanged<LibraryFilter> onOpenLibrary;
  final VoidCallback onOpenSearch;

  const HomeScreen({
    super.key,
    required this.onOpenLibrary,
    required this.onOpenSearch,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Selector<MusicProvider, _HomeSummary>(
        selector: (_, provider) => _HomeSummary(
          isLoading: provider.isLoading,
          songCount: provider.allSongs.length,
          favoriteCount: provider.favoriteCount,
          queueLength: provider.queue.length,
          playlistCount: provider.playlistCount,
          albumCount: provider.albums.length,
          mostPlayed: provider.mostPlayed,
          suggestions: provider.allSongs.take(8).toList(),
          errorMessage: provider.errorMessage,
        ),
        builder: (context, summary, _) {
          final musicProvider = context.read<MusicProvider>();

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _greeting(),
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Rescan library',
                            onPressed: summary.isLoading
                                ? null
                                : musicProvider.refreshLibrary,
                            icon: summary.isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.refresh),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 2.7,
                        children: [
                          QuickAccessTile(
                            icon: Icons.library_music,
                            title: 'All Songs',
                            subtitle: '${summary.songCount} tracks',
                            onTap: () => onOpenLibrary(LibraryFilter.songs),
                          ),
                          QuickAccessTile(
                            icon: Icons.favorite,
                            title: 'Liked Songs',
                            subtitle: '${summary.favoriteCount} saved',
                            onTap: () => onOpenLibrary(LibraryFilter.liked),
                          ),
                          QuickAccessTile(
                            icon: Icons.playlist_play,
                            title: 'Playlists',
                            subtitle: '${summary.playlistCount} saved',
                            onTap: () => onOpenLibrary(LibraryFilter.playlists),
                          ),
                          QuickAccessTile(
                            icon: Icons.queue_music,
                            title: 'Queue',
                            subtitle: '${summary.queueLength} tracks',
                            onTap: () => onOpenLibrary(LibraryFilter.queue),
                          ),
                          QuickAccessTile(
                            icon: Icons.album,
                            title: 'Albums',
                            subtitle: '${summary.albumCount} found',
                            onTap: onOpenSearch,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (summary.mostPlayed.isNotEmpty) ...[
                const _SectionHeader(title: 'Most played'),
                SongSliverList(
                  songs: summary.mostPlayed,
                  onSongTap: musicProvider.playFromMostPlayed,
                  onSongDismissed: musicProvider.removeFromMostPlayed,
                ),
              ],
              const _SectionHeader(title: 'Made from your local music'),
              if (summary.suggestions.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyHomeState(
                    isLoading: summary.isLoading,
                    message: summary.errorMessage,
                  ),
                )
              else
                SongSliverList(songs: summary.suggestions),
            ],
          );
        },
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 22, 16, 10),
        child: Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _EmptyHomeState extends StatelessWidget {
  final bool isLoading;
  final String? message;

  const _EmptyHomeState({required this.isLoading, this.message});

  @override
  Widget build(BuildContext context) {
    return Selector<MusicProvider, String>(
      selector: (_, provider) => provider.scanStatus,
      builder: (context, scanStatus, _) {
        final musicProvider = context.read<MusicProvider>();
        return EmptyState(
          isLoading: isLoading,
          icon: isLoading ? Icons.search : Icons.music_off,
          title: isLoading ? 'Scanning your device...' : 'No songs found',
          message:
              message ??
              (isLoading
                  ? scanStatus
                  : 'Check music permissions or add audio files to your device.'),
          primaryLabel: isLoading ? null : 'Rescan library',
          onPrimary: isLoading ? null : musicProvider.refreshLibrary,
          secondaryLabel: isLoading ? null : 'Open settings',
          onSecondary: isLoading ? null : openAppSettings,
        );
      },
    );
  }
}

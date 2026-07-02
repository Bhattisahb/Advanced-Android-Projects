import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../providers/music_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/empty_state.dart';
import '../widgets/song_list_tile.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Consumer<MusicProvider>(
        builder: (context, musicProvider, _) {
          final hasQuery = musicProvider.searchQuery.isNotEmpty;
          final results = musicProvider.searchResults;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Search',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _searchController,
                        style: const TextStyle(color: AppColors.textPrimary),
                        onChanged: musicProvider.searchSongs,
                        decoration: InputDecoration(
                          hintText: 'What do you want to listen to?',
                          prefixIcon: const Icon(
                            Icons.search,
                            color: AppColors.textSecondary,
                          ),
                          suffixIcon: hasQuery
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: AppColors.textSecondary,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    musicProvider.clearSearch();
                                  },
                                )
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (hasQuery) ...[
                _SearchHeader(title: '${results.length} results'),
                if (results.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _NoResultsState(
                      onRescan: musicProvider.refreshLibrary,
                    ),
                  )
                else
                  SongSliverList(songs: results),
              ] else ...[
                const _SearchHeader(title: 'Browse your music'),
                SliverToBoxAdapter(
                  child: _BrowseGroups(
                    artists: musicProvider.artists.take(8).toList(),
                    albums: musicProvider.albums.take(8).toList(),
                    onSelected: (value) {
                      _searchController.text = value;
                      musicProvider.searchSongs(value);
                    },
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SearchHeader extends StatelessWidget {
  final String title;

  const _SearchHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
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

class _BrowseGroups extends StatelessWidget {
  final List<String> artists;
  final List<String> albums;
  final ValueChanged<String> onSelected;

  const _BrowseGroups({
    required this.artists,
    required this.albums,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (artists.isEmpty && albums.isEmpty) {
      return Consumer<MusicProvider>(
        builder: (context, musicProvider, _) {
          return SizedBox(
            height: 360,
            child: EmptyState(
              isLoading: musicProvider.isLoading,
              icon: musicProvider.isLoading ? Icons.search : Icons.album,
              title: musicProvider.isLoading
                  ? 'Building browse'
                  : 'Nothing to browse yet',
              message: musicProvider.isLoading
                  ? musicProvider.scanStatus
                  : 'No artists or albums found. Check music permissions or add songs to your device.',
              primaryLabel: musicProvider.isLoading ? null : 'Rescan library',
              onPrimary: musicProvider.isLoading
                  ? null
                  : musicProvider.refreshLibrary,
              secondaryLabel: musicProvider.isLoading ? null : 'Open settings',
              onSecondary: musicProvider.isLoading ? null : openAppSettings,
            ),
          );
        },
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (artists.isNotEmpty) ...[
            const _BrowseTitle(title: 'Artists'),
            _BrowseChipWrap(values: artists, onSelected: onSelected),
            const SizedBox(height: 20),
          ],
          if (albums.isNotEmpty) ...[
            const _BrowseTitle(title: 'Albums'),
            _BrowseChipWrap(values: albums, onSelected: onSelected),
          ],
        ],
      ),
    );
  }
}

class _BrowseTitle extends StatelessWidget {
  final String title;

  const _BrowseTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _BrowseChipWrap extends StatelessWidget {
  final List<String> values;
  final ValueChanged<String> onSelected;

  const _BrowseChipWrap({required this.values, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: values.map((value) {
        return ActionChip(
          backgroundColor: AppColors.surface,
          label: Text(value),
          labelStyle: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          side: const BorderSide(color: AppColors.divider),
          onPressed: () => onSelected(value),
        );
      }).toList(),
    );
  }
}

class _NoResultsState extends StatelessWidget {
  final VoidCallback onRescan;

  const _NoResultsState({required this.onRescan});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.search_off,
      title: 'No songs found',
      message: 'Try another title, artist, or album.',
      primaryLabel: 'Rescan library',
      onPrimary: onRescan,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/music_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/mini_player_bar.dart';
import 'home_screen.dart';
import 'library_screen.dart';
import 'search_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const int _tabCount = 3;

  PageController? _pageController;
  int _selectedIndex = 0;
  LibraryFilter _libraryFilter = LibraryFilter.songs;
  MusicProvider? _musicProvider;
  DateTime? _lastBackPress;

  PageController get _pages => _pageController!;

  void _ensurePageController() {
    _pageController ??= PageController(initialPage: _selectedIndex);
  }

  @override
  void initState() {
    super.initState();
    _ensurePageController();
  }

  @override
  void dispose() {
    _pageController?.dispose();
    _musicProvider?.removeListener(_handleProviderMessage);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<MusicProvider>();
    if (_musicProvider == provider) return;
    _musicProvider?.removeListener(_handleProviderMessage);
    _musicProvider = provider..addListener(_handleProviderMessage);
  }

  @override
  Widget build(BuildContext context) {
    _ensurePageController();
    final screens = [
      HomeScreen(onOpenLibrary: _openLibrary, onOpenSearch: _openSearch),
      const SearchScreen(),
      LibraryScreen(selectedFilter: _libraryFilter),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackPress();
      },
      child: Scaffold(
        body: PageView(
          controller: _pages,
          onPageChanged: _onPageChanged,
          children: screens,
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.divider)),
              ),
              child: MiniPlayerBar(),
            ),
            BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: _onTabSelected,
              type: BottomNavigationBarType.fixed,
              backgroundColor: AppColors.surface,
              selectedItemColor: AppColors.accent,
              unselectedItemColor: AppColors.textSecondary,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_filled),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.search),
                  label: 'Search',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.library_music),
                  label: 'Your Library',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _onPageChanged(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
  }

  void _onTabSelected(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
    _pages.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _goToPage(int index) {
    final safeIndex = index.clamp(0, _tabCount - 1);
    setState(() => _selectedIndex = safeIndex);
    if (_pages.hasClients) {
      _pages.jumpToPage(safeIndex);
    }
  }

  void _handleBackPress() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }

    if (_selectedIndex != 0) {
      _goToPage(0);
      return;
    }

    final now = DateTime.now();
    if (_lastBackPress == null ||
        now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
      _lastBackPress = now;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Press back again to exit'),
            duration: Duration(seconds: 2),
          ),
        );
      return;
    }

    SystemNavigator.pop();
  }

  void _openLibrary(LibraryFilter filter) {
    setState(() => _libraryFilter = filter);
    _goToPage(2);
  }

  void _openSearch() {
    _goToPage(1);
  }

  void _handleProviderMessage() {
    final message = _musicProvider?.takeSnackMessage();
    if (message == null || !mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:grocery_app/screens/cart/cart_screen.dart';
import 'package:grocery_app/screens/home_screen.dart';
import 'package:grocery_app/screens/notifications_screen.dart';
import 'package:grocery_app/screens/user.dart';
import 'package:grocery_app/services/auth_gate_service.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../providers/dark_theme_provider.dart';

class BottomBarScreen extends StatefulWidget {
  const BottomBarScreen({Key? key}) : super(key: key);

  static const Color accent = Color(0xFFFF6B35);

  @override
  State<BottomBarScreen> createState() => _BottomBarScreenState();
}

class _BottomBarScreenState extends State<BottomBarScreen> {
  int _selectedIndex = 0;

  /// Second back press within this window exits the app (Home tab root only).
  static const Duration _exitConfirmWindow = Duration(seconds: 2);
  DateTime? _lastExitPromptAt;

  late final List<Widget> _pages = [
    const HomeScreen(),
    const NotificationsScreen(),
    const CartScreen(),
    const UserScreen(),
  ];

  Future<void> _onSelect(int index) async {
    if (index == 2 || index == 3) {
      final user = await AuthGateService.requireVerifiedUser(
        context,
        message: index == 2
            ? 'Sign in with a verified account to use your cart and checkout.'
            : 'Sign in with a verified account to view your profile.',
      );
      if (user == null) return;
    }
    _lastExitPromptAt = null;
    setState(() => _selectedIndex = index);
  }

  void _handleBackNavigation() {
    if (_selectedIndex != 0) {
      _lastExitPromptAt = null;
      setState(() => _selectedIndex = 0);
      return;
    }

    final now = DateTime.now();
    if (_lastExitPromptAt != null &&
        now.difference(_lastExitPromptAt!) <= _exitConfirmWindow) {
      SystemNavigator.pop();
      return;
    }
    _lastExitPromptAt = now;
    Fluttertoast.showToast(
      msg: 'Press back again to exit',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  Widget _item({
    required int index,
    required IconData iconBold,
    required IconData iconLight,
    required String label,
    bool cartBadge = false,
    bool notifyDot = false,
  }) {
    final themeState = Provider.of<DarkThemeProvider>(context);
    final isDark = themeState.getDarkTheme;
    final selected = _selectedIndex == index;

    final Widget baseIcon = Icon(
      selected ? iconBold : iconLight,
      color: selected
          ? BottomBarScreen.accent
          : (isDark ? Colors.white38 : Colors.black38),
      size: 24,
    );

    Widget iconWidget = baseIcon;

    if (cartBadge && index == 2) {
      iconWidget = Selector<CartProvider, int>(
        selector: (_, cart) => cart.getCartItems.length,
        builder: (context, count, _) {
          if (count <= 0) return baseIcon;
          return Badge(
            label: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: BottomBarScreen.accent,
            child: baseIcon,
          );
        },
      );
    } else if (notifyDot && index == 1) {
      iconWidget = Stack(
        clipBehavior: Clip.none,
        children: [
          baseIcon,
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: BottomBarScreen.accent,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      );
    }

    return Expanded(
      child: InkWell(
        onTap: () => _onSelect(index),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected
                      ? BottomBarScreen.accent.withValues(alpha: 0.14)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: iconWidget,
              ),
              if (selected) ...[
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: BottomBarScreen.accent,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeState = Provider.of<DarkThemeProvider>(context);
    final isDark = themeState.getDarkTheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackNavigation();
      },
      child: Scaffold(
        body: _pages[_selectedIndex],
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: isDark ? Theme.of(context).cardColor : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                children: [
                  _item(
                    index: 0,
                    iconBold: IconlyBold.home,
                    iconLight: IconlyLight.home,
                    label: 'Home',
                  ),
                  _item(
                    index: 1,
                    iconBold: IconlyBold.notification,
                    iconLight: IconlyLight.notification,
                    label: 'Notifications',
                    notifyDot: true,
                  ),
                  _item(
                    index: 2,
                    iconBold: IconlyBold.buy,
                    iconLight: IconlyLight.buy,
                    label: 'Cart',
                    cartBadge: true,
                  ),
                  _item(
                    index: 3,
                    iconBold: IconlyBold.profile,
                    iconLight: IconlyLight.profile,
                    label: 'Profile',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

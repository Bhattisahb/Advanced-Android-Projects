import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:grocery_app/consts/firebase_consts.dart';
import 'package:grocery_app/screens/auth/forget_pass.dart';
import 'package:grocery_app/screens/loading_manager.dart';
import 'package:grocery_app/screens/orders/orders_screen.dart';
import 'package:grocery_app/screens/viewed_recently/viewed_recently.dart';
import 'package:grocery_app/screens/wishlist/wishlist_screen.dart';
import 'package:grocery_app/screens/admin/admin_dashboard_screen.dart';
import 'package:grocery_app/services/admin_service.dart';
import 'package:grocery_app/services/auth_gate_service.dart';
import 'package:grocery_app/services/auth_navigation_helpers.dart';
import 'package:grocery_app/services/global_methods.dart';
import 'package:grocery_app/widgets/text_widget.dart';
import 'package:provider/provider.dart';

import '../providers/dark_theme_provider.dart';
import 'auth/login.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({Key? key}) : super(key: key);

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  final TextEditingController _addressTextController =
      TextEditingController(text: "");
  @override
  void dispose() {
    _addressTextController.dispose();
    super.dispose();
  }

  String? _email;
  String? _name;
  String? address;
  bool _isAdmin = false;
  bool _isLoading = false;
  final User? user = authInstance.currentUser;
  @override
  void initState() {
    getUserData();
    super.initState();
  }

  Future<void> getUserData() async {
    setState(() {
      _isLoading = true;
    });
    if (user == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }
    final gate = await AuthGateService.resolve();
    if (!gate.canUsePrivateData) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }
    try {
      final uid = user!.uid;

      final DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      _email = userDoc.get('email');
      _name = userDoc.get('name');
      address = userDoc.get('shipping-address');
      _addressTextController.text = userDoc.get('shipping-address');
      _isAdmin = await const AdminService().isCurrentUserAdmin();
    } catch (error) {
      if (mounted) {
        GlobalMethods.errorDialog(subtitle: '$error', context: context);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeState = Provider.of<DarkThemeProvider>(context);
    final Color color = themeState.getDarkTheme ? Colors.white : Colors.black;
    return Scaffold(
        body: LoadingManager(
      isLoading: _isLoading,
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  height: 15,
                ),
                RichText(
                  text: TextSpan(
                    text: 'Hi,  ',
                    style: const TextStyle(
                      color: Colors.cyan,
                      fontSize: 27,
                      fontWeight: FontWeight.bold,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                          text: _name ?? 'user',
                          style: TextStyle(
                            color: color,
                            fontSize: 25,
                            fontWeight: FontWeight.w600,
                          ),
                          recognizer: TapGestureRecognizer()..onTap = () {}),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                TextWidget(
                  text: _email == null ? 'Email' : _email!,
                  color: color,
                  textSize: 18,
                ),
                const SizedBox(
                  height: 20,
                ),
                const Divider(
                  thickness: 2,
                ),
                const SizedBox(
                  height: 20,
                ),
                _listTiles(
                  title: 'Address 2',
                  subtitle: address,
                  icon: IconlyLight.profile,
                  onPressed: () async {
                    final verified = await AuthGateService.requireVerifiedUser(
                      context,
                      message:
                          'Sign in with a verified account to update your address.',
                    );
                    if (verified == null) return;
                    await _showAddressDialog();
                  },
                  color: color,
                ),
                _listTiles(
                  title: 'Orders',
                  icon: IconlyLight.bag,
                  onPressed: () async {
                    final verified = await AuthGateService.requireVerifiedUser(
                      context,
                      message:
                          'Sign in with a verified account to view your orders.',
                    );
                    if (verified == null || !context.mounted) return;
                    GlobalMethods.navigateTo(
                        ctx: context, routeName: OrdersScreen.routeName);
                  },
                  color: color,
                ),
                _listTiles(
                  title: 'Wishlist',
                  icon: IconlyLight.heart,
                  onPressed: () async {
                    final verified = await AuthGateService.requireVerifiedUser(
                      context,
                      message:
                          'Sign in with a verified account to view your wishlist.',
                    );
                    if (verified == null || !context.mounted) return;
                    GlobalMethods.navigateTo(
                        ctx: context, routeName: WishlistScreen.routeName);
                  },
                  color: color,
                ),
                _listTiles(
                  title: 'Viewed',
                  icon: IconlyLight.show,
                  onPressed: () {
                    GlobalMethods.navigateTo(
                        ctx: context,
                        routeName: ViewedRecentlyScreen.routeName);
                  },
                  color: color,
                ),
                if (user != null)
                  _listTiles(
                    title: 'Admin',
                    subtitle: _isAdmin
                        ? 'Catalog and tools'
                        : 'Admin access required',
                    icon: Icons.admin_panel_settings_outlined,
                    onPressed: () async {
                      final verified =
                          await AuthGateService.requireVerifiedUser(
                        context,
                        message:
                            'Sign in with a verified admin account to continue.',
                      );
                      if (verified == null || !context.mounted) return;
                      if (!_isAdmin) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Ask an owner to set isAdmin on your user doc.',
                            ),
                          ),
                        );
                        return;
                      }
                      GlobalMethods.navigateTo(
                        ctx: context,
                        routeName: AdminDashboardScreen.routeName,
                      );
                    },
                    color: color,
                  ),
                _listTiles(
                  title: 'Forget password',
                  icon: IconlyLight.unlock,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ForgetPasswordScreen(),
                      ),
                    );
                  },
                  color: color,
                ),
                SwitchListTile(
                  title: TextWidget(
                    text: themeState.getDarkTheme ? 'Dark mode' : 'Light mode',
                    color: color,
                    textSize: 18,
                  ),
                  secondary: Icon(themeState.getDarkTheme
                      ? Icons.dark_mode_outlined
                      : Icons.light_mode_outlined),
                  onChanged: (bool value) {
                    setState(() {
                      themeState.setDarkTheme = value;
                    });
                  },
                  value: themeState.getDarkTheme,
                ),
                _listTiles(
                  title: user == null ? 'Login' : 'Logout',
                  icon: user == null ? IconlyLight.login : IconlyLight.logout,
                  onPressed: () {
                    if (user == null) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                      return;
                    }
                    _confirmSignOut(context);
                  },
                  color: color,
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out'),
        content: const Text(
          'You will need to sign in again to view orders, cart, and saved profile data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await AuthNavigationHelpers.signOutCustomer(context);
  }

  Future<void> _showAddressDialog() async {
    await showDialog(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Update'),
            content: TextField(
              controller: _addressTextController,
              maxLines: 5,
              decoration: const InputDecoration(hintText: "Your address"),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  final uid = user!.uid;
                  try {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .update({
                      'shipping-address': _addressTextController.text,
                    });

                    if (!dialogContext.mounted) return;
                    Navigator.pop(dialogContext);
                    if (!mounted) return;
                    setState(() {
                      address = _addressTextController.text;
                    });
                  } catch (err) {
                    if (!dialogContext.mounted) return;
                    GlobalMethods.errorDialog(
                        subtitle: err.toString(), context: dialogContext);
                  }
                },
                child: const Text('Update'),
              ),
            ],
          );
        });
  }

  Widget _listTiles({
    required String title,
    String? subtitle,
    required IconData icon,
    required Function onPressed,
    required Color color,
  }) {
    return ListTile(
      title: TextWidget(
        text: title,
        color: color,
        textSize: 22,
      ),
      subtitle: TextWidget(
        text: subtitle ?? "",
        color: color,
        textSize: 18,
      ),
      leading: Icon(icon),
      trailing: const Icon(IconlyLight.arrowRight2),
      onTap: () {
        onPressed();
      },
    );
  }
}

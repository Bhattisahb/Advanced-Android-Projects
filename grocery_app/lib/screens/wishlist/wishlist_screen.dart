import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:grocery_app/providers/wishlist_provider.dart';
import 'package:grocery_app/services/auth_gate_service.dart';
import 'package:grocery_app/widgets/empty_screen.dart';
import 'package:grocery_app/widgets/text_widget.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
import '../../services/global_methods.dart';
import '../../services/utils.dart';
import '../../widgets/back_widget.dart';
import 'wishlist_widget.dart';

class WishlistScreen extends StatelessWidget {
  static const routeName = "/WishlistScreen";
  const WishlistScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AuthGateResult>(
      future: AuthGateService.resolve(),
      builder: (context, snapshot) {
        final gate = snapshot.data;
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (gate == null || !gate.canUsePrivateData) {
          return Scaffold(
            appBar: AppBar(
              leading: const BackWidget(),
              elevation: 0,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(IconlyLight.heart, size: 48),
                    const SizedBox(height: 16),
                    const Text(
                      'Sign in with a verified account to view your wishlist.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => AuthGateService.requireVerifiedUser(
                        context,
                        message:
                            'Sign in with a verified account to view your wishlist.',
                      ),
                      child: const Text('Sign in'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return _wishlistContent(context);
      },
    );
  }

  Widget _wishlistContent(BuildContext context) {
    final Color color = Utils(context).color;
    final wishlistProvider = Provider.of<WishlistProvider>(context);
    final wishlistItemsList =
        wishlistProvider.getWishlistItems.values.toList().reversed.toList();
    return wishlistItemsList.isEmpty
        ? const EmptyScreen(
            title: 'Your Wishlist Is Empty',
            subtitle: 'Explore more and shortlist some items',
            imagePath: 'assets/images/wishlist.png',
            buttonText: 'Add a wish',
          )
        : Scaffold(
            appBar: AppBar(
                centerTitle: true,
                leading: const BackWidget(),
                automaticallyImplyLeading: false,
                elevation: 0,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                title: TextWidget(
                  text: 'Wishlist (${wishlistItemsList.length})',
                  color: color,
                  isTitle: true,
                  textSize: 22,
                ),
                actions: [
                  IconButton(
                    onPressed: () {
                      GlobalMethods.warningDialog(
                          title: 'Empty your wishlist?',
                          subtitle: 'Are you sure?',
                          fct: () async {
                            await wishlistProvider.clearOnlineWishlist();
                            wishlistProvider.clearLocalWishlist();
                          },
                          context: context);
                    },
                    icon: Icon(
                      IconlyBroken.delete,
                      color: color,
                    ),
                  ),
                ]),
            body: MasonryGridView.count(
              itemCount: wishlistItemsList.length,
              crossAxisCount: 2,
              // mainAxisSpacing: 16,
              // crossAxisSpacing: 20,
              itemBuilder: (context, index) {
                return ChangeNotifierProvider.value(
                    value: wishlistItemsList[index],
                    child: const WishlistWidget());
              },
            ));
  }
}

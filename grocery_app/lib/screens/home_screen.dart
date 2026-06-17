import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:grocery_app/inner_screens/cat_screen.dart';
import 'package:grocery_app/inner_screens/feeds_screen.dart';
import 'package:grocery_app/inner_screens/most_rated_screen.dart';
import 'package:grocery_app/inner_screens/on_sale_screen.dart';
import 'package:grocery_app/models/home_screen_tile_model.dart';
import 'package:grocery_app/models/products_model.dart';
import 'package:grocery_app/providers/home_screen_tiles_provider.dart';
import 'package:grocery_app/providers/product_ratings_provider.dart';
import 'package:grocery_app/providers/products_provider.dart';
import 'package:grocery_app/screens/categories.dart';
import 'package:grocery_app/screens/home_shortcut_products_screen.dart';
import 'package:grocery_app/screens/store_search_screen.dart';
import 'package:grocery_app/services/global_methods.dart';
import 'package:grocery_app/services/utils.dart';
import 'package:grocery_app/widgets/home_feature_tile.dart';
import 'package:grocery_app/widgets/network_product_image.dart';
import 'package:grocery_app/widgets/text_widget.dart';
import 'package:provider/provider.dart';

import '../consts/contss.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  static const Color accent = Color(0xFFFF6B35);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<ProductModel> _filterByKeyword(List<ProductModel> all, String key) {
    final k = key.toLowerCase();
    return all
        .where(
          (e) => e.productCategoryName.toLowerCase().contains(k),
        )
        .toList();
  }

  Widget _homeHeader(BuildContext context, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Row(
        children: [
          Material(
            color: HomeScreen.accent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CategoriesScreen()),
                );
              },
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(Icons.grid_view_rounded, color: Colors.white, size: 22),
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_on_rounded,
                        color: HomeScreen.accent, size: 18),
                    const SizedBox(width: 4),
                    TextWidget(
                      text: 'F-6/2',
                      color: color,
                      textSize: 15,
                      isTitle: true,
                    ),
                  ],
                ),
                TextWidget(
                  text: 'Islamabad',
                  color: color.withValues(alpha: 0.65),
                  textSize: 13,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          Material(
            color: HomeScreen.accent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                Navigator.pushNamed(context, StoreSearchScreen.routeName);
              },
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(IconlyLight.search, color: Colors.white, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openHomeShortcut(BuildContext context, HomeScreenTileModel tile) {
    final pinned = tile.productIds;
    if (pinned.isNotEmpty) {
      Navigator.pushNamed(
        context,
        HomeShortcutProductsScreen.routeName,
        arguments: HomeShortcutProductsArgs(
          title: tile.title,
          productIds: List<String>.from(pinned),
        ),
      );
      return;
    }

    switch (tile.linkType) {
      case HomeTileLinkType.mostRated:
        Navigator.pushNamed(context, MostRatedScreen.routeName);
        break;
      case HomeTileLinkType.onSale:
        GlobalMethods.navigateTo(
          ctx: context,
          routeName: OnSaleScreen.routeName,
        );
        break;
      case HomeTileLinkType.categoryFilter:
        final filter = tile.categoryFilter?.trim();
        if (filter != null && filter.isNotEmpty) {
          Navigator.pushNamed(
            context,
            CategoryScreen.routeName,
            arguments: filter,
          );
        }
        break;
    }
  }

  Widget _homeShortcutBubble(
    BuildContext context,
    HomeScreenTileModel tile,
    Color textColor,
  ) {
    final bg = tile.accentColor;
    final url = tile.imageUrl?.trim();
    final asset = tile.assetPath?.trim();

    Widget circleChild;
    if (url != null && url.isNotEmpty) {
      circleChild = NetworkProductImage(
        imageUrl: url,
        width: 68,
        height: 68,
        boxFit: BoxFit.cover,
      );
    } else if (asset != null && asset.isNotEmpty) {
      circleChild = Image.asset(
        asset,
        fit: BoxFit.cover,
        width: 68,
        height: 68,
        errorBuilder: (_, __, ___) => Container(
          color: bg.withValues(alpha: 0.55),
          alignment: Alignment.center,
          child: Icon(tile.materialIcon, color: Colors.white, size: 28),
        ),
      );
    } else {
      circleChild = Container(
        color: bg.withValues(alpha: 0.55),
        alignment: Alignment.center,
        child: Icon(tile.materialIcon, color: Colors.white, size: 28),
      );
    }

    return InkWell(
      onTap: () => _openHomeShortcut(context, tile),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bg.withValues(alpha: 0.35),
            ),
            child: ClipOval(child: circleChild),
          ),
          const SizedBox(height: 6),
          Text(
            tile.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              height: 1.15,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionStrip({
    required BuildContext context,
    required String title,
    required Color color,
    required List<ProductModel> products,
    VoidCallback? onViewAll,
    ProductRatingsProvider? ratingsProvider,
  }) {
    if (products.isEmpty) return const SizedBox.shrink();

    final w = MediaQuery.of(context).size.width * 0.42;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: TextWidget(
                  text: title,
                  color: color,
                  textSize: 20,
                  isTitle: true,
                ),
              ),
              if (onViewAll != null)
                TextButton(
                  onPressed: onViewAll,
                  child: TextWidget(
                    text: 'View all',
                    maxLines: 1,
                    color: HomeScreen.accent,
                    textSize: 15,
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          height: w * 1.22,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: products.length > 12 ? 12 : products.length,
            itemBuilder: (ctx, i) {
              final p = products[i];
              return ChangeNotifierProvider.value(
                value: p,
                child: HomeFeatureTile(
                  width: w,
                  averageRating: ratingsProvider?.averageFor(p.id),
                  reviewCount: ratingsProvider?.reviewCountFor(p.id),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final Utils utils = Utils(context);
    final Color color = utils.color;
    final Size size = utils.getScreenSize;
    final productProviders = Provider.of<ProductsProvider>(context);
    final ratings = Provider.of<ProductRatingsProvider>(context);
    final List<ProductModel> allProducts = productProviders.getProducts;
    final topRated = ratings.productsInRatingOrder(allProducts);

    final featured = allProducts.length > 12
        ? allProducts.sublist(0, 12)
        : List<ProductModel>.from(allProducts);
    final veg = _filterByKeyword(allProducts, 'Vegetables');
    final fruits = _filterByKeyword(allProducts, 'Fruits');

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _homeHeader(context, color),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: SizedBox(
                  height: size.height * 0.26,
                  child: Swiper(
                    itemBuilder: (BuildContext context, int index) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          Constss.offerImages[index],
                          fit: BoxFit.cover,
                        ),
                      );
                    },
                    autoplay: true,
                    itemCount: Constss.offerImages.length,
                    pagination: const SwiperPagination(
                      alignment: Alignment.bottomCenter,
                      builder: DotSwiperPaginationBuilder(
                        color: Colors.white54,
                        activeColor: HomeScreen.accent,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                child: Consumer<HomeScreenTilesProvider>(
                  builder: (context, homeTiles, _) {
                    final shortcuts = homeTiles.shopperTiles;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: shortcuts.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 6,
                        childAspectRatio: 0.72,
                      ),
                      itemBuilder: (ctx, index) {
                        return _homeShortcutBubble(
                          context,
                          shortcuts[index],
                          color,
                        );
                      },
                    );
                  },
                ),
              ),
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => CategoriesScreen()),
                    );
                  },
                  icon: Icon(Icons.keyboard_arrow_down_rounded,
                      color: HomeScreen.accent),
                  label: TextWidget(
                    text: 'View more categories',
                    color: HomeScreen.accent,
                    textSize: 15,
                  ),
                ),
              ),
              _sectionStrip(
                context: context,
                title: 'Featured products',
                color: color,
                products: featured,
                onViewAll: () {
                  GlobalMethods.navigateTo(
                    ctx: context,
                    routeName: FeedsScreen.routeName,
                  );
                },
              ),
              _sectionStrip(
                context: context,
                title: 'Most rated products',
                color: color,
                products: topRated,
                ratingsProvider: ratings,
                onViewAll: () {
                  Navigator.pushNamed(context, MostRatedScreen.routeName);
                },
              ),
              _sectionStrip(
                context: context,
                title: 'Fresh vegetables',
                color: color,
                products: veg,
                onViewAll: () {
                  Navigator.pushNamed(
                    context,
                    CategoryScreen.routeName,
                    arguments: 'Vegetables',
                  );
                },
              ),
              _sectionStrip(
                context: context,
                title: 'Fresh fruits',
                color: color,
                products: fruits,
                onViewAll: () {
                  Navigator.pushNamed(
                    context,
                    CategoryScreen.routeName,
                    arguments: 'Fruits',
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

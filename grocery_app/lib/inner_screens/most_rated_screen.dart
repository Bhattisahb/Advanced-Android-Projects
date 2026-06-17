import 'package:flutter/material.dart';
import 'package:grocery_app/providers/product_ratings_provider.dart';
import 'package:grocery_app/providers/products_provider.dart';
import 'package:provider/provider.dart';

import '../services/utils.dart';
import '../widgets/back_widget.dart';
import '../widgets/empty_products_widget.dart';
import '../widgets/feed_items.dart';
import '../widgets/text_widget.dart';

class MostRatedScreen extends StatefulWidget {
  const MostRatedScreen({super.key});

  static const routeName = '/MostRatedScreen';

  @override
  State<MostRatedScreen> createState() => _MostRatedScreenState();
}

class _MostRatedScreenState extends State<MostRatedScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final ratings =
          Provider.of<ProductRatingsProvider>(context, listen: false);
      final products =
          Provider.of<ProductsProvider>(context, listen: false);
      await products.fetchProducts();
      await ratings.refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = Utils(context).color;
    final size = Utils(context).getScreenSize;
    final productsProvider = Provider.of<ProductsProvider>(context);
    final ratings = Provider.of<ProductRatingsProvider>(context);
    final ordered = ratings.productsInRatingOrder(productsProvider.getProducts);

    return Scaffold(
      appBar: AppBar(
        leading: const BackWidget(),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        centerTitle: true,
        title: TextWidget(
          text: 'Most rated',
          color: color,
          textSize: 20,
          isTitle: true,
        ),
      ),
      body: ordered.isEmpty
          ? const EmptyProdWidget(
              text:
                  'No ratings yet. Open a product and submit a review to build this list.',
            )
          : GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: size.width / (size.height * 0.61),
              ),
              itemCount: ordered.length,
              itemBuilder: (ctx, index) {
                return ChangeNotifierProvider.value(
                  value: ordered[index],
                  child: const FeedsWidget(),
                );
              },
            ),
    );
  }
}

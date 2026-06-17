import 'package:flutter/material.dart';
import 'package:grocery_app/models/products_model.dart';
import 'package:grocery_app/providers/products_provider.dart';
import 'package:grocery_app/widgets/back_widget.dart';
import 'package:grocery_app/widgets/empty_products_widget.dart';
import 'package:grocery_app/widgets/feed_items.dart';
import 'package:grocery_app/widgets/text_widget.dart';
import 'package:provider/provider.dart';

import 'package:grocery_app/services/utils.dart';

/// Route arguments for [HomeShortcutProductsScreen].
class HomeShortcutProductsArgs {
  const HomeShortcutProductsArgs({
    required this.title,
    required this.productIds,
  });

  final String title;
  final List<String> productIds;
}

/// Shows products pinned to a home shortcut (order follows [productIds]).
class HomeShortcutProductsScreen extends StatefulWidget {
  const HomeShortcutProductsScreen({super.key});

  static const routeName = '/home-shortcut-products';

  @override
  State<HomeShortcutProductsScreen> createState() =>
      _HomeShortcutProductsScreenState();
}

class _HomeShortcutProductsScreenState extends State<HomeShortcutProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  List<ProductModel> _resolveInOrder(
    ProductsProvider products,
    List<String> ids,
  ) {
    final out = <ProductModel>[];
    for (final id in ids) {
      final p = products.findProdByIdOrNull(id);
      if (p != null) out.add(p);
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final color = Utils(context).color;
    final size = Utils(context).getScreenSize;
    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is! HomeShortcutProductsArgs) {
      return Scaffold(
        appBar: AppBar(title: const Text('Products')),
        body: const Center(child: Text('Missing shortcut data')),
      );
    }

    final productsProvider = context.watch<ProductsProvider>();
    final ordered = _resolveInOrder(productsProvider, args.productIds);
    final q = _searchController.text.trim().toLowerCase();
    final visible = q.isEmpty
        ? ordered
        : ordered
            .where((p) => p.title.toLowerCase().contains(q))
            .toList();

    return Scaffold(
      appBar: AppBar(
        leading: const BackWidget(),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        centerTitle: true,
        title: TextWidget(
          text: args.title,
          color: color,
          textSize: 20,
          isTitle: true,
        ),
      ),
      body: ordered.isEmpty
          ? const EmptyProdWidget(
              text: 'No products found for this shortcut',
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocus,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search in this list',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  _searchFocus.unfocus();
                                  setState(() {});
                                },
                              ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  if (visible.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: EmptyProdWidget(
                        text: 'No matching products',
                      ),
                    )
                  else
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      padding: EdgeInsets.zero,
                      childAspectRatio: size.width / (size.height * 0.61),
                      children: List.generate(visible.length, (index) {
                        return ChangeNotifierProvider.value(
                          value: visible[index],
                          child: const FeedsWidget(),
                        );
                      }),
                    ),
                ],
              ),
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:grocery_app/inner_screens/product_details.dart';
import 'package:grocery_app/models/products_model.dart';
import 'package:grocery_app/providers/products_provider.dart';
import 'package:grocery_app/widgets/text_widget.dart';
import 'package:provider/provider.dart';

import '../services/utils.dart';

class StoreSearchScreen extends StatefulWidget {
  static const routeName = '/store-search';

  const StoreSearchScreen({Key? key}) : super(key: key);

  @override
  State<StoreSearchScreen> createState() => _StoreSearchScreenState();
}

class _StoreSearchScreenState extends State<StoreSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  List<ProductModel> _results = [];

  static const List<String> _popular = [
    'Rice',
    'Bread',
    'Biscuits',
    'Milk',
  ];

  void _runSearch(String q) {
    final productsProvider =
        Provider.of<ProductsProvider>(context, listen: false);
    setState(() {
      _results = q.trim().isEmpty
          ? []
          : productsProvider.searchQuery(q.trim());
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color color = Utils(context).color;
    final query = _controller.text.trim();

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: Icon(IconlyLight.arrowLeft2, color: color),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search',
            hintStyle: TextStyle(color: color.withValues(alpha: 0.45)),
            prefixIcon: Icon(IconlyLight.search, color: color.withValues(alpha: 0.55)),
            border: InputBorder.none,
            filled: true,
            fillColor: color.withValues(alpha: 0.06),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
          style: TextStyle(color: color),
          onChanged: _runSearch,
          textInputAction: TextInputAction.search,
          onSubmitted: _runSearch,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          if (query.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 12),
              child: TextWidget(
                text: 'Popular searches',
                color: color,
                textSize: 18,
                isTitle: true,
              ),
            ),
            ..._popular.map(
              (term) => ListTile(
                leading: Icon(IconlyLight.search,
                    color: color.withValues(alpha: 0.55)),
                title: Text(term),
                onTap: () {
                  _controller.text = term;
                  _runSearch(term);
                  setState(() {});
                },
              ),
            ),
          ],
          if (query.isNotEmpty && _results.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: TextWidget(
                text: 'Results (${_results.length})',
                color: color,
                textSize: 18,
                isTitle: true,
              ),
            ),
            ..._results.map(
              (p) => ListTile(
                title: Text(p.title),
                subtitle: Text(
                  formatPkr(p.isOnSale ? p.salePrice : p.price),
                  style: const TextStyle(color: Color(0xFFFF6B35)),
                ),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    ProductDetails.routeName,
                    arguments: p.id,
                  );
                },
              ),
            ),
          ],
          if (query.isNotEmpty && _results.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 48),
              child: Center(
                child: TextWidget(
                  text: 'No products found',
                  color: color,
                  textSize: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

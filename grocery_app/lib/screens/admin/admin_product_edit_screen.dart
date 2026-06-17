import 'dart:io';

import 'package:flutter/material.dart';
import 'package:grocery_app/models/products_model.dart';
import 'package:grocery_app/providers/categories_provider.dart';
import 'package:grocery_app/providers/products_provider.dart';
import 'package:grocery_app/services/product_image_storage_service.dart';
import 'package:grocery_app/widgets/network_product_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class AdminProductEditScreen extends StatefulWidget {
  const AdminProductEditScreen({super.key});

  static const routeName = '/admin-product-edit';

  @override
  State<AdminProductEditScreen> createState() => _AdminProductEditScreenState();
}

class _AdminProductEditScreenState extends State<AdminProductEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _titleController = TextEditingController();
  final _categoryController = TextEditingController();
  final _priceController = TextEditingController();
  final _salePriceController = TextEditingController();
  final _stockQtyController = TextEditingController();
  final _lowStockThresholdController = TextEditingController(text: '5');
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _picker = ImagePicker();

  bool _isOnSale = false;
  bool _isPiece = false;
  bool _hiddenFromCatalog = false;
  bool _saving = false;
  bool _didLoadProduct = false;
  bool _requestedCategoryCatalog = false;
  XFile? _pickedImage;

  bool get _isEditing => (_routeProductId ?? '').isNotEmpty;
  String? _routeProductId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_requestedCategoryCatalog) {
      _requestedCategoryCatalog = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<CategoriesProvider>().fetchCategories();
      });
    }
    if (_didLoadProduct) return;

    _routeProductId = ModalRoute.of(context)?.settings.arguments as String?;
    if (_routeProductId != null) {
      final product =
          context.read<ProductsProvider>().findProdByIdOrNull(_routeProductId!);
      if (product != null) {
        _populate(product);
      }
    }
    _didLoadProduct = true;
  }

  @override
  void dispose() {
    _idController.dispose();
    _titleController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    _salePriceController.dispose();
    _stockQtyController.dispose();
    _lowStockThresholdController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  void _populate(ProductModel product) {
    _idController.text = product.id;
    _titleController.text = product.title;
    _categoryController.text = product.productCategoryName;
    _priceController.text = product.price.toStringAsFixed(0);
    _salePriceController.text = product.salePrice.toStringAsFixed(0);
    _stockQtyController.text =
        product.stockQuantity != null ? '${product.stockQuantity}' : '';
    _lowStockThresholdController.text = '${product.lowStockThreshold}';
    _descriptionController.text = product.description;
    _imageUrlController.text = product.imageUrl;
    _isOnSale = product.isOnSale;
    _isPiece = product.isPiece;
    _hiddenFromCatalog = product.hiddenFromCatalog;
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (image == null) return;
    setState(() => _pickedImage = image);
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final productsProvider = context.read<ProductsProvider>();
      final productId = _idController.text.trim();
      var imageUrl = _imageUrlController.text.trim();

      if (_pickedImage != null) {
        imageUrl = await const ProductImageStorageService().uploadProductImage(
          productId: productId,
          image: _pickedImage!,
        );
      }

      final stockRaw = _stockQtyController.text.trim();
      final int? stockQty =
          stockRaw.isEmpty ? null : int.tryParse(stockRaw);

      final threshRaw = _lowStockThresholdController.text.trim();
      final threshParsed = int.tryParse(threshRaw);
      final lowStockThreshold =
          threshParsed == null || threshParsed < 1 ? 5 : threshParsed;

      final product = ProductModel(
        id: productId,
        title: _titleController.text.trim(),
        imageUrl: imageUrl,
        productCategoryName: _categoryController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        salePrice: double.parse(_salePriceController.text.trim()),
        isOnSale: _isOnSale,
        isPiece: _isPiece,
        stockQuantity: stockQty,
        lowStockThreshold: lowStockThreshold,
        hiddenFromCatalog: _hiddenFromCatalog,
      );

      await productsProvider.upsertProduct(product);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product saved')),
      );
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $error')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _requiredText(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    return null;
  }

  String? _requiredNumber(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Required';
    if (double.tryParse(text) == null) return 'Enter a number';
    return null;
  }

  Widget _categoryField() {
    return Consumer2<CategoriesProvider, ProductsProvider>(
      builder: (context, cats, products, _) {
        final options = cats.mergedNames(products.getProducts);
        return TextFormField(
          controller: _categoryController,
          decoration: InputDecoration(
            labelText: 'Category',
            helperText: 'Type a name or pick from catalog / existing products',
            suffixIcon: options.isEmpty
                ? null
                : PopupMenuButton<String>(
                    tooltip: 'Pick from list',
                    icon: const Icon(Icons.arrow_drop_down_circle_outlined),
                    itemBuilder: (ctx) => options
                        .map(
                          (n) => PopupMenuItem<String>(
                            value: n,
                            child: Text(
                              n,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onSelected: (value) {
                      setState(() {
                        _categoryController.text = value;
                      });
                    },
                  ),
          ),
          validator: _requiredText,
        );
      },
    );
  }

  Widget _imagePreview() {
    if (_pickedImage != null) {
      return Image.file(
        File(_pickedImage!.path),
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    }

    final imageUrl = _imageUrlController.text.trim();
    return NetworkProductImage(
      imageUrl: imageUrl,
      height: 180,
      width: double.infinity,
      boxFit: BoxFit.cover,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit product' : 'Add product'),
      ),
      body: AbsorbPointer(
        absorbing: _saving,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _imagePreview(),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Choose photo from gallery'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _idController,
                  readOnly: _isEditing,
                  decoration: const InputDecoration(
                    labelText: 'Product ID',
                    hintText: 'apple_1kg',
                  ),
                  validator: _requiredText,
                ),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: _requiredText,
                ),
                _categoryField(),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    alignLabelWithHint: true,
                  ),
                  maxLines: 4,
                  validator: _requiredText,
                ),
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Price (PKR)',
                  ),
                  keyboardType: TextInputType.number,
                  validator: _requiredNumber,
                ),
                TextFormField(
                  controller: _salePriceController,
                  decoration: const InputDecoration(
                    labelText: 'Sale price (PKR)',
                  ),
                  keyboardType: TextInputType.number,
                  validator: _requiredNumber,
                ),
                TextFormField(
                  controller: _stockQtyController,
                  decoration: const InputDecoration(
                    labelText: 'Stock quantity',
                    helperText:
                        'Leave empty if you do not track inventory for this SKU',
                  ),
                  keyboardType: TextInputType.number,
                ),
                TextFormField(
                  controller: _lowStockThresholdController,
                  decoration: const InputDecoration(
                    labelText: 'Low-stock threshold',
                    helperText:
                        'Alert in admin list when quantity ≤ this value (≥ 1)',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final n = int.tryParse(v?.trim() ?? '');
                    if (n == null || n < 1) return 'Enter an integer ≥ 1';
                    return null;
                  },
                ),
                TextFormField(
                  controller: _imageUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Image URL',
                    helperText:
                        'Auto-filled after Cloudinary upload, or paste a URL',
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: (value) =>
                      _pickedImage == null ? _requiredText(value) : null,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('On sale'),
                  value: _isOnSale,
                  onChanged: (value) => setState(() => _isOnSale = value),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Sold as piece'),
                  subtitle: const Text('Turn off for kg products'),
                  value: _isPiece,
                  onChanged: (value) => setState(() => _isPiece = value),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Hidden from store catalog'),
                  subtitle: const Text(
                    'Shoppers will not see this product (admin still can)',
                  ),
                  value: _hiddenFromCatalog,
                  onChanged: (value) =>
                      setState(() => _hiddenFromCatalog = value),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _saveProduct,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_saving ? 'Saving...' : 'Save product'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

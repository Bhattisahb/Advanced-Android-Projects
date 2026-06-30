/// Product Form Screen
/// Allows users to add new products or edit existing ones
/// Validates input and handles form submission

import 'package:flutter/material.dart';
import 'package:pos_app/core/constants/app_constants.dart';
import 'package:pos_app/core/utils/validators.dart';
import 'package:pos_app/data/models/product_model.dart';
import 'package:pos_app/data/repositories/product_repository.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? product;

  const ProductFormScreen({
    Key? key,
    this.product,
  }) : super(key: key);

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productRepository = ProductRepository();

  late TextEditingController _nameController;
  late TextEditingController _skuController;
  late TextEditingController _priceController;
  late TextEditingController _costController;
  late TextEditingController _categoryController;
  late TextEditingController _stockController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _nameController = TextEditingController(text: product?.name ?? '');
    _skuController = TextEditingController(text: product?.sku ?? '');
    _priceController =
        TextEditingController(text: product?.price.toString() ?? '');
    _costController = TextEditingController(text: product?.cost.toString() ?? '');
    _categoryController = TextEditingController(text: product?.category ?? '');
    _stockController =
        TextEditingController(text: product?.stockQuantity.toString() ?? '0');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _priceController.dispose();
    _costController.dispose();
    _categoryController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  /// Handle form submission
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final name = _nameController.text.trim();
      final sku = _skuController.text.trim();
      final price = double.parse(_priceController.text);
      final cost = double.parse(_costController.text);
      final category = _categoryController.text.trim();
      final stock = int.parse(_stockController.text);

      if (widget.product == null) {
        // Add new product
        await _productRepository.addProduct(
          name: name,
          sku: sku,
          price: price,
          cost: cost,
          category: category,
          stockQuantity: stock,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(AppConstants.SUCCESS_PRODUCT_ADDED),
            ),
          );
        }
      } else {
        // Update existing product
        await _productRepository.updateProduct(
          id: widget.product!.id!,
          name: name,
          sku: sku,
          price: price,
          cost: cost,
          category: category,
          stockQuantity: stock,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(AppConstants.SUCCESS_PRODUCT_UPDATED),
            ),
          );
        }
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Product' : 'Add Product'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.DEFAULT_PADDING),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Product name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Product Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppConstants.DEFAULT_BORDER_RADIUS,
                    ),
                  ),
                  prefixIcon: const Icon(Icons.shopping_bag),
                ),
                validator: Validators.validateProductName,
              ),
              const SizedBox(height: 16),

              // SKU
              TextFormField(
                controller: _skuController,
                decoration: InputDecoration(
                  labelText: 'SKU',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppConstants.DEFAULT_BORDER_RADIUS,
                    ),
                  ),
                  prefixIcon: const Icon(Icons.qr_code),
                ),
                validator: Validators.validateSKU,
              ),
              const SizedBox(height: 16),

              // Price
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(
                  labelText: 'Selling Price',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppConstants.DEFAULT_BORDER_RADIUS,
                    ),
                  ),
                  prefixIcon: const Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                validator: Validators.validatePrice,
              ),
              const SizedBox(height: 16),

              // Cost
              TextFormField(
                controller: _costController,
                decoration: InputDecoration(
                  labelText: 'Cost Price',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppConstants.DEFAULT_BORDER_RADIUS,
                    ),
                  ),
                  prefixIcon: const Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                validator: Validators.validateCost,
              ),
              const SizedBox(height: 16),

              // Category
              TextFormField(
                controller: _categoryController,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppConstants.DEFAULT_BORDER_RADIUS,
                    ),
                  ),
                  prefixIcon: const Icon(Icons.category),
                ),
              ),
              const SizedBox(height: 16),

              // Stock quantity
              TextFormField(
                controller: _stockController,
                decoration: InputDecoration(
                  labelText: 'Initial Stock Quantity',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppConstants.DEFAULT_BORDER_RADIUS,
                    ),
                  ),
                  prefixIcon: const Icon(Icons.inventory),
                ),
                keyboardType: TextInputType.number,
                validator: Validators.validateQuantity,
              ),
              const SizedBox(height: 32),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(isEditing ? 'Update Product' : 'Add Product'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

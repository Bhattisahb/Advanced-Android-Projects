import 'dart:io';

import 'package:flutter/material.dart';
import 'package:grocery_app/models/category_catalog_model.dart';
import 'package:grocery_app/providers/categories_provider.dart';
import 'package:grocery_app/providers/products_provider.dart';
import 'package:grocery_app/services/product_image_storage_service.dart';
import 'package:grocery_app/widgets/network_product_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

Future<void> showAdminCategoryEditor(
  BuildContext context,
  CategoryCatalogDoc doc,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetCtx) => AdminCategoryEditSheet(initial: doc),
  );
}

class AdminCategoryEditSheet extends StatefulWidget {
  const AdminCategoryEditSheet({super.key, required this.initial});

  final CategoryCatalogDoc initial;

  @override
  State<AdminCategoryEditSheet> createState() => _AdminCategoryEditSheetState();
}

class _AdminCategoryEditSheetState extends State<AdminCategoryEditSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _sortOrderController;
  final ImagePicker _picker = ImagePicker();

  XFile? _pickedImage;
  bool _removeImage = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initial.name);
    _sortOrderController =
        TextEditingController(text: '${widget.initial.sortOrder}');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (image == null) return;
    setState(() {
      _pickedImage = image;
      _removeImage = false;
    });
  }

  void _clearPicture() {
    setState(() {
      _pickedImage = null;
      _removeImage = true;
    });
  }

  Future<void> _save() async {
    final sortParsed = int.tryParse(_sortOrderController.text.trim());
    if (sortParsed == null || sortParsed < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid sort order (0 or higher)')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final categories = context.read<CategoriesProvider>();
      final productsProvider = context.read<ProductsProvider>();

      String? uploadedUrl;
      if (_pickedImage != null) {
        uploadedUrl = await const ProductImageStorageService().uploadCategoryImage(
          categoryDocId: widget.initial.id,
          image: _pickedImage!,
        );
      }

      await categories.saveCatalogCategoryEdits(
            doc: widget.initial,
            newName: _nameController.text,
            sortOrder: sortParsed,
            newImageUrl: uploadedUrl,
            removeImage: _removeImage && _pickedImage == null,
          );

      await productsProvider.fetchProducts(includeHiddenFromCatalog: true);

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category saved')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _preview() {
    final size = 120.0;
    Widget child;
    if (_pickedImage != null) {
      child = Image.file(
        File(_pickedImage!.path),
        fit: BoxFit.cover,
        width: size,
        height: size,
      );
    } else if (!_removeImage &&
        widget.initial.imageUrl != null &&
        widget.initial.imageUrl!.trim().isNotEmpty) {
      child = NetworkProductImage(
        imageUrl: widget.initial.imageUrl!,
        width: size,
        height: size,
        boxFit: BoxFit.cover,
      );
    } else {
      child = Center(
        child: Icon(
          Icons.image_outlined,
          size: 48,
          color: Theme.of(context).colorScheme.outline,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: size,
        height: size,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return AbsorbPointer(
      absorbing: _saving,
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 8,
          bottom: 24 + bottomInset,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Edit category',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 16),
              Center(child: _preview()),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_library_outlined, size: 20),
                    label: const Text('Choose picture'),
                  ),
                  const SizedBox(width: 10),
                  if (_pickedImage != null ||
                      (!_removeImage &&
                          (widget.initial.imageUrl?.isNotEmpty ?? false)))
                    TextButton.icon(
                      onPressed: _clearPicture,
                      icon: const Icon(Icons.hide_image_outlined, size: 20),
                      label: const Text('Remove'),
                    ),
                ],
              ),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Category name',
                  helperText: 'Changing name updates all products in this category',
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _sortOrderController,
                decoration: const InputDecoration(
                  labelText: 'Sort order',
                  helperText: 'Lower numbers list first (admin / future storefront)',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_saving ? 'Saving…' : 'Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

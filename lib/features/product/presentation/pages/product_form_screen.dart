import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fruit_factory_stock/features/product/presentation/providers/product_providers.dart';
import 'package:fruit_factory_stock/shared/models/product_type.dart';
import 'package:uuid/uuid.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  final ProductType? existingProduct;

  const ProductFormScreen({
    Key? key,
    this.existingProduct,
  }) : super(key: key);

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  late TextEditingController _codeController;
  late TextEditingController _nameEnController;
  late TextEditingController _nameThController;
  late TextEditingController _unitController;
  late GlobalKey<FormState> _formKey;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _codeController = TextEditingController(
      text: widget.existingProduct?.productCode ?? '',
    );
    _nameEnController = TextEditingController(
      text: widget.existingProduct?.nameEn ?? '',
    );
    _nameThController = TextEditingController(
      text: widget.existingProduct?.nameTh ?? '',
    );
    _unitController = TextEditingController(
      text: widget.existingProduct?.unit ?? 'KG',
    );
    _isActive = widget.existingProduct?.active ?? true;
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameEnController.dispose();
    _nameThController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final product = ProductType(
      productCode: _codeController.text.trim(),
      nameEn: _nameEnController.text.trim(),
      nameTh: _nameThController.text.trim(),
      unit: _unitController.text.trim(),
      active: _isActive,
      createdAt: widget.existingProduct?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      if (widget.existingProduct == null) {
        // Create new product
        await ref
            .read(productNotifierProvider.notifier)
            .createProduct(product);
      } else {
        // Update existing product
        await ref
            .read(productNotifierProvider.notifier)
            .updateProduct(product);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingProduct == null
                  ? 'Product created successfully'
                  : 'Product updated successfully',
            ),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingProduct != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Product' : 'Add Product'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Product Code (read-only if editing)
                TextFormField(
                  controller: _codeController,
                  enabled: !isEditing,
                  decoration: InputDecoration(
                    labelText: 'Product Code',
                    hintText: 'e.g., RD-001',
                    prefixIcon: const Icon(Icons.code),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Product code is required';
                    }
                    if (value.length > 10) {
                      return 'Product code must be 10 characters or less';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // English Name
                TextFormField(
                  controller: _nameEnController,
                  decoration: InputDecoration(
                    labelText: 'Name (English)',
                    hintText: 'e.g., Red Cap',
                    prefixIcon: const Icon(Icons.label),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'English name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Thai Name
                TextFormField(
                  controller: _nameThController,
                  decoration: InputDecoration(
                    labelText: 'Name (Thai)',
                    hintText: 'เช่น ฝาแดง',
                    prefixIcon: const Icon(Icons.label),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Thai name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Unit
                TextFormField(
                  controller: _unitController,
                  decoration: InputDecoration(
                    labelText: 'Unit',
                    hintText: 'e.g., KG',
                    prefixIcon: const Icon(Icons.straighten),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Unit is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Active toggle
                CheckboxListTile(
                  title: const Text('Active'),
                  value: _isActive,
                  onChanged: (value) {
                    setState(() {
                      _isActive = value ?? true;
                    });
                  },
                ),
                const SizedBox(height: 32),
                // Save button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _handleSave,
                    child: Text(isEditing ? 'Update Product' : 'Create Product'),
                  ),
                ),
                const SizedBox(height: 16),
                // Cancel button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

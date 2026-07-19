import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../providers/product_providers.dart';
import '../../data/models/product_model.dart';  // ✅ Fixed path

class ProductFormScreen extends ConsumerStatefulWidget {
  final Product? existingProduct;
  const ProductFormScreen({Key? key, this.existingProduct}) : super(key: key);

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _unitController = TextEditingController(text: 'KG');
  final _stockController = TextEditingController(text: '0');
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingProduct != null) {
      _nameController.text = widget.existingProduct!.name;
      _codeController.text = widget.existingProduct!.code;
      _unitController.text = widget.existingProduct!.unit;
      _stockController.text = widget.existingProduct!.stock.toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _unitController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final now = DateTime.now();
    final product = Product(
      id: widget.existingProduct?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      code: _codeController.text.trim().toUpperCase(),
      unit: _unitController.text.trim(),
      stock: int.tryParse(_stockController.text) ?? 0,
      createdAt: widget.existingProduct?.createdAt ?? now,
      updatedAt: now,
    );
    try {
      if (widget.existingProduct == null) {
        await ref.read(productNotifierProvider.notifier).addProduct(product);
      } else {
        await ref.read(productNotifierProvider.notifier).updateProduct(product);
      }
      ref.refresh(productListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingProduct == null ? 'Product created successfully' : 'Product updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingProduct != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Product' : 'Add Product'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Product Name', prefixIcon: Icon(Icons.inventory_2)),
                validator: (value) => value == null || value.isEmpty ? 'Product name is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(labelText: 'Product Code', prefixIcon: Icon(Icons.code), hintText: 'e.g., RD-001'),
                validator: (value) => value == null || value.isEmpty ? 'Product code is required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _unitController,
                      decoration: const InputDecoration(labelText: 'Unit', prefixIcon: Icon(Icons.straighten)),
                      validator: (value) => value == null || value.isEmpty ? 'Unit is required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _stockController,
                      decoration: const InputDecoration(labelText: 'Stock', prefixIcon: Icon(Icons.numbers)),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Stock is required';
                        if (int.tryParse(value) == null) return 'Must be a number';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProduct,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(isEditing ? 'Update Product' : 'Add Product'),
                ),
              ),
              const SizedBox(height: 16),
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
    );
  }
}

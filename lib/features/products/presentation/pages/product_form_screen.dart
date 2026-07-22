import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../providers/product_providers.dart';
import '../../data/models/product_model.dart';

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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingProduct != null) {
      _nameController.text = widget.existingProduct!.name;
      _codeController.text = widget.existingProduct!.code;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
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
      stock: widget.existingProduct?.stock ?? 0.0,
      unit: widget.existingProduct?.unit ?? 'KG',
      factoryId: widget.existingProduct?.factoryId,
      createdAt: widget.existingProduct?.createdAt ?? now,
      updatedAt: now,
      createdBy: widget.existingProduct?.createdBy,
      updatedBy: widget.existingProduct?.updatedBy,
      history: widget.existingProduct?.history,
    );

    try {
      if (widget.existingProduct == null) {
        await ref.read(productNotifierProvider.notifier).addProduct(product);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('เพิ่มสินค้าสำเร็จ'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        await ref.read(productNotifierProvider.notifier).updateProduct(product);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('อัปเดตสินค้าสำเร็จ'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      // ✅ รีเฟรช productListProvider
      ref.refresh(productListProvider);
      
      if (mounted) {
        context.pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาด: $e'),
          backgroundColor: Colors.red,
        ),
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
        title: Text(isEditing ? 'แก้ไขสินค้า' : 'เพิ่มสินค้า'),
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
                decoration: const InputDecoration(
                  labelText: 'ชื่อสินค้า',
                  prefixIcon: Icon(Icons.inventory_2),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty ? 'กรุณากรอกชื่อสินค้า' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'รหัสสินค้า',
                  prefixIcon: Icon(Icons.code),
                  border: OutlineInputBorder(),
                  hintText: 'เช่น APPLE-001',
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (value) => value == null || value.isEmpty ? 'กรุณากรอกรหัสสินค้า' : null,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(isEditing ? 'อัปเดตสินค้า' : 'เพิ่มสินค้า'),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () => context.pop(),
                  child: const Text('ยกเลิก'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

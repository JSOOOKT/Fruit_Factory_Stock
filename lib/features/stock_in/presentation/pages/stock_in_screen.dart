// lib/features/stock_in/presentation/pages/stock_in_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../../products/presentation/providers/product_providers.dart';
import '../providers/stock_in_providers.dart';
import '../../data/models/stock_in_model.dart';

class StockInScreen extends ConsumerStatefulWidget {
  const StockInScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<StockInScreen> createState() => _StockInScreenState();
}

class _StockInScreenState extends ConsumerState<StockInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _noteController = TextEditingController();
  String? _selectedProductId;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void dispose() {
    _quantityController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submitStockIn() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProductId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a product'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    final products = ref.read(productListProvider).valueOrNull ?? [];
    final product = products.firstWhere((p) => p.id == _selectedProductId);
    final quantity = int.tryParse(_quantityController.text) ?? 0;

    final stockIn = StockIn(
      id: const Uuid().v4(),
      productId: product.id,
      productName: product.name,
      productCode: product.code,
      quantity: quantity,
      unit: product.unit,
      note: _noteController.text.isNotEmpty ? _noteController.text : null,
      date: _selectedDate,
      recordedBy: 'user', // TODO: Get from auth
      createdAt: DateTime.now(),
    );

    try {
      await ref.read(stockInNotifierProvider.notifier).addStockIn(stockIn);
      ref.refresh(stockInListProvider);
      ref.refresh(productListProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stock in recorded successfully!'), backgroundColor: Colors.green),
        );
        _quantityController.clear();
        _noteController.clear();
        setState(() => _selectedProductId = null);
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
    final productsAsync = ref.watch(productListProvider);
    final stockInAsync = ref.watch(stockInListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock In'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => context.push('/stock-in/history'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Form
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Product Dropdown
                      productsAsync.when(
                        data: (products) => DropdownButtonFormField<String>(
                          value: _selectedProductId,
                          decoration: const InputDecoration(
                            labelText: 'Product',
                            prefixIcon: Icon(Icons.inventory_2),
                          ),
                          items: products.map((product) {
                            return DropdownMenuItem(
                              value: product.id,
                              child: Text('${product.code} - ${product.name} (${product.stock} ${product.unit})'),
                            );
                          }).toList(),
                          onChanged: (value) => setState(() => _selectedProductId = value),
                          validator: (value) => value == null ? 'Please select a product' : null,
                        ),
                        loading: () => DropdownButtonFormField(
                          decoration: InputDecoration(labelText: 'Loading...'),
                          items: [],
                          onChanged: null,
                        ),
                        error: (error, stack) => DropdownButtonFormField(
                          decoration: InputDecoration(labelText: 'Error loading products'),
                          items: [],
                          onChanged: null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Quantity
                      TextFormField(
                        controller: _quantityController,
                        decoration: const InputDecoration(
                          labelText: 'Quantity',
                          prefixIcon: Icon(Icons.numbers),
                          suffixText: 'KG',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Quantity is required';
                          if (int.tryParse(value) == null) return 'Must be a number';
                          if (int.parse(value) <= 0) return 'Quantity must be greater than 0';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Date
                      InkWell(
                        onTap: () => _selectDate(context),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Date',
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Note
                      TextFormField(
                        controller: _noteController,
                        decoration: const InputDecoration(
                          labelText: 'Note (Optional)',
                          prefixIcon: Icon(Icons.note),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      
                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitStockIn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Record Stock In'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Recent Stock In
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Stock In',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: stockInAsync.when(
                      data: (stockIns) {
                        if (stockIns.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inbox, size: 48, color: Colors.grey[400]),
                                const SizedBox(height: 8),
                                Text('No stock in records', style: TextStyle(color: Colors.grey[600])),
                              ],
                            ),
                          );
                        }
                        return ListView.builder(
                          itemCount: stockIns.length > 10 ? 10 : stockIns.length,
                          itemBuilder: (context, index) {
                            final item = stockIns[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue[100],
                                child: Text(item.productCode[0]),
                              ),
                              title: Text(item.productName),
                              subtitle: Text('${DateFormat('dd/MM/yyyy').format(item.date)} - ${item.note ?? ''}'),
                              trailing: Text(
                                '+${item.quantity} ${item.unit}',
                                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                              ),
                            );
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (error, stack) => Center(child: Text('Error: $error')),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
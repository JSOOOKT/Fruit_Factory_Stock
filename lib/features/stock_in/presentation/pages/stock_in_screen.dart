import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../products/presentation/providers/product_providers.dart';
import '../../../products/data/models/product_model.dart';
import '../../../tanks/presentation/providers/tank_providers.dart';
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
  final _supplierController = TextEditingController();
  final _noteController = TextEditingController();
  final _newProductNameController = TextEditingController();
  final _newProductCodeController = TextEditingController();
  final _newTankTypeController = TextEditingController();
  
  String? _selectedProductId;
  String? _selectedTankType;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  String? _userName;

  Future<void> _loadUserData() async {
    final userData = await ref.read(currentUserDataProvider.future);
    if (userData != null) {
      _userName = userData['name'] ?? 'unknown';
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _supplierController.dispose();
    _noteController.dispose();
    _newProductNameController.dispose();
    _newProductCodeController.dispose();
    _newTankTypeController.dispose();
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

  Future<void> _showAddProductDialog() async {
    _newProductNameController.clear();
    _newProductCodeController.clear();

    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('เพิ่มสินค้าใหม่'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _newProductNameController,
              decoration: const InputDecoration(
                labelText: 'ชื่อสินค้า',
                border: OutlineInputBorder(),
                hintText: 'เช่น แอปเปิ้ลแดง',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _newProductCodeController,
              decoration: const InputDecoration(
                labelText: 'รหัสสินค้า',
                border: OutlineInputBorder(),
                hintText: 'เช่น APPLE-001',
              ),
              textCapitalization: TextCapitalization.characters,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = _newProductNameController.text.trim();
              final code = _newProductCodeController.text.trim().toUpperCase();

              if (name.isEmpty || code.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('กรุณากรอกข้อมูลให้ครบ'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              try {
                final user = ref.read(currentUserProvider);
                final factoryId = ref.read(currentFactoryIdProvider);
                final product = Product(
                  id: const Uuid().v4(),
                  name: name,
                  code: code,
                  factoryId: factoryId ?? user?.uid,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );

                await ref.read(productNotifierProvider.notifier).addProduct(product);
                ref.refresh(productListProvider);
                
                setState(() => _selectedProductId = product.id);
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('เพิ่มสินค้าสำเร็จ!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context, true);
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('เพิ่มสินค้า'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddTankDialog() async {
    _newTankTypeController.clear();

    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('เพิ่มประเภทถังใหม่'),
        content: TextFormField(
          controller: _newTankTypeController,
          decoration: const InputDecoration(
            labelText: 'ประเภทถัง',
            border: OutlineInputBorder(),
            hintText: 'เช่น ถังเขียว, ถังแดง',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              final tankType = _newTankTypeController.text.trim();
              if (tankType.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('กรุณากรอกประเภทถัง'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              try {
                final factoryId = ref.read(currentFactoryIdProvider);
                if (factoryId == null) return;

                final repository = ref.read(tankRepositoryProvider);
                await repository.addTank(
                  factoryId: factoryId,
                  tankType: tankType,
                  tankNumber: null,
                );

                ref.refresh(tankListProvider);
                ref.refresh(tankListStreamProvider);
                
                setState(() => _selectedTankType = tankType);
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('เพิ่มประเภทถังสำเร็จ!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context, true);
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('เพิ่มถัง'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitStockIn() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProductId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกสินค้า'), backgroundColor: Colors.orange),
      );
      return;
    }

    // ✅ บังคับเลือกประเภทถัง
    if (_selectedTankType == null || _selectedTankType!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาเลือกประเภทถัง'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final user = ref.read(currentUserProvider);
    final factoryId = ref.read(currentFactoryIdProvider);
    final products = ref.read(productListProvider).valueOrNull ?? [];
    final product = products.firstWhere((p) => p.id == _selectedProductId);
    final quantity = double.tryParse(_quantityController.text) ?? 0;

    final stockIn = StockIn(
      id: const Uuid().v4(),
      productId: product.id,
      productName: product.name,
      productCode: product.code,
      quantity: quantity,
      unit: 'KG',
      supplierName: _supplierController.text.isNotEmpty 
          ? _supplierController.text.trim() 
          : null,
      tankType: _selectedTankType!, // ✅ บันทึกประเภทถัง
      tankNumber: null,
      note: _noteController.text.isNotEmpty ? _noteController.text.trim() : null,
      date: _selectedDate,
      recordedBy: _userName ?? user?.uid ?? 'unknown',
      factoryId: factoryId ?? user?.uid,
      createdAt: DateTime.now(),
    );

    try {
      await ref.read(stockInNotifierProvider.notifier).addStockIn(stockIn);
      ref.refresh(stockInListProvider);
      ref.refresh(productListProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกการนำเข้าสำเร็จ!'), backgroundColor: Colors.green),
        );
        _quantityController.clear();
        _supplierController.clear();
        _noteController.clear();
        setState(() {
          _selectedProductId = null;
          _selectedTankType = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productListProvider);
    final stockInAsync = ref.watch(stockInListProvider);
    final tanksAsync = ref.watch(tankListStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('นำเข้า'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => context.push('/stock-in/history'),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Form
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              productsAsync.when(
                                data: (products) => DropdownButtonFormField<String>(
                                  value: _selectedProductId,
                                  decoration: const InputDecoration(
                                    labelText: 'สินค้า *',
                                    prefixIcon: Icon(Icons.inventory_2),
                                    border: OutlineInputBorder(),
                                  ),
                                  items: [
                                    const DropdownMenuItem(
                                      value: '__add_new__',
                                      child: Row(
                                        children: [
                                          Icon(Icons.add_circle, color: Colors.green),
                                          SizedBox(width: 8),
                                          Text('+ เพิ่มสินค้าใหม่'),
                                        ],
                                      ),
                                    ),
                                    ...products.map((product) {
                                      return DropdownMenuItem(
                                        value: product.id,
                                        child: Text('${product.code} - ${product.name}'),
                                      );
                                    }).toList(),
                                  ],
                                  onChanged: (value) {
                                    if (value == '__add_new__') {
                                      _showAddProductDialog();
                                    } else {
                                      setState(() => _selectedProductId = value);
                                    }
                                  },
                                  validator: (value) => 
                                      value == null || value == '__add_new__'
                                          ? 'กรุณาเลือกสินค้า' 
                                          : null,
                                ),
                                loading: () => DropdownButtonFormField<String>(
                                  decoration: const InputDecoration(
                                    labelText: 'กำลังโหลด...',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: [],
                                  onChanged: null,
                                ),
                                error: (error, stack) => DropdownButtonFormField<String>(
                                  decoration: InputDecoration(
                                    labelText: 'เกิดข้อผิดพลาด',
                                    errorText: error.toString(),
                                    border: OutlineInputBorder(),
                                  ),
                                  items: [],
                                  onChanged: null,
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              TextFormField(
                                controller: _quantityController,
                                decoration: const InputDecoration(
                                  labelText: 'จำนวน (กิโลกรัม) *',
                                  prefixIcon: Icon(Icons.numbers),
                                  suffixText: 'KG',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'กรุณากรอกจำนวน';
                                  }
                                  if (double.tryParse(value) == null) {
                                    return 'กรุณากรอกตัวเลข';
                                  }
                                  if (double.parse(value) <= 0) {
                                    return 'จำนวนต้องมากกว่า 0';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              
                              TextFormField(
                                controller: _supplierController,
                                decoration: const InputDecoration(
                                  labelText: 'ชื่อผู้ส่ง / บริษัท *',
                                  prefixIcon: Icon(Icons.business),
                                  border: OutlineInputBorder(),
                                  hintText: 'เช่น บริษัท ผลไม้ไทย จำกัด',
                                ),
                                validator: (value) => 
                                    value == null || value.isEmpty
                                        ? 'กรุณากรอกชื่อผู้ส่ง'
                                        : null,
                              ),
                              const SizedBox(height: 16),

                              // ✅ ประเภทถัง (บังคับ)
                              tanksAsync.when(
                                data: (tanks) {
                                  final tankTypes = tanks.map((t) => t.tankType).toSet().toList();
                                  
                                  return DropdownButtonFormField<String>(
                                    value: _selectedTankType,
                                    decoration: const InputDecoration(
                                      labelText: 'ประเภทถัง *',
                                      prefixIcon: Icon(Icons.inventory),
                                      border: OutlineInputBorder(),
                                    ),
                                    hint: const Text('เลือกประเภทถัง'),
                                    items: [
                                      const DropdownMenuItem(
                                        value: '__add_new_tank__',
                                        child: Row(
                                          children: [
                                            Icon(Icons.add_circle, color: Colors.blue),
                                            SizedBox(width: 8),
                                            Text('+ เพิ่มประเภทถังใหม่'),
                                          ],
                                        ),
                                      ),
                                      ...tankTypes.map((type) {
                                        return DropdownMenuItem(
                                          value: type,
                                          child: Text(type),
                                        );
                                      }).toList(),
                                    ],
                                    onChanged: (value) {
                                      if (value == '__add_new_tank__') {
                                        _showAddTankDialog();
                                      } else {
                                        setState(() => _selectedTankType = value);
                                      }
                                    },
                                    validator: (value) => value == null ? 'กรุณาเลือกประเภทถัง' : null,
                                  );
                                },
                                loading: () => DropdownButtonFormField<String>(
                                  decoration: const InputDecoration(
                                    labelText: 'กำลังโหลดประเภทถัง...',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: [],
                                  onChanged: null,
                                ),
                                error: (_, __) => DropdownButtonFormField<String>(
                                  decoration: const InputDecoration(
                                    labelText: 'ไม่สามารถโหลดประเภทถัง',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: [],
                                  onChanged: null,
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              InkWell(
                                onTap: () => _selectDate(context),
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'วันที่รับเข้า *',
                                    prefixIcon: Icon(Icons.calendar_today),
                                    border: OutlineInputBorder(),
                                  ),
                                  child: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              TextFormField(
                                controller: _noteController,
                                decoration: const InputDecoration(
                                  labelText: 'หมายเหตุ (ไม่บังคับ)',
                                  prefixIcon: Icon(Icons.note),
                                  border: OutlineInputBorder(),
                                ),
                                maxLines: 2,
                              ),
                              const SizedBox(height: 16),
                              
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
                                      : const Text('บันทึกการนำเข้า'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Recent Stock In
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ประวัติการนำเข้าระยะล่าสุด',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 200,
                          child: stockInAsync.when(
                            data: (stockIns) {
                              if (stockIns.isEmpty) {
                                return const Center(
                                  child: Text(
                                    'ยังไม่มีประวัติการนำเข้า',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                );
                              }
                              return ListView.builder(
                                shrinkWrap: true,
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: stockIns.length > 10 ? 10 : stockIns.length,
                                itemBuilder: (context, index) {
                                  final item = stockIns[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: Colors.blue[100],
                                        child: Text(item.productCode[0].toUpperCase()),
                                      ),
                                      title: Text(item.productName),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('${DateFormat('dd/MM/yyyy').format(item.date)}'),
                                          if (item.supplierName != null)
                                            Text(
                                              'ผู้ส่ง: ${item.supplierName}',
                                              style: const TextStyle(fontSize: 12),
                                            ),
                                          if (item.tankType != null && item.tankType!.isNotEmpty)
                                            Text(
                                              'ถัง: ${item.tankType}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blue,
                                              ),
                                            ),
                                        ],
                                      ),
                                      trailing: Text(
                                        '+${item.quantity} ${item.unit}',
                                        style: const TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (error, stack) => Center(
                              child: Text('เกิดข้อผิดพลาด: $error'),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

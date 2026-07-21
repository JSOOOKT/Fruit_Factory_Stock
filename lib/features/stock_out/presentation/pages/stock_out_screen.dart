import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../products/presentation/providers/product_providers.dart';
import '../../../products/data/models/product_model.dart';
import '../../../tanks/presentation/providers/tank_providers.dart';
import '../providers/stock_out_providers.dart';
import '../../data/models/stock_out_model.dart';
import '../providers/purpose_providers.dart';

class StockOutScreen extends ConsumerStatefulWidget {
  const StockOutScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<StockOutScreen> createState() => _StockOutScreenState();
}

class _StockOutScreenState extends ConsumerState<StockOutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _purposeController = TextEditingController();
  final _noteController = TextEditingController();
  final _newProductNameController = TextEditingController();
  final _newProductCodeController = TextEditingController();
  final _tankNumberController = TextEditingController();
  
  String? _selectedProductId;
  String? _selectedTankType;
  String? _selectedTankNumber;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  bool _showCustomTankNumber = false;
  double _currentBalance = 0;
  bool _isCheckingBalance = false;
  String? _userName;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userData = await ref.read(currentUserDataProvider.future);
    if (userData != null) {
      _userName = userData['name'] ?? 'unknown';
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _purposeController.dispose();
    _noteController.dispose();
    _newProductNameController.dispose();
    _newProductCodeController.dispose();
    _tankNumberController.dispose();
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

  Future<void> _checkBalance(String productId) async {
    if (productId.isEmpty) return;
    
    setState(() => _isCheckingBalance = true);
    
    try {
      final products = ref.read(productListProvider).valueOrNull ?? [];
      final product = products.firstWhere((p) => p.id == productId);
      setState(() => _currentBalance = product.stock);
    } catch (e) {
      // Handle error silently
    } finally {
      setState(() => _isCheckingBalance = false);
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

  Future<void> _submitStockOut() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProductId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกสินค้า'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    final user = ref.read(currentUserProvider);
    final factoryId = ref.read(currentFactoryIdProvider);
    final products = ref.read(productListProvider).valueOrNull ?? [];
    final product = products.firstWhere((p) => p.id == _selectedProductId);
    final quantity = double.tryParse(_quantityController.text) ?? 0;

    final stockOut = StockOut(
      id: const Uuid().v4(),
      productId: product.id,
      productName: product.name,
      productCode: product.code,
      quantity: quantity,
      unit: 'KG',
      purpose: _purposeController.text.isNotEmpty ? _purposeController.text.trim() : null,
      tankType: _selectedTankType,
      tankNumber: _selectedTankNumber ?? 
          (_tankNumberController.text.isNotEmpty ? _tankNumberController.text.trim() : null),
      note: _noteController.text.isNotEmpty ? _noteController.text.trim() : null,
      date: _selectedDate,
      recordedBy: _userName ?? user?.uid ?? 'unknown',
      factoryId: factoryId ?? user?.uid,
      createdAt: DateTime.now(),
    );

    try {
      final success = await ref.read(stockOutNotifierProvider.notifier).addStockOut(stockOut);
      
      if (success) {
        // Save purpose to history
        if (_purposeController.text.isNotEmpty) {
          final purposeService = ref.read(purposeServiceProvider);
          await purposeService.savePurpose(
            factoryId ?? '',
            _purposeController.text.trim(),
          );
        }
        
        ref.refresh(stockOutListProvider);
        ref.refresh(productListProvider);
        ref.refresh(purposeHistoryProvider);
        ref.refresh(purposeHistoryStreamProvider);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('บันทึกการเบิกออกสำเร็จ!'), backgroundColor: Colors.green),
          );
          _quantityController.clear();
          _purposeController.clear();
          _noteController.clear();
          _tankNumberController.clear();
          setState(() {
            _selectedProductId = null;
            _selectedTankType = null;
            _selectedTankNumber = null;
            _showCustomTankNumber = false;
            _currentBalance = 0;
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('สินค้าไม่เพียงพอ!'), backgroundColor: Colors.red),
        );
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
    final stockOutAsync = ref.watch(stockOutListProvider);
    final purposesAsync = ref.watch(purposeHistoryStreamProvider);
    final tanksAsync = ref.watch(tankListStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('เบิกออก'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => context.push('/stock-out/history'),
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
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Product Dropdown with Add New Option
                        productsAsync.when(
                          data: (products) => DropdownButtonFormField<String>(
                            value: _selectedProductId,
                            decoration: const InputDecoration(
                              labelText: 'สินค้า',
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
                                if (value != null) {
                                  _checkBalance(value);
                                }
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

                        // Current Balance Display
                        if (_isCheckingBalance)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                SizedBox(width: 8),
                                Text('กำลังตรวจสอบสต็อก...'),
                              ],
                            ),
                          ),
                        if (_currentBalance > 0 && !_isCheckingBalance)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _currentBalance < 50 ? Colors.red[50] : Colors.green[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _currentBalance < 50 ? Colors.red : Colors.green,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _currentBalance < 50 ? Icons.warning : Icons.info_outline,
                                  color: _currentBalance < 50 ? Colors.red : Colors.green,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'สต็อกคงเหลือ: ${_currentBalance.toStringAsFixed(1)} KG',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _currentBalance < 50 ? Colors.red : Colors.green,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 16),
                        
                        // Quantity
                        TextFormField(
                          controller: _quantityController,
                          decoration: const InputDecoration(
                            labelText: 'จำนวน (กิโลกรัม)',
                            prefixIcon: Icon(Icons.numbers),
                            suffixText: 'KG',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'กรุณากรอกจำนวน';
                            }
                            final quantity = double.tryParse(value);
                            if (quantity == null) {
                              return 'กรุณากรอกตัวเลข';
                            }
                            if (quantity <= 0) {
                              return 'จำนวนต้องมากกว่า 0';
                            }
                            if (_currentBalance > 0 && quantity > _currentBalance) {
                              return 'สินค้าไม่เพียงพอ คงเหลือ: ${_currentBalance.toStringAsFixed(1)} KG';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Purpose with Autocomplete - ใช้ Stream
                        purposesAsync.when(
                          data: (purposes) {
                            return Autocomplete<String>(
                              optionsBuilder: (TextEditingValue textEditingValue) {
                                if (textEditingValue.text.isEmpty) {
                                  return purposes;
                                }
                                return purposes.where((purpose) =>
                                    purpose.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                              },
                              onSelected: (String selection) {
                                _purposeController.text = selection;
                              },
                              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                                return TextFormField(
                                  controller: controller,
                                  focusNode: focusNode,
                                  decoration: const InputDecoration(
                                    labelText: 'วัตถุประสงค์',
                                    prefixIcon: Icon(Icons.info),
                                    border: OutlineInputBorder(),
                                    hintText: 'พิมพ์หรือเลือกจากประวัติ',
                                  ),
                                  validator: (value) => value == null || value.isEmpty
                                      ? 'กรุณากรอกวัตถุประสงค์'
                                      : null,
                                );
                              },
                            );
                          },
                          loading: () => TextFormField(
                            controller: _purposeController,
                            decoration: const InputDecoration(
                              labelText: 'วัตถุประสงค์',
                              prefixIcon: Icon(Icons.info),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) => value == null || value.isEmpty
                                ? 'กรุณากรอกวัตถุประสงค์'
                                : null,
                          ),
                          error: (_, __) => TextFormField(
                            controller: _purposeController,
                            decoration: const InputDecoration(
                              labelText: 'วัตถุประสงค์',
                              prefixIcon: Icon(Icons.info),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) => value == null || value.isEmpty
                                ? 'กรุณากรอกวัตถุประสงค์'
                                : null,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Tank Type - ใช้ Stream
                        tanksAsync.when(
                          data: (tanks) {
                            final tankTypes = tanks.map((t) => t.tankType).toSet().toList();
                            if (tankTypes.isEmpty) {
                              return Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.orange[50],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.orange[200]!),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.warning, color: Colors.orange[700]),
                                        const SizedBox(width: 8),
                                        const Expanded(
                                          child: Text(
                                            'ยังไม่มีประเภทถัง กรุณาเพิ่มในหน้าการตั้งค่า',
                                            style: TextStyle(fontSize: 14),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              );
                            }
                            return Column(
                              children: [
                                DropdownButtonFormField<String>(
                                  value: _selectedTankType,
                                  decoration: const InputDecoration(
                                    labelText: 'ประเภทถัง (ไม่บังคับ)',
                                    prefixIcon: Icon(Icons.inventory),
                                    border: OutlineInputBorder(),
                                  ),
                                  hint: const Text('เลือกประเภทถัง'),
                                  items: tankTypes.map((type) {
                                    return DropdownMenuItem(
                                      value: type,
                                      child: Text(type),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedTankType = value;
                                      _selectedTankNumber = null;
                                      _showCustomTankNumber = false;
                                      _tankNumberController.clear();
                                    });
                                  },
                                ),
                                const SizedBox(height: 16),
                              ],
                            );
                          },
                          loading: () => Column(
                            children: [
                              DropdownButtonFormField(
                                decoration: const InputDecoration(
                                  labelText: 'กำลังโหลดประเภทถัง...',
                                  border: OutlineInputBorder(),
                                ),
                                items: [],
                                onChanged: null,
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                          error: (_, __) => Column(
                            children: [
                              DropdownButtonFormField(
                                decoration: const InputDecoration(
                                  labelText: 'ไม่สามารถโหลดประเภทถัง',
                                  border: OutlineInputBorder(),
                                ),
                                items: [],
                                onChanged: null,
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),

                        // Tank Number (แสดงเมื่อเลือกประเภทถังแล้ว)
                        if (_selectedTankType != null)
                          tanksAsync.when(
                            data: (tanks) {
                              final tankNumbers = tanks
                                  .where((t) => t.tankType == _selectedTankType && t.tankNumber != null)
                                  .map((t) => t.tankNumber!)
                                  .toList();
                              
                              if (tankNumbers.isEmpty && !_showCustomTankNumber) {
                                return TextFormField(
                                  controller: _tankNumberController,
                                  decoration: const InputDecoration(
                                    labelText: 'เลขถัง (ไม่บังคับ)',
                                    prefixIcon: Icon(Icons.numbers),
                                    border: OutlineInputBorder(),
                                    hintText: 'ระบุเลขถัง',
                                  ),
                                );
                              }
                              
                              if (tankNumbers.isNotEmpty && !_showCustomTankNumber) {
                                return DropdownButtonFormField<String>(
                                  value: _selectedTankNumber,
                                  decoration: const InputDecoration(
                                    labelText: 'เลขถัง',
                                    prefixIcon: Icon(Icons.numbers),
                                    border: OutlineInputBorder(),
                                  ),
                                  hint: const Text('เลือกเลขถัง'),
                                  items: [
                                    const DropdownMenuItem(
                                      value: '__custom__',
                                      child: Text('+ ระบุเลขถังเอง'),
                                    ),
                                    ...tankNumbers.map((number) {
                                      return DropdownMenuItem(
                                        value: number,
                                        child: Text(number),
                                      );
                                    }).toList(),
                                  ],
                                  onChanged: (value) {
                                    if (value == '__custom__') {
                                      setState(() {
                                        _showCustomTankNumber = true;
                                        _selectedTankNumber = null;
                                        _tankNumberController.clear();
                                      });
                                    } else {
                                      setState(() {
                                        _selectedTankNumber = value;
                                        _tankNumberController.text = value ?? '';
                                      });
                                    }
                                  },
                                );
                              }
                              return const SizedBox.shrink();
                            },
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),

                        // Custom Tank Number Field
                        if (_showCustomTankNumber)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: TextFormField(
                              controller: _tankNumberController,
                              decoration: const InputDecoration(
                                labelText: 'ระบุเลขถัง',
                                prefixIcon: Icon(Icons.numbers),
                                border: OutlineInputBorder(),
                                hintText: 'เช่น T-001',
                              ),
                            ),
                          ),
                        
                        // Date
                        InkWell(
                          onTap: () => _selectDate(context),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'วันที่เบิก',
                              prefixIcon: Icon(Icons.calendar_today),
                              border: OutlineInputBorder(),
                            ),
                            child: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Note
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
                        
                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submitStockOut,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text('บันทึกการเบิกออก'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Recent Stock Out
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ประวัติการเบิกระยะล่าสุด',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: stockOutAsync.when(
                      data: (stockOuts) {
                        if (stockOuts.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inbox, size: 48, color: Colors.grey[400]),
                                const SizedBox(height: 8),
                                Text(
                                  'ยังไม่มีประวัติการเบิกออก',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          );
                        }
                        return ListView.builder(
                          itemCount: stockOuts.length > 10 ? 10 : stockOuts.length,
                          itemBuilder: (context, index) {
                            final item = stockOuts[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.orange[100],
                                  child: Text(item.productCode[0].toUpperCase()),
                                ),
                                title: Text(item.productName),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${DateFormat('dd/MM/yyyy').format(item.date)}'),
                                    if (item.purpose != null)
                                      Text(
                                        'วัตถุประสงค์: ${item.purpose}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    if (item.tankType != null)
                                      Text(
                                        'ถัง: ${item.tankType}${item.tankNumber != null ? ' (${item.tankNumber})' : ''}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    if (item.note != null)
                                      Text(
                                        'หมายเหตุ: ${item.note}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                  ],
                                ),
                                trailing: Text(
                                  '-${item.quantity} ${item.unit}',
                                  style: const TextStyle(
                                    color: Colors.red,
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
                        child: Column(
                          children: [
                            Text('เกิดข้อผิดพลาด: $error'),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () => ref.refresh(stockOutListProvider),
                              child: const Text('ลองใหม่'),
                            ),
                          ],
                        ),
                      ),
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

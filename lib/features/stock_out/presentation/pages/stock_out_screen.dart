import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../products/presentation/providers/product_providers.dart';
import '../../../products/data/models/product_model.dart';
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
  final _tankNumberController = TextEditingController();
  final _newPurposeController = TextEditingController();
  
  String? _selectedProductId;
  String? _selectedTankType;
  String? _selectedTankNumber;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  double _currentBalance = 0;
  bool _isCheckingBalance = false;
  String? _userName;
  
  Product? _selectedProduct;
  List<Map<String, dynamic>> _availableTanks = [];
  bool _isLoadingTanks = false;
  bool _isAddingPurpose = false;

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
    _tankNumberController.dispose();
    _newPurposeController.dispose();
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

  Future<void> _loadAvailableTanks(String productId) async {
    setState(() => _isLoadingTanks = true);
    _availableTanks = [];
    
    try {
      final factoryId = ref.read(currentFactoryIdProvider);
      if (factoryId == null) {
        setState(() => _isLoadingTanks = false);
        return;
      }

      final firestore = FirebaseFirestore.instance;
      
      final snapshot = await firestore
          .collection('stock_in_entries')
          .where('factoryId', isEqualTo: factoryId)
          .where('product_id', isEqualTo: productId)
          .get();

      final Map<String, Map<String, dynamic>> tankMap = {};
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final tankType = data['tank_type'] as String?;
        if (tankType == null || tankType.isEmpty) continue;
        
        final quantity = (data['quantity'] as num?)?.toDouble() ?? 0;
        final key = '$productId-$tankType';
        
        if (!tankMap.containsKey(key)) {
          tankMap[key] = {
            'tankType': tankType,
            'totalIn': 0.0,
            'totalOut': 0.0,
          };
        }
        tankMap[key]!['totalIn'] = (tankMap[key]!['totalIn'] as double) + quantity;
      }

      final outSnapshot = await firestore
          .collection('stock_out_entries')
          .where('factoryId', isEqualTo: factoryId)
          .where('product_id', isEqualTo: productId)
          .get();

      for (final doc in outSnapshot.docs) {
        final data = doc.data();
        final tankType = data['tank_type'] as String?;
        if (tankType == null || tankType.isEmpty) continue;
        
        final quantity = (data['quantity'] as num?)?.toDouble() ?? 0;
        final key = '$productId-$tankType';
        
        if (tankMap.containsKey(key)) {
          tankMap[key]!['totalOut'] = (tankMap[key]!['totalOut'] as double) + quantity;
        }
      }

      _availableTanks = tankMap.values.map((data) {
        final balance = (data['totalIn'] as double) - (data['totalOut'] as double);
        return {
          'tankType': data['tankType'],
          'balance': balance,
        };
      }).where((item) => (item['balance'] as double) > 0).toList();

      _availableTanks.sort((a, b) => (b['balance'] as double).compareTo(a['balance'] as double));

      setState(() {});
      
    } catch (e) {
      print('Error loading tanks: $e');
    } finally {
      setState(() => _isLoadingTanks = false);
    }
  }

  Future<void> _checkBalance(String productId) async {
    if (productId.isEmpty) return;
    
    setState(() => _isCheckingBalance = true);
    
    try {
      final products = ref.read(productListProvider).valueOrNull ?? [];
      final product = products.firstWhere((p) => p.id == productId);
      setState(() {
        _selectedProduct = product;
        _selectedProductId = productId;
        _currentBalance = product.stock;
      });
      
      await _loadAvailableTanks(productId);
      
    } catch (e) {
      print('Error checking balance: $e');
    } finally {
      setState(() => _isCheckingBalance = false);
    }
  }

  Future<void> _addNewPurpose(String purpose) async {
    if (purpose.trim().isEmpty) return;

    setState(() => _isAddingPurpose = true);

    try {
      final factoryId = ref.read(currentFactoryIdProvider);
      if (factoryId == null) return;

      final purposeService = ref.read(purposeServiceProvider);
      await purposeService.savePurpose(factoryId, purpose.trim());

      ref.refresh(purposeHistoryProvider);
      ref.refresh(purposeHistoryStreamProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ เพิ่มวัตถุประสงค์สำเร็จ'),
            backgroundColor: Colors.green,
          ),
        );
        _purposeController.text = purpose.trim();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isAddingPurpose = false);
    }
  }

  Future<void> _submitStockOut() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProductId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกสินค้า'), backgroundColor: Colors.orange),
      );
      return;
    }

    if (_selectedTankType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกประเภทถัง'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    final user = ref.read(currentUserProvider);
    final factoryId = ref.read(currentFactoryIdProvider);
    final products = ref.read(productListProvider).valueOrNull ?? [];
    final product = products.firstWhere((p) => p.id == _selectedProductId);
    final quantity = double.tryParse(_quantityController.text) ?? 0;

    final selectedTank = _availableTanks.firstWhere(
      (t) => t['tankType'] == _selectedTankType,
      orElse: () => {'balance': 0.0},
    );
    
    if ((selectedTank['balance'] as double) < quantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('สินค้าในถัง $_selectedTankType ไม่เพียงพอ คงเหลือ: ${(selectedTank['balance'] as double).toStringAsFixed(1)} KG'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isLoading = false);
      return;
    }

    final stockOut = StockOut(
      id: const Uuid().v4(),
      productId: product.id,
      productName: product.name,
      productCode: product.code,
      quantity: quantity,
      unit: 'KG',
      purpose: _purposeController.text.isNotEmpty ? _purposeController.text.trim() : null,
      tankType: _selectedTankType,
      tankNumber: _tankNumberController.text.isNotEmpty ? _tankNumberController.text.trim() : null,
      note: _noteController.text.isNotEmpty ? _noteController.text.trim() : null,
      date: _selectedDate,
      recordedBy: _userName ?? user?.uid ?? 'unknown',
      factoryId: factoryId ?? user?.uid,
      createdAt: DateTime.now(),
    );

    try {
      final success = await ref.read(stockOutNotifierProvider.notifier).addStockOut(stockOut);
      
      if (success) {
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
            _selectedProduct = null;
            _selectedTankType = null;
            _selectedTankNumber = null;
            _currentBalance = 0;
            _availableTanks = [];
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
                              // สินค้า
                              productsAsync.when(
                                data: (products) => DropdownButtonFormField<String>(
                                  value: _selectedProductId,
                                  decoration: const InputDecoration(
                                    labelText: 'เลือกสินค้า *',
                                    prefixIcon: Icon(Icons.inventory_2),
                                    border: OutlineInputBorder(),
                                  ),
                                  hint: const Text('เลือกสินค้าที่ต้องการเบิก'),
                                  items: products.map((product) {
                                    return DropdownMenuItem<String>(
                                      value: product.id,
                                      child: Text('${product.code} - ${product.name}'),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedProductId = value;
                                      _selectedTankType = null;
                                      _availableTanks = [];
                                      _tankNumberController.clear();
                                    });
                                    if (value != null) {
                                      _checkBalance(value);
                                    }
                                  },
                                  validator: (value) => value == null ? 'กรุณาเลือกสินค้า' : null,
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

                              // แสดงสินค้า
                              if (_selectedProduct != null)
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.blue[200]!),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'สินค้า: ${_selectedProduct!.name} (${_selectedProduct!.code})',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        'ยอดรวมทั้งหมด: ${_currentBalance.toStringAsFixed(1)} KG',
                                        style: const TextStyle(color: Colors.blue),
                                      ),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 16),

                              // เลือกถัง
                              if (_availableTanks.isNotEmpty)
                                DropdownButtonFormField<String>(
                                  value: _selectedTankType,
                                  decoration: const InputDecoration(
                                    labelText: 'เลือกถังที่ต้องการเบิก *',
                                    prefixIcon: Icon(Icons.inventory),
                                    border: OutlineInputBorder(),
                                  ),
                                  hint: const Text('เลือกถังที่บันทึกไว้'),
                                  items: _availableTanks.map((tank) {
                                    final balance = tank['balance'] as double;
                                    return DropdownMenuItem<String>(
                                      value: tank['tankType'],
                                      child: Text(
                                        '${tank['tankType']} (คงเหลือ ${balance.toStringAsFixed(1)} KG)',
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() => _selectedTankType = value);
                                  },
                                  validator: (value) => value == null ? 'กรุณาเลือกถัง' : null,
                                )
                              else if (_selectedProduct != null && !_isLoadingTanks)
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.orange[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.orange[200]!),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.warning, color: Colors.orange),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'ยังไม่มีถังที่บันทึกสำหรับสินค้านี้ กรุณานำเข้าในถังก่อน',
                                          style: const TextStyle(color: Colors.orange),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else if (_selectedProduct == null)
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.info_outline, color: Colors.grey),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'กรุณาเลือกสินค้าก่อน',
                                          style: const TextStyle(color: Colors.grey),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              
                              if (_isLoadingTanks)
                                const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Center(child: CircularProgressIndicator()),
                                ),
                              
                              const SizedBox(height: 16),

                              // จำนวน
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
                                  final quantity = double.tryParse(value);
                                  if (quantity == null) {
                                    return 'กรุณากรอกตัวเลข';
                                  }
                                  if (quantity <= 0) {
                                    return 'จำนวนต้องมากกว่า 0';
                                  }
                                  if (_selectedTankType != null) {
                                    final selectedTank = _availableTanks.firstWhere(
                                      (t) => t['tankType'] == _selectedTankType,
                                      orElse: () => {'balance': 0.0},
                                    );
                                    if ((selectedTank['balance'] as double) < quantity) {
                                      return 'สินค้าในถังนี้ไม่เพียงพอ';
                                    }
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              
                              // วัตถุประสงค์
                              purposesAsync.when(
                                data: (purposes) {
                                  final allPurposes = [...purposes];
                                  if (_purposeController.text.isNotEmpty && !allPurposes.contains(_purposeController.text)) {
                                    allPurposes.add(_purposeController.text);
                                  }
                                  
                                  return DropdownButtonFormField<String>(
                                    value: _purposeController.text.isNotEmpty ? _purposeController.text : null,
                                    decoration: const InputDecoration(
                                      labelText: 'วัตถุประสงค์ *',
                                      prefixIcon: Icon(Icons.info),
                                      border: OutlineInputBorder(),
                                    ),
                                    hint: const Text('เลือกหรือพิมพ์วัตถุประสงค์'),
                                    items: [
                                      const DropdownMenuItem<String>(
                                        value: '__add_new__',
                                        child: Row(
                                          children: [
                                            Icon(Icons.add_circle, color: Colors.green),
                                            SizedBox(width: 8),
                                            Text('+ เพิ่มวัตถุประสงค์ใหม่'),
                                          ],
                                        ),
                                      ),
                                      ...allPurposes.map((purpose) {
                                        return DropdownMenuItem<String>(
                                          value: purpose,
                                          child: Text(purpose),
                                        );
                                      }).toList(),
                                    ],
                                    onChanged: (value) async {
                                      if (value == '__add_new__') {
                                        final newPurpose = await showDialog<String>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('เพิ่มวัตถุประสงค์ใหม่'),
                                            content: TextFormField(
                                              controller: _newPurposeController,
                                              decoration: const InputDecoration(
                                                labelText: 'วัตถุประสงค์',
                                                border: OutlineInputBorder(),
                                                hintText: 'เช่น ผลิต, สูญเสีย, ตัวอย่าง',
                                              ),
                                              autofocus: true,
                                              onFieldSubmitted: (value) {
                                                Navigator.pop(context, value);
                                              },
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context, null),
                                                child: const Text('ยกเลิก'),
                                              ),
                                              ElevatedButton(
                                                onPressed: () {
                                                  final purpose = _newPurposeController.text.trim();
                                                  if (purpose.isNotEmpty) {
                                                    Navigator.pop(context, purpose);
                                                  }
                                                },
                                                child: const Text('เพิ่ม'),
                                              ),
                                            ],
                                          ),
                                        );
                                        
                                        _newPurposeController.clear();
                                        
                                        if (newPurpose != null && newPurpose.isNotEmpty) {
                                          await _addNewPurpose(newPurpose);
                                        }
                                      } else {
                                        setState(() {
                                          _purposeController.text = value ?? '';
                                        });
                                      }
                                    },
                                    validator: (value) => value == null || value.isEmpty
                                        ? 'กรุณากรอกวัตถุประสงค์'
                                        : null,
                                  );
                                },
                                loading: () => TextFormField(
                                  controller: _purposeController,
                                  decoration: const InputDecoration(
                                    labelText: 'วัตถุประสงค์ *',
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
                                    labelText: 'วัตถุประสงค์ *',
                                    prefixIcon: Icon(Icons.info),
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) => value == null || value.isEmpty
                                      ? 'กรุณากรอกวัตถุประสงค์'
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // เลขถัง
                              TextFormField(
                                controller: _tankNumberController,
                                decoration: const InputDecoration(
                                  labelText: 'เลขถังที่นำออก (ไม่บังคับ)',
                                  prefixIcon: Icon(Icons.numbers),
                                  border: OutlineInputBorder(),
                                  hintText: 'ระบุเลขถังที่นำออกไปใช้',
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // วันที่
                              InkWell(
                                onTap: () => _selectDate(context),
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'วันที่เบิก *',
                                    prefixIcon: Icon(Icons.calendar_today),
                                    border: OutlineInputBorder(),
                                  ),
                                  child: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // หมายเหตุ
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
                              
                              // ปุ่มบันทึก
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
                    
                    const SizedBox(height: 16),
                    
                    // ประวัติการเบิกออก
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ประวัติการเบิกระยะล่าสุด',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 200,
                          child: stockOutAsync.when(
                            data: (stockOuts) {
                              if (stockOuts.isEmpty) {
                                return const Center(
                                  child: Text(
                                    'ยังไม่มีประวัติการเบิกออก',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                );
                              }
                              return ListView.builder(
                                shrinkWrap: true,
                                physics: const AlwaysScrollableScrollPhysics(),
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
                                              'ถัง: ${item.tankType}',
                                              style: const TextStyle(fontSize: 12),
                                            ),
                                          if (item.tankNumber != null)
                                            Text(
                                              'เลขถัง: ${item.tankNumber}',
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

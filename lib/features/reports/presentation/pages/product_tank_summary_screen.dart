import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class ProductTankSummaryScreen extends ConsumerStatefulWidget {
  const ProductTankSummaryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProductTankSummaryScreen> createState() => _ProductTankSummaryScreenState();
}

class _ProductTankSummaryScreenState extends ConsumerState<ProductTankSummaryScreen> {
  List<Map<String, dynamic>> _stockMovements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final factoryId = ref.read(currentFactoryIdProvider);
      if (factoryId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final firestore = FirebaseFirestore.instance;

      // ดึงข้อมูล stock_in
      final stockInSnapshot = await firestore
          .collection('stock_in_entries')
          .where('factoryId', isEqualTo: factoryId)
          .get();

      // ดึงข้อมูล stock_out
      final stockOutSnapshot = await firestore
          .collection('stock_out_entries')
          .where('factoryId', isEqualTo: factoryId)
          .get();

      // รวมข้อมูล
      final Map<String, Map<String, dynamic>> productMap = {};

      // Process Stock In
      for (final doc in stockInSnapshot.docs) {
        final data = doc.data();
        final productCode = data['product_code'] ?? '';
        final productName = data['product_name'] ?? '';
        final tankType = data['tank_type'] ?? 'ไม่ระบุ';
        final quantity = (data['quantity'] as num?)?.toDouble() ?? 0;

        final key = '$productCode-$tankType';
        if (!productMap.containsKey(key)) {
          productMap[key] = {
            'productCode': productCode,
            'productName': productName,
            'tankType': tankType,
            'totalIn': 0.0,
            'totalOut': 0.0,
            'balance': 0.0,
            'tankNumbers': <String>{},
          };
        }
        productMap[key]!['totalIn'] = (productMap[key]!['totalIn'] as double) + quantity;
      }

      // Process Stock Out
      for (final doc in stockOutSnapshot.docs) {
        final data = doc.data();
        final productCode = data['product_code'] ?? '';
        final tankType = data['tank_type'] ?? 'ไม่ระบุ';
        final quantity = (data['quantity'] as num?)?.toDouble() ?? 0;
        final tankNumber = data['tank_number'] ?? '';

        final key = '$productCode-$tankType';
        if (productMap.containsKey(key)) {
          productMap[key]!['totalOut'] = (productMap[key]!['totalOut'] as double) + quantity;
          if (tankNumber.isNotEmpty) {
            (productMap[key]!['tankNumbers'] as Set<String>).add(tankNumber);
          }
        }
      }

      // คำนวณยอดคงเหลือ
      for (final key in productMap.keys) {
        final data = productMap[key]!;
        data['balance'] = (data['totalIn'] as double) - (data['totalOut'] as double);
      }

      _stockMovements = productMap.values.toList()
        ..sort((a, b) => (b['balance'] as double).compareTo(a['balance'] as double));

      setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('สรุปสินค้าในถัง'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _stockMovements.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('ยังไม่มีข้อมูลการเคลื่อนไหว'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _stockMovements.length,
                  itemBuilder: (context, index) {
                    final item = _stockMovements[index];
                    final balance = item['balance'] as double;
                    final tankNumbers = (item['tankNumbers'] as Set<String>).join(', ');

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: balance > 0 ? Colors.green[100] : Colors.red[100],
                          child: Text(
                            item['productCode'][0].toUpperCase(),
                            style: TextStyle(
                              color: balance > 0 ? Colors.green[700] : Colors.red[700],
                            ),
                          ),
                        ),
                        title: Text(
                          item['productName'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ถัง: ${item['tankType']}'),
                            if (tankNumbers.isNotEmpty)
                              Text(
                                'เลขถัง: $tankNumbers',
                                style: const TextStyle(fontSize: 12),
                              ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${balance.toStringAsFixed(1)} KG',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: balance > 0 ? Colors.green : Colors.red,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'คงเหลือ',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    children: [
                                      Text(
                                        '${item['totalIn'].toStringAsFixed(1)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue,
                                          fontSize: 18,
                                        ),
                                      ),
                                      const Text('รับเข้า', style: TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Container(
                                  height: 40,
                                  width: 1,
                                  color: Colors.grey[300],
                                ),
                                Expanded(
                                  child: Column(
                                    children: [
                                      Text(
                                        '${item['totalOut'].toStringAsFixed(1)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange,
                                          fontSize: 18,
                                        ),
                                      ),
                                      const Text('เบิกออก', style: TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Container(
                                  height: 40,
                                  width: 1,
                                  color: Colors.grey[300],
                                ),
                                Expanded(
                                  child: Column(
                                    children: [
                                      Text(
                                        '${balance.toStringAsFixed(1)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: balance > 0 ? Colors.green : Colors.red,
                                          fontSize: 18,
                                        ),
                                      ),
                                      const Text('คงเหลือ', style: TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (tankNumbers.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Wrap(
                                  spacing: 8,
                                  children: tankNumbers.split(',').map((number) {
                                    return Chip(
                                      label: Text(number.trim()),
                                      backgroundColor: Colors.green[50],
                                      side: BorderSide(color: Colors.green[200]!),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadData,
        backgroundColor: Colors.green,
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }
}

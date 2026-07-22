import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/models/product_model.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final Product product;
  const ProductDetailScreen({Key? key, required this.product}) : super(key: key);

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  List<Map<String, dynamic>> _stockInHistory = [];
  List<Map<String, dynamic>> _stockOutHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);

    try {
      final factoryId = ref.read(currentFactoryIdProvider);
      if (factoryId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final firestore = FirebaseFirestore.instance;

      // ดึงประวัติการนำเข้า
      final inSnapshot = await firestore
          .collection('stock_in_entries')
          .where('factoryId', isEqualTo: factoryId)
          .where('product_id', isEqualTo: widget.product.id)
          .orderBy('date', descending: true)
          .get();

      _stockInHistory = inSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'date': data['date'] != null ? DateTime.parse(data['date']) : DateTime.now(),
          'supplier_name': data['supplier_name'] ?? '-',
          'quantity': (data['quantity'] as num?)?.toDouble() ?? 0,
          'tank_type': data['tank_type'] ?? '-',
          'note': data['note'] ?? '',
        };
      }).toList();

      // ดึงประวัติการเบิกออก
      final outSnapshot = await firestore
          .collection('stock_out_entries')
          .where('factoryId', isEqualTo: factoryId)
          .where('product_id', isEqualTo: widget.product.id)
          .orderBy('date', descending: true)
          .get();

      _stockOutHistory = outSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'date': data['date'] != null ? DateTime.parse(data['date']) : DateTime.now(),
          'purpose': data['purpose'] ?? '-',
          'quantity': (data['quantity'] as num?)?.toDouble() ?? 0,
          'tank_type': data['tank_type'] ?? '-',
          'tank_number': data['tank_number'] ?? '-',
          'note': data['note'] ?? '',
        };
      }).toList();

      setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading history: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.product.name}'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ข้อมูลสินค้า
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.green[50],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('รหัสสินค้า: ${widget.product.code}'),
                      Text(
                        'ยอดคงเหลือ: ${widget.product.stock.toStringAsFixed(1)} KG',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // ✅ Tab Bar - เหลือเพียง 2 แท็บ (นำเข้า และ เบิกออก)
                Expanded(
                  child: DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        TabBar(
                          labelColor: Colors.green[700],
                          unselectedLabelColor: Colors.grey,
                          tabs: const [
                            Tab(
                              icon: Icon(Icons.download),
                              text: 'นำเข้า',
                            ),
                            Tab(
                              icon: Icon(Icons.upload),
                              text: 'เบิกออก',
                            ),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              // แท็บนำเข้า
                              _buildStockInTab(),
                              // แท็บเบิกออก
                              _buildStockOutTab(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStockInTab() {
    if (_stockInHistory.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text('ยังไม่มีประวัติการนำเข้า'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _stockInHistory.length,
      itemBuilder: (context, index) {
        final item = _stockInHistory[index];
        final date = item['date'] as DateTime;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue[100],
              child: const Icon(Icons.download, color: Colors.blue),
            ),
            title: Text(
              '+${item['quantity'].toStringAsFixed(1)} KG',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ผู้ส่ง: ${item['supplier_name']}'),
                Text('ถัง: ${item['tank_type']}', 
                     style: const TextStyle(fontWeight: FontWeight.bold)),
                if (item['note'].isNotEmpty)
                  Text('หมายเหตุ: ${item['note']}', style: const TextStyle(fontSize: 12)),
              ],
            ),
            trailing: Text(
              DateFormat('dd/MM/yyyy').format(date),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStockOutTab() {
    if (_stockOutHistory.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text('ยังไม่มีประวัติการเบิกออก'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _stockOutHistory.length,
      itemBuilder: (context, index) {
        final item = _stockOutHistory[index];
        final date = item['date'] as DateTime;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.orange[100],
              child: const Icon(Icons.upload, color: Colors.orange),
            ),
            title: Text(
              '-${item['quantity'].toStringAsFixed(1)} KG',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('วัตถุประสงค์: ${item['purpose']}'),
                Text('ถัง: ${item['tank_type']}', 
                     style: const TextStyle(fontWeight: FontWeight.bold)),
                if (item['tank_number'] != '-')
                  Text('เลขถัง: ${item['tank_number']}'),
                if (item['note'].isNotEmpty)
                  Text('หมายเหตุ: ${item['note']}', style: const TextStyle(fontSize: 12)),
              ],
            ),
            trailing: Text(
              DateFormat('dd/MM/yyyy').format(date),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        );
      },
    );
  }
}

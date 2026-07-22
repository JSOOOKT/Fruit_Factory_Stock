import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/models/product_model.dart';

class ProductHistoryScreen extends ConsumerStatefulWidget {
  const ProductHistoryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProductHistoryScreen> createState() => _ProductHistoryScreenState();
}

class _ProductHistoryScreenState extends ConsumerState<ProductHistoryScreen> {
  List<Map<String, dynamic>> _productHistory = [];
  bool _isLoading = true;
  String? _selectedFilter;

  final List<String> _filters = ['ทั้งหมด', 'สร้าง', 'แก้ไข', 'ลบ'];

  @override
  void initState() {
    super.initState();
    _loadProductHistory();
  }

  Future<void> _loadProductHistory() async {
    setState(() => _isLoading = true);

    try {
      final factoryId = ref.read(currentFactoryIdProvider);
      if (factoryId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final firestore = FirebaseFirestore.instance;

      // ✅ ดึงประวัติจาก product_history collection
      final snapshot = await firestore
          .collection('product_history')
          .where('factoryId', isEqualTo: factoryId)
          .orderBy('timestamp', descending: true)
          .get();

      _productHistory = snapshot.docs.map((doc) {
        final data = doc.data();
        final timestamp = data['timestamp'] != null 
            ? (data['timestamp'] as Timestamp).toDate() 
            : DateTime.now();
        
        final action = data['action'] ?? 'unknown';
        IconData icon;
        Color color;
        String actionName;
        
        switch (action) {
          case 'create':
            icon = Icons.add_circle;
            color = Colors.green;
            actionName = 'สร้าง';
            break;
          case 'update':
            icon = Icons.edit;
            color = Colors.blue;
            actionName = 'แก้ไข';
            break;
          case 'delete':
            icon = Icons.delete;
            color = Colors.red;
            actionName = 'ลบ';
            break;
          default:
            icon = Icons.history;
            color = Colors.grey;
            actionName = 'อื่นๆ';
        }

        return {
          'id': doc.id,
          'product_id': data['product_id'] ?? '',
          'product_name': data['product_name'] ?? 'ไม่ระบุ',
          'product_code': data['product_code'] ?? '',
          'action': action,
          'action_name': actionName,
          'user': data['user'] ?? 'ระบบ',
          'timestamp': timestamp,
          'details': data['details'] ?? '',
          'old_data': data['old_data'],
          'new_data': data['new_data'],
          'deleted_data': data['deleted_data'],
          'icon': icon,
          'color': color,
        };
      }).toList();

      setState(() => _isLoading = false);
    } catch (e) {
      print('Error loading product history: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredHistory = _selectedFilter == null || _selectedFilter == 'ทั้งหมด'
        ? _productHistory
        : _productHistory.where((item) {
            final action = item['action_name'] as String;
            return action == _selectedFilter;
          }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('ประวัติสินค้า'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProductHistory,
          ),
        ],
      ),
      body: Column(
        children: [
          // ✅ Filter Dropdown
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Text('กรอง: '),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedFilter ?? 'ทั้งหมด',
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                    items: _filters.map((filter) {
                      return DropdownMenuItem(
                        value: filter,
                        child: Text(filter),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedFilter = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredHistory.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history, size: 48, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('ยังไม่มีประวัติสินค้า'),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredHistory.length,
                        itemBuilder: (context, index) {
                          final item = filteredHistory[index];
                          final timestamp = item['timestamp'] as DateTime;
                          final color = item['color'] as Color;
                          final icon = item['icon'] as IconData;
                          final actionName = item['action_name'] as String;
                          final details = item['details'] as String;
                          final productName = item['product_name'] as String;
                          final productCode = item['product_code'] as String;
                          final user = item['user'] as String;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: color.withOpacity(0.2),
                                child: Icon(icon, color: color),
                              ),
                              title: Text(
                                productName,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$actionName (${productCode})',
                                    style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    details,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  Text(
                                    'โดย: $user',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                  // ✅ แสดงข้อมูลเก่าและใหม่กรณีแก้ไข
                                  if (item['old_data'] != null && item['new_data'] != null)
                                    Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'เก่า: ${item['old_data']['old_name']} (${item['old_data']['old_code']})',
                                            style: const TextStyle(fontSize: 11, color: Colors.red),
                                          ),
                                          Text(
                                            'ใหม่: ${item['new_data']['new_name']} (${item['new_data']['new_code']})',
                                            style: const TextStyle(fontSize: 11, color: Colors.green),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              trailing: Text(
                                DateFormat('dd/MM/yyyy HH:mm').format(timestamp),
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'product_tank_summary_screen.dart';

class ReportScreen extends ConsumerWidget {
  const ReportScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รายงาน'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.inventory, color: Colors.green[700]),
              ),
              title: const Text(
                'สรุปสินค้าในถัง',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('ดูข้อมูลสินค้าและถังที่ใช้งาน'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => context.push('/reports/product-tank-summary'),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.history, color: Colors.blue[700]),
              ),
              title: const Text(
                'ประวัติการเคลื่อนไหว',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('ดูประวัติการรับเข้า-เบิกออกทั้งหมด'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => context.push('/stock-in/history'),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.assessment, color: Colors.orange[700]),
              ),
              title: const Text(
                'สรุปภาพรวม',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('ดูสรุปยอดรวมทั้งหมด'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => context.go('/'),
            ),
          ),
        ],
      ),
    );
  }
}

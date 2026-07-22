import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/language_provider.dart';

class SettingsMenuScreen extends ConsumerWidget {
  const SettingsMenuScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isThai = ref.watch(languageProvider) == 'th';

    return Scaffold(
      appBar: AppBar(
        title: Text(isThai ? 'ตั้งค่า' : 'Settings'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 👤 โปรไฟล์
          Card(
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.person, color: Colors.blue[700]),
              ),
              title: Text(
                isThai ? 'โปรไฟล์' : 'Profile',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                isThai 
                    ? 'แก้ไขชื่อผู้ใช้, รหัสผ่าน'
                    : 'Edit username, password',
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => context.push('/settings/profile'),
            ),
          ),
          const SizedBox(height: 12),
          
          // 🏭 โรงงาน
          Card(
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.factory, color: Colors.green[700]),
              ),
              title: Text(
                isThai ? 'จัดการโรงงาน' : 'Factory Management',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                isThai 
                    ? 'แก้ไขข้อมูลโรงงาน'
                    : 'Edit factory information',
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => context.push('/factory/select'),
            ),
          ),
          const SizedBox(height: 12),
          
          // 🛢️ ถังบรรจุ
          Card(
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.inventory, color: Colors.purple[700]),
              ),
              title: Text(
                isThai ? 'จัดการถังบรรจุ' : 'Tank Management',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                isThai 
                    ? 'เพิ่ม/ลบ ประเภทถัง'
                    : 'Add/Delete tank types',
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => context.push('/settings/tanks'),
            ),
          ),
          const SizedBox(height: 12),
          
          // 📝 วัตถุประสงค์
          Card(
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.info, color: Colors.orange[700]),
              ),
              title: Text(
                isThai ? 'จัดการวัตถุประสงค์' : 'Purpose Management',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                isThai 
                    ? 'เพิ่ม/ลบ วัตถุประสงค์การเบิกออก'
                    : 'Add/Delete stock out purposes',
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => context.push('/settings/purposes'),
            ),
          ),
          const SizedBox(height: 12),
          
          // 📋 รายงานปัญหา
          Card(
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.report_problem, color: Colors.red[700]),
              ),
              title: Text(
                isThai ? 'รายงานปัญหา' : 'Report Issue',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                isThai 
                    ? 'แจ้งปัญหาหรือข้อเสนอแนะ'
                    : 'Report issues or suggestions',
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => context.push('/settings/report-issue'),
            ),
          ),
        ],
      ),
    );
  }
}

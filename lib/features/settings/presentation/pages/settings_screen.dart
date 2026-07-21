import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../factory/presentation/providers/factory_providers.dart';
import '../../../factory/data/repositories/factory_repository.dart';
import '../../../factory/presentation/pages/edit_factory_screen.dart';
import '../providers/language_provider.dart';
import 'tank_settings_screen.dart';
import 'report_issue_screen.dart';
import 'purpose_settings_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _nameController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userData = await ref.read(currentUserDataProvider.future);
    if (userData != null) {
      _nameController.text = userData['name'] ?? '';
      _userRole = userData['role'] ?? 'recorder';
    }
  }

  void _goToSwitchFactory() {
    context.push('/factory/select');
  }

  void _goToEditFactory() {
    final factory = ref.read(currentFactoryProvider).valueOrNull;
    if (factory != null) {
      context.push('/factory/edit', extra: factory);
    }
  }

  void _goToTankSettings() {
    context.push('/settings/tanks');
  }

  void _goToPurposeSettings() {
    context.push('/settings/purposes');
  }

  void _goToReportIssue() {
    context.push('/settings/report-issue');
  }

  Future<void> _updateProfile() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกชื่อ'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);
    await ref.read(authStateProvider.notifier).updateProfile(
      _nameController.text,
      ref.read(languageProvider),
    );
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ อัปเดตโปรไฟล์สำเร็จ'), backgroundColor: Colors.green),
    );
  }

  Future<void> _changePassword() async {
    if (_currentPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบ'), backgroundColor: Colors.orange),
      );
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('รหัสผ่านใหม่ไม่ตรงกัน'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);
    final success = await ref.read(authStateProvider.notifier).changePassword(
      _currentPasswordController.text,
      _newPasswordController.text,
    );
    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ เปลี่ยนรหัสผ่านสำเร็จ'), backgroundColor: Colors.green),
      );
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ เปลี่ยนรหัสผ่านล้มเหลว'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ ลบบัญชีผู้ใช้'),
        content: const Text(
          'คุณแน่ใจหรือไม่ที่จะลบบัญชีนี้?\n'
          'ข้อมูลทั้งหมดจะถูกลบอย่างถาวรและไม่สามารถกู้คืนได้',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('ลบบัญชี'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      final user = ref.read(currentUserProvider);
      if (user != null) {
        final repository = FactoryRepository();
        await repository.deleteUserAccount(user.uid);
        await user.delete();
        await ref.read(authStateProvider.notifier).signOut();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ ลบบัญชีสำเร็จ'),
              backgroundColor: Colors.green,
            ),
          );
          context.go('/login');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ลบบัญชีล้มเหลว: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLang = ref.watch(languageProvider);
    final isThai = currentLang == 'th';
    final currentFactory = ref.watch(currentFactoryProvider);
    
    final canEditFactory = _userRole == 'manager' || _userRole == 'admin';

    return Scaffold(
      appBar: AppBar(
        title: Text(isThai ? 'ตั้งค่า' : 'Settings'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // โรงงานปัจจุบัน
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isThai ? '🏭 โรงงานปัจจุบัน' : 'Current Factory',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    currentFactory.when(
                      data: (factory) {
                        if (factory == null) {
                          return const Text('ยังไม่ได้เลือกโรงงาน');
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              factory.name,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text('รหัส: ${factory.factoryCode}'),
                            Text('ที่อยู่: ${factory.address}'),
                            Text('เบอร์โทร: ${factory.phone}'),
                            
                            if (canEditFactory) ...[
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                height: 40,
                                child: OutlinedButton.icon(
                                  onPressed: _goToEditFactory,
                                  icon: const Icon(Icons.edit, size: 18),
                                  label: Text(isThai ? 'แก้ไขข้อมูลโรงงาน' : 'Edit Factory'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.green,
                                    side: const BorderSide(color: Colors.green),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (_, __) => const Text('ไม่สามารถโหลดข้อมูลโรงงาน'),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      isThai ? '🔄 สลับโรงงาน' : 'Switch Factory',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isThai 
                          ? 'กดเพื่อเลือกโรงงานอื่นและกรอกรหัสผ่านใหม่'
                          : 'Tap to select another factory and enter password',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton.icon(
                        onPressed: _goToSwitchFactory,
                        icon: const Icon(Icons.swap_horiz),
                        label: Text(isThai ? 'ไปที่หน้าเลือกโรงงาน' : 'Go to Select Factory'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Tank Management
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isThai ? '🛢️ จัดการถังบรรจุ' : 'Tank Management',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isThai 
                          ? 'เพิ่ม แก้ไข หรือลบ ประเภทถังและเลขถัง'
                          : 'Add, edit, or delete tank types and numbers',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton.icon(
                        onPressed: _goToTankSettings,
                        icon: const Icon(Icons.inventory),
                        label: Text(isThai ? 'จัดการถังบรรจุ' : 'Manage Tanks'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Purpose Management
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isThai ? '📝 จัดการวัตถุประสงค์' : 'Purpose Management',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isThai 
                          ? 'เพิ่ม หรือลบ วัตถุประสงค์สำหรับการเบิกออก'
                          : 'Add or delete purposes for stock out',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton.icon(
                        onPressed: _goToPurposeSettings,
                        icon: const Icon(Icons.info),
                        label: Text(isThai ? 'จัดการวัตถุประสงค์' : 'Manage Purposes'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Report Issue
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isThai ? '📋 รายงานปัญหา' : 'Report Issue',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isThai 
                          ? 'แจ้งปัญหาหรือข้อเสนอแนะถึงผู้ดูแลระบบ'
                          : 'Report issues or suggestions to the administrator',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton.icon(
                        onPressed: _goToReportIssue,
                        icon: const Icon(Icons.report_problem),
                        label: Text(isThai ? 'รายงานปัญหา' : 'Report Issue'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Language Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isThai ? '🌐 ภาษา' : 'Language',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildLanguageButton(
                            'ไทย',
                            'th',
                            currentLang == 'th',
                            onTap: () => _changeLanguage('th'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildLanguageButton(
                            'English',
                            'en',
                            currentLang == 'en',
                            onTap: () => _changeLanguage('en'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Profile Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isThai ? '👤 โปรไฟล์' : 'Profile',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: isThai ? 'ชื่อผู้ใช้' : 'Username',
                        prefixIcon: const Icon(Icons.person),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updateProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(isThai ? 'อัปเดตโปรไฟล์' : 'Update Profile'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Change Password Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isThai ? '🔑 เปลี่ยนรหัสผ่าน' : 'Change Password',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _currentPasswordController,
                      decoration: InputDecoration(
                        labelText: isThai ? 'รหัสผ่านปัจจุบัน' : 'Current Password',
                        prefixIcon: const Icon(Icons.lock),
                        border: const OutlineInputBorder(),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _newPasswordController,
                      decoration: InputDecoration(
                        labelText: isThai ? 'รหัสผ่านใหม่' : 'New Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _confirmPasswordController,
                      decoration: InputDecoration(
                        labelText: isThai ? 'ยืนยันรหัสผ่านใหม่' : 'Confirm New Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _changePassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(isThai ? 'เปลี่ยนรหัสผ่าน' : 'Change Password'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Delete Account Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isThai ? '🗑️ ลบบัญชี' : 'Delete Account',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isThai 
                          ? 'การลบบัญชีจะลบข้อมูลทั้งหมดของคุณอย่างถาวร'
                          : 'Deleting your account will permanently remove all your data',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _deleteAccount,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(isThai ? 'ลบบัญชี' : 'Delete Account'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Logout Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : () async {
                  setState(() => _isLoading = true);
                  await ref.read(authStateProvider.notifier).signOut();
                  if (mounted) {
                    context.go('/login');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[800],
                  foregroundColor: Colors.white,
                ),
                child: Text(isThai ? '🚪 ออกจากระบบ' : 'Logout'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageButton(String label, String code, bool isSelected, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[800],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  void _changeLanguage(String lang) async {
    await ref.read(languageProvider.notifier).setLanguage(lang);
  }
}

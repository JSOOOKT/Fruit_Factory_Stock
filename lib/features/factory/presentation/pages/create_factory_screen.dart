import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/factory_providers.dart';

class CreateFactoryScreen extends ConsumerStatefulWidget {
  const CreateFactoryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CreateFactoryScreen> createState() => _CreateFactoryScreenState();
}

class _CreateFactoryScreenState extends ConsumerState<CreateFactoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _createFactory() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('รหัสผ่านไม่ตรงกัน กรุณากรอกใหม่'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final user = ref.read(currentUserProvider);
    
    // ถ้ายังไม่ login ให้ไปหน้า login ก่อน
    if (user == null) {
      setState(() => _isLoading = false);
      
      // บันทึกข้อมูลที่จะใช้หลังจาก login
      // ใช้ shared_preferences หรือส่งผ่าน state
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาเข้าสู่ระบบก่อนสร้างโรงงาน'),
          backgroundColor: Colors.orange,
        ),
      );
      context.go('/login');
      return;
    }

    try {
      final repository = ref.read(factoryRepositoryProvider);
      
      final factory = await repository.createFactory(
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        phone: _phoneController.text.trim(),
        adminId: user.uid,
        password: _passwordController.text,
        description: null,
      );

      // เข้าสู่โรงงานโดยอัตโนมัติ
      await ref.read(authStateProvider.notifier).updateFactoryId(factory.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 สร้างโรงงาน "${factory.name}" สำเร็จ!'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('สร้างโรงงานใหม่'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/factory/select'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // ไอคอน
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.factory,
                    size: 60,
                    color: Colors.green[700],
                  ),
                ),
                const SizedBox(height: 16),
                
                Text(
                  'สำหรับผู้ดูแลที่ต้องการเริ่มบัญชีของโรงงานใหม่',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // ชื่อโรงงาน
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'ชื่อโรงงาน',
                    prefixIcon: Icon(Icons.business),
                    border: OutlineInputBorder(),
                    hintText: 'เช่น โรงงานขนม',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'กรุณากรอกชื่อโรงงาน';
                    }
                    if (value.length < 2) {
                      return 'ชื่อโรงงานต้องมีอย่างน้อย 2 ตัวอักษร';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ที่อยู่
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'ที่อยู่',
                    prefixIcon: Icon(Icons.location_on),
                    border: OutlineInputBorder(),
                    hintText: 'เช่น 123 ถนนสุขุมวิท แขวงคลองเตย',
                  ),
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'กรุณากรอกที่อยู่';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // เบอร์โทรศัพท์
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'เบอร์โทรศัพท์',
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
                    hintText: 'เช่น 081-234-5678',
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'กรุณากรอกเบอร์โทรศัพท์';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ตั้งรหัสผ่านโรงงาน
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'ตั้งรหัสผ่านโรงงาน',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                    ),
                    border: const OutlineInputBorder(),
                    hintText: 'รหัสผ่านสำหรับเข้าถึงโรงงานนี้',
                  ),
                  obscureText: !_isPasswordVisible,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'กรุณาตั้งรหัสผ่านโรงงาน';
                    }
                    if (value.length < 4) {
                      return 'รหัสผ่านต้องมีอย่างน้อย 4 ตัวอักษร';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ยืนยันรหัสผ่าน
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'ยืนยันรหัสผ่าน',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'กรุณายืนยันรหัสผ่าน';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // ปุ่มสร้างโรงงาน
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _createFactory,
                    icon: const Icon(Icons.add_business),
                    label: Text(
                      _isLoading ? 'กำลังสร้าง...' : 'สร้างโรงงาน',
                      style: const TextStyle(fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ปุ่มยกเลิก
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('ยกเลิก'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

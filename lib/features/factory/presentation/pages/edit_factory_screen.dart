import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/factory_providers.dart';
import '../../domain/entities/factory.dart';

class EditFactoryScreen extends ConsumerStatefulWidget {
  final Factory factory;
  const EditFactoryScreen({Key? key, required this.factory}) : super(key: key);

  @override
  ConsumerState<EditFactoryScreen> createState() => _EditFactoryScreenState();
}

class _EditFactoryScreenState extends ConsumerState<EditFactoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.factory.name;
    _addressController.text = widget.factory.address;
    _phoneController.text = widget.factory.phone;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _updateFactory() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณากรอกรหัสผ่านโรงงานเพื่อยืนยัน'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('กรุณาเข้าสู่ระบบก่อน'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final repository = ref.read(factoryRepositoryProvider);
      
      // ตรวจสอบรหัสผ่านก่อนแก้ไข
      final isValid = await repository.verifyFactoryPassword(
        widget.factory.id,
        _passwordController.text,
      );

      if (!isValid) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ รหัสผ่านไม่ถูกต้อง'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // อัปเดตข้อมูล
      final updatedFactory = widget.factory.copyWith(
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        phone: _phoneController.text.trim(),
        updatedAt: DateTime.now(),
      );

      await repository.updateFactory(updatedFactory);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ อัปเดตข้อมูลโรงงานสำเร็จ!'),
            backgroundColor: Colors.green,
          ),
        );
        ref.refresh(currentFactoryProvider);
        ref.refresh(allFactoriesProvider);
        context.pop();
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
        title: const Text('แก้ไขข้อมูลโรงงาน'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
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
                  'แก้ไขข้อมูลโรงงาน',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'กรอกรหัสผ่านโรงงานเพื่อยืนยันการแก้ไข',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'ชื่อโรงงาน',
                    prefixIcon: Icon(Icons.business),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'กรุณากรอกชื่อโรงงาน';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'ที่อยู่',
                    prefixIcon: Icon(Icons.location_on),
                    border: OutlineInputBorder(),
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

                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'เบอร์โทรศัพท์',
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'กรุณากรอกเบอร์โทรศัพท์';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                const Divider(),
                const SizedBox(height: 16),

                Text(
                  'ยืนยันด้วยรหัสผ่านโรงงาน',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),

                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'รหัสผ่านโรงงาน',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                    ),
                    border: const OutlineInputBorder(),
                    hintText: 'กรอกรหัสผ่านเพื่อยืนยัน',
                  ),
                  obscureText: !_isPasswordVisible,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'กรุณากรอกรหัสผ่านเพื่อยืนยัน';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _updateFactory,
                    icon: const Icon(Icons.save),
                    label: Text(
                      _isLoading ? 'กำลังบันทึก...' : 'บันทึกการเปลี่ยนแปลง',
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

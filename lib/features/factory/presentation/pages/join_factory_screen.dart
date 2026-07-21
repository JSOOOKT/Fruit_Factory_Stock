// lib/features/factory/presentation/pages/join_factory_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/factory_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class JoinFactoryScreen extends ConsumerStatefulWidget {
  const JoinFactoryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<JoinFactoryScreen> createState() => _JoinFactoryScreenState();
}

class _JoinFactoryScreenState extends ConsumerState<JoinFactoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _joinFactory() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final user = ref.read(currentUserProvider);
    if (user == null) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเข้าสู่ระบบก่อน'), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      final repository = ref.read(factoryRepositoryProvider);
      await repository.joinFactory(
        _codeController.text.trim().toUpperCase(),
        user.uid,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('เข้าร่วมโรงงานสำเร็จ!'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ไม่พบโรงงาน: ${_codeController.text}'),
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
        title: const Text('เข้าร่วมโรงงาน'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.business, size: 64, color: Colors.green),
              const SizedBox(height: 16),
              Text(
                'เข้าร่วมโรงงานที่มีอยู่',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'กรุณากรอกรหัสโรงงานจากผู้ดูแลระบบ',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 32),

              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'รหัสโรงงาน',
                  prefixIcon: Icon(Icons.qr_code),
                  border: OutlineInputBorder(),
                  hintText: 'เช่น F2024ABC123',
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'กรุณากรอกรหัสโรงงาน';
                  }
                  if (value.length < 6) {
                    return 'รหัสโรงงานต้องมีอย่างน้อย 6 ตัวอักษร';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _joinFactory,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('เข้าร่วมโรงงาน'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
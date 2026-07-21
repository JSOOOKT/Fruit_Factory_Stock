import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/factory_providers.dart';

class FactorySelectScreen extends ConsumerStatefulWidget {
  const FactorySelectScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<FactorySelectScreen> createState() => _FactorySelectScreenState();
}

class _FactorySelectScreenState extends ConsumerState<FactorySelectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  String? _selectedFactoryId;
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _selectFactory() async {
    if (!_formKey.currentState!.validate()) return;

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
        context.go('/login');
        return;
      }

      final factoryRepo = ref.read(factoryRepositoryProvider);
      final success = await factoryRepo.joinFactoryWithPassword(
        _selectedFactoryId!,
        _passwordController.text,
        user.uid,
      );

      if (success) {
        await ref.read(authStateProvider.notifier).updateFactoryId(_selectedFactoryId!);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ เข้าสู่โรงงานสำเร็จ!'),
              backgroundColor: Colors.green,
            ),
          );
          context.go('/');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ รหัสผ่านโรงงานไม่ถูกต้อง'),
              backgroundColor: Colors.red,
            ),
          );
        }
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
    final factoriesAsync = ref.watch(allFactoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('เข้าสู่โรงงาน'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () => context.push('/factory/create'),
            child: const Text(
              'สร้างโรงงานใหม่',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: factoriesAsync.when(
          data: (factories) {
            if (factories.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.factory, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    const Text(
                      'ยังไม่มีโรงงาน',
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'กรุณาสร้างโรงงานใหม่เพื่อเริ่มใช้งาน',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => context.push('/factory/create'),
                      icon: const Icon(Icons.add_business),
                      label: const Text('สร้างโรงงานใหม่'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: const Text('กลับ'),
                    ),
                  ],
                ),
              );
            }

            return Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
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
                    'กรอกชื่อโรงงานและรหัสผ่านเพื่อเข้าถึงข้อมูล',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // ✅ แสดงรายการโรงงานทั้งหมด
                  DropdownButtonFormField<String>(
                    value: _selectedFactoryId,
                    decoration: const InputDecoration(
                      labelText: 'ชื่อโรงงาน',
                      prefixIcon: Icon(Icons.business),
                      border: OutlineInputBorder(),
                      hintText: 'เลือกโรงงานที่ต้องการเข้า',
                    ),
                    items: factories.map((factory) {
                      return DropdownMenuItem(
                        value: factory.id,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              factory.name,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'รหัส: ${factory.factoryCode}',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedFactoryId = value;
                        _passwordController.clear();
                      });
                    },
                    validator: (value) => value == null ? 'กรุณาเลือกโรงงาน' : null,
                  ),
                  const SizedBox(height: 16),

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
                      hintText: 'กรอกรหัสผ่านของโรงงาน',
                    ),
                    obscureText: !_isPasswordVisible,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'กรุณากรอกรหัสผ่านโรงงาน';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _selectFactory,
                      icon: const Icon(Icons.login),
                      label: Text(
                        _isLoading ? 'กำลังเข้าสู่ระบบ...' : 'เข้าสู่โรงงาน',
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

                  TextButton.icon(
                    onPressed: () async {
                      await ref.read(authStateProvider.notifier).signOut();
                      if (mounted) {
                        context.go('/login');
                      }
                    },
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('ออกจากระบบ'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red[400],
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
                const SizedBox(height: 16),
                Text('เกิดข้อผิดพลาด: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.refresh(allFactoriesProvider),
                  child: const Text('ลองใหม่'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

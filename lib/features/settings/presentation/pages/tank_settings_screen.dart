import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../tanks/presentation/providers/tank_providers.dart';
import '../providers/language_provider.dart';

class TankSettingsScreen extends ConsumerStatefulWidget {
  const TankSettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<TankSettingsScreen> createState() => _TankSettingsScreenState();
}

class _TankSettingsScreenState extends ConsumerState<TankSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tankTypeController = TextEditingController();
  final _tankNumberController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _tankTypeController.dispose();
    _tankNumberController.dispose();
    super.dispose();
  }

  Future<void> _addTank() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final factoryId = ref.read(currentFactoryIdProvider);
    if (factoryId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final repository = ref.read(tankRepositoryProvider);
      await repository.addTank(
        factoryId: factoryId,
        tankType: _tankTypeController.text.trim(),
        tankNumber: _tankNumberController.text.isNotEmpty 
            ? _tankNumberController.text.trim() 
            : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ เพิ่มถังสำเร็จ'), backgroundColor: Colors.green),
        );
        _tankTypeController.clear();
        _tankNumberController.clear();
        ref.refresh(tankListProvider);
        ref.refresh(tankListStreamProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tanksAsync = ref.watch(tankListProvider);
    final isThai = ref.watch(languageProvider) == 'th';

    return Scaffold(
      appBar: AppBar(
        title: Text(isThai ? 'จัดการถังบรรจุ' : 'Tank Management'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Add Tank Form
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isThai ? 'เพิ่มถังใหม่' : 'Add New Tank',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _tankTypeController,
                        decoration: const InputDecoration(
                          labelText: 'ประเภทถัง',
                          prefixIcon: Icon(Icons.inventory),
                          border: OutlineInputBorder(),
                          hintText: 'เช่น ฝาแดง, ฝา 2 สี, ฝาขาวแดง',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'กรุณากรอกประเภทถัง';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _tankNumberController,
                        decoration: const InputDecoration(
                          labelText: 'เลขถัง (ไม่บังคับ)',
                          prefixIcon: Icon(Icons.numbers),
                          border: OutlineInputBorder(),
                          hintText: 'เช่น T-001',
                        ),
                      ),
                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        height: 45,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _addTank,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(isThai ? 'เพิ่มถัง' : 'Add Tank'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Tank List
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isThai ? 'รายการถังทั้งหมด' : 'All Tanks',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: tanksAsync.when(
                      data: (tanks) {
                        if (tanks.isEmpty) {
                          return Center(
                            child: Text(isThai ? 'ยังไม่มีถัง กรุณาเพิ่มถังแรก' : 'No tanks yet'),
                          );
                        }
                        return ListView.builder(
                          itemCount: tanks.length,
                          itemBuilder: (context, index) {
                            final tank = tanks[index];
                            return Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.green[100],
                                  child: Text(tank.tankType[0]),
                                ),
                                title: Text(tank.tankType),
                                subtitle: tank.tankNumber != null
                                    ? Text('เลขถัง: ${tank.tankNumber}')
                                    : null,
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: () => _confirmDeleteTank(tank.id),
                                ),
                              ),
                            );
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (error, _) => Center(child: Text('Error: $error')),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteTank(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ลบถัง'),
        content: const Text('คุณต้องการลบถังนี้ใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final repository = ref.read(tankRepositoryProvider);
              await repository.deleteTank(id);
              ref.refresh(tankListProvider);
              ref.refresh(tankListStreamProvider);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ ลบถังสำเร็จ'), backgroundColor: Colors.green),
                );
              }
            },
            child: const Text('ลบ', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

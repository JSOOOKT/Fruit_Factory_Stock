import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
  bool _isLoading = false;

  @override
  void dispose() {
    _tankTypeController.dispose();
    super.dispose();
  }

  Future<void> _addTankType() async {
    if (_tankTypeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณากรอกประเภทถัง'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

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
        tankNumber: null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ เพิ่มประเภทถังสำเร็จ'), backgroundColor: Colors.green),
        );
        _tankTypeController.clear();
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

  Future<void> _deleteTankType(String id, String type) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ลบประเภทถัง'),
        content: Text('คุณต้องการลบประเภทถัง "$type" ใช่หรือไม่?'),
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
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(tankRepositoryProvider);
      await repository.deleteTank(id);

      ref.refresh(tankListProvider);
      ref.refresh(tankListStreamProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ ลบประเภทถังสำเร็จ'), backgroundColor: Colors.green),
        );
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
    final tanksAsync = ref.watch(tankListStreamProvider);
    final isThai = ref.watch(languageProvider) == 'th';

    return Scaffold(
      appBar: AppBar(
        title: Text(isThai ? 'จัดการประเภทถัง' : 'Tank Type Management'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isThai ? 'เพิ่มประเภทถังใหม่' : 'Add New Tank Type',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _tankTypeController,
                              decoration: const InputDecoration(
                                labelText: 'ประเภทถัง',
                                border: OutlineInputBorder(),
                                hintText: 'เช่น ฝาแดง, ฝาฟ้า',
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'กรุณากรอกประเภทถัง';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _addTankType,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(80, 56),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(isThai ? 'เพิ่ม' : 'Add'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isThai ? 'รายการประเภทถังทั้งหมด' : 'All Tank Types',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: tanksAsync.when(
                      data: (tanks) {
                        final types = tanks.where((t) => t.tankNumber == null).toList();
                        if (types.isEmpty) {
                          return Center(
                            child: Text(isThai ? 'ยังไม่มีประเภทถัง' : 'No tank types yet'),
                          );
                        }
                        return ListView.builder(
                          itemCount: types.length,
                          itemBuilder: (context, index) {
                            final tank = types[index];
                            return Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.green[100],
                                  child: Text(tank.tankType[0].toUpperCase()),
                                ),
                                title: Text(tank.tankType),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: () => _deleteTankType(tank.id, tank.tankType),
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
}

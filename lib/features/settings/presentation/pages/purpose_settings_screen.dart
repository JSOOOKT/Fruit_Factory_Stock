import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../stock_out/presentation/providers/purpose_providers.dart';
import '../providers/language_provider.dart';

class PurposeSettingsScreen extends ConsumerStatefulWidget {
  const PurposeSettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PurposeSettingsScreen> createState() => _PurposeSettingsScreenState();
}

class _PurposeSettingsScreenState extends ConsumerState<PurposeSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _purposeController = TextEditingController();
  bool _isLoading = false;

  Future<void> _addPurpose() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final factoryId = ref.read(currentFactoryIdProvider);
    if (factoryId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final purposeService = ref.read(purposeServiceProvider);
      await purposeService.savePurpose(
        factoryId,
        _purposeController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ เพิ่มวัตถุประสงค์สำเร็จ'), backgroundColor: Colors.green),
        );
        _purposeController.clear();
        // ✅ Refresh ทั้ง Future และ Stream
        ref.refresh(purposeHistoryProvider);
        ref.refresh(purposeHistoryStreamProvider);
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

  Future<void> _deletePurpose(String purpose) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ลบวัตถุประสงค์'),
        content: Text('คุณต้องการลบวัตถุประสงค์ "$purpose" ใช่หรือไม่?'),
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
      final factoryId = ref.read(currentFactoryIdProvider);
      if (factoryId == null) return;

      final purposeService = ref.read(purposeServiceProvider);
      await purposeService.deletePurpose(factoryId, purpose);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ ลบวัตถุประสงค์สำเร็จ'), backgroundColor: Colors.green),
        );
        ref.refresh(purposeHistoryProvider);
        ref.refresh(purposeHistoryStreamProvider);
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
    // ✅ ใช้ Stream เพื่ออัปเดตแบบ Real-time
    final purposesAsync = ref.watch(purposeHistoryStreamProvider);
    final isThai = ref.watch(languageProvider) == 'th';

    return Scaffold(
      appBar: AppBar(
        title: Text(isThai ? 'จัดการวัตถุประสงค์' : 'Purpose Management'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Add Purpose Form
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isThai ? 'เพิ่มวัตถุประสงค์ใหม่' : 'Add New Purpose',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _purposeController,
                        decoration: const InputDecoration(
                          labelText: 'วัตถุประสงค์',
                          prefixIcon: Icon(Icons.info),
                          border: OutlineInputBorder(),
                          hintText: 'เช่น ผลิต, สูญเสีย, ตัวอย่าง',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'กรุณากรอกวัตถุประสงค์';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        height: 45,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _addPurpose,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(isThai ? 'เพิ่มวัตถุประสงค์' : 'Add Purpose'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Purpose List
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isThai ? 'รายการวัตถุประสงค์ทั้งหมด' : 'All Purposes',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: purposesAsync.when(
                      data: (purposes) {
                        if (purposes.isEmpty) {
                          return Center(
                            child: Text(isThai ? 'ยังไม่มีวัตถุประสงค์' : 'No purposes yet'),
                          );
                        }
                        return ListView.builder(
                          itemCount: purposes.length,
                          itemBuilder: (context, index) {
                            final purpose = purposes[index];
                            return Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue[100],
                                  child: Text(purpose[0].toUpperCase()),
                                ),
                                title: Text(purpose),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: () => _deletePurpose(purpose),
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

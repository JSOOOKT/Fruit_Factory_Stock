// lib/features/stock/domain/services/purpose_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class PurposeService {
  final FirebaseFirestore _firestore;

  PurposeService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<List<String>> getPurposeHistory(String factoryId) async {
    final snapshot = await _firestore
        .collection('stock_out_entries')
        .where('factoryId', isEqualTo: factoryId)
        .orderBy('created_at', descending: true)
        .limit(50)
        .get();

    final purposes = <String>{};
    for (final doc in snapshot.docs) {
      final purpose = doc.data()['purpose'] as String?;
      if (purpose != null && purpose.isNotEmpty) {
        purposes.add(purpose);
      }
    }

    return purposes.toList();
  }

  Future<void> savePurpose(String factoryId, String purpose) async {
    // บันทึก purpose เพื่อใช้ในอนาคต
    await _firestore.collection('purpose_history').add({
      'factoryId': factoryId,
      'purpose': purpose,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<String>> watchPurposeHistory(String factoryId) {
    return _firestore
        .collection('stock_out_entries')
        .where('factoryId', isEqualTo: factoryId)
        .orderBy('created_at', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          final purposes = <String>{};
          for (final doc in snapshot.docs) {
            final purpose = doc.data()['purpose'] as String?;
            if (purpose != null && purpose.isNotEmpty) {
              purposes.add(purpose);
            }
          }
          return purposes.toList();
        });
  }
}
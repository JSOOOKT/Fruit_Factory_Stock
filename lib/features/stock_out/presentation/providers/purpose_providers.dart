import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class PurposeService {
  final FirebaseFirestore _firestore;

  PurposeService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<List<String>> getPurposeHistory(String factoryId) async {
    if (factoryId.isEmpty) return [];

    final snapshot = await _firestore
        .collection('purpose_history')
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
    if (factoryId.isEmpty || purpose.isEmpty) return;

    await _firestore.collection('purpose_history').add({
      'factoryId': factoryId,
      'purpose': purpose.trim(),
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deletePurpose(String factoryId, String purpose) async {
    if (factoryId.isEmpty || purpose.isEmpty) return;

    final snapshot = await _firestore
        .collection('purpose_history')
        .where('factoryId', isEqualTo: factoryId)
        .where('purpose', isEqualTo: purpose)
        .get();

    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  Stream<List<String>> watchPurposeHistory(String factoryId) {
    if (factoryId.isEmpty) {
      return Stream.value([]);
    }

    return _firestore
        .collection('purpose_history')
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

final purposeServiceProvider = Provider<PurposeService>((ref) {
  return PurposeService();
});

final purposeHistoryProvider = FutureProvider<List<String>>((ref) async {
  final factoryId = ref.watch(currentFactoryIdProvider);
  final service = ref.watch(purposeServiceProvider);
  if (factoryId == null) return [];
  return await service.getPurposeHistory(factoryId);
});

final purposeHistoryStreamProvider = StreamProvider<List<String>>((ref) {
  final factoryId = ref.watch(currentFactoryIdProvider);
  final service = ref.watch(purposeServiceProvider);
  if (factoryId == null) return Stream.value([]);
  return service.watchPurposeHistory(factoryId);
});

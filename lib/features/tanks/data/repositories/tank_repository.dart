import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/tank.dart';

class TankRepository {
  final FirebaseFirestore _firestore;

  TankRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<List<Tank>> getTanksByFactory(String factoryId) async {
    final snapshot = await _firestore
        .collection('tanks')
        .where('factoryId', isEqualTo: factoryId)
        .where('isActive', isEqualTo: true)
        .get();

    final tanks = snapshot.docs
        .map((doc) => Tank.fromJson(doc.data()))
        .toList();
    
    tanks.sort((a, b) => a.tankType.compareTo(b.tankType));
    return tanks;
  }

  Future<Tank> addTank({
    required String factoryId,
    required String tankType,
    String? tankNumber,
  }) async {
    final id = const Uuid().v4();
    final now = DateTime.now();

    final tank = Tank(
      id: id,
      factoryId: factoryId,
      tankType: tankType,
      tankNumber: tankNumber,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );

    await _firestore.collection('tanks').doc(id).set(tank.toJson());
    return tank;
  }

  Future<void> updateTank(Tank tank) async {
    final updatedTank = tank.copyWith(updatedAt: DateTime.now());
    await _firestore.collection('tanks').doc(tank.id).update(updatedTank.toJson());
  }

  Future<void> deleteTank(String id) async {
    await _firestore.collection('tanks').doc(id).update({
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Tank>> watchTanks(String factoryId) {
    return _firestore
        .collection('tanks')
        .where('factoryId', isEqualTo: factoryId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Tank.fromJson(doc.data()))
            .toList());
  }
}

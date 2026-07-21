import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/factory.dart';

class FactoryRepository {
  final FirebaseFirestore _firestore;

  FactoryRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<Factory> createFactory({
    required String name,
    required String address,
    required String phone,
    required String adminId,
    required String password,
    String? description,
  }) async {
    final id = const Uuid().v4();
    final now = DateTime.now();
    final factoryCode = 'F${now.year}${now.month.toString().padLeft(2, '0')}${id.substring(0, 6).toUpperCase()}';

    final factory = Factory(
      id: id,
      factoryCode: factoryCode,
      name: name,
      address: address,
      phone: phone,
      adminId: adminId,
      isActive: true,
      password: password,
      createdAt: now,
      updatedAt: now,
      description: description,
    );

    await _firestore.collection('factories').doc(id).set(factory.toJson());
    
    await _firestore.collection('users').doc(adminId).update({
      'factoryId': id,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return factory;
  }

  Future<Factory?> getFactory(String id) async {
    final doc = await _firestore.collection('factories').doc(id).get();
    if (!doc.exists) return null;
    return Factory.fromJson(doc.data()!);
  }

  Future<Factory?> getFactoryByCode(String code) async {
    final snapshot = await _firestore
        .collection('factories')
        .where('factoryCode', isEqualTo: code)
        .limit(1)
        .get();
    
    if (snapshot.docs.isEmpty) return null;
    return Factory.fromJson(snapshot.docs.first.data());
  }

  Future<List<Factory>> getAllFactories() async {
    final snapshot = await _firestore
        .collection('factories')
        .where('isActive', isEqualTo: true)
        .get();
    
    final factories = snapshot.docs
        .map((doc) => Factory.fromJson(doc.data()))
        .toList();
    
    factories.sort((a, b) => a.name.compareTo(b.name));
    return factories;
  }

  Future<bool> joinFactoryWithPassword(String factoryId, String password, String userId) async {
    final factory = await getFactory(factoryId);
    if (factory == null) return false;

    if (factory.password != password) return false;

    await _firestore.collection('users').doc(userId).update({
      'factoryId': factory.id,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return true;
  }

  Future<bool> verifyFactoryPassword(String factoryId, String password) async {
    final factory = await getFactory(factoryId);
    if (factory == null) return false;
    return factory.password == password;
  }

  Future<void> updateFactory(Factory factory) async {
    final updatedFactory = factory.copyWith(updatedAt: DateTime.now());
    await _firestore.collection('factories').doc(factory.id).update(
      updatedFactory.toJson(),
    );
  }

  Future<void> switchFactory(String factoryId, String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'factoryId': factoryId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteFactory(String factoryId) async {
    await _firestore.collection('factories').doc(factoryId).update({
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteUserAccount(String userId) async {
    await _firestore.collection('users').doc(userId).delete();
  }

  Stream<Factory?> watchFactory(String id) {
    return _firestore
        .collection('factories')
        .doc(id)
        .snapshots()
        .map((doc) => doc.exists ? Factory.fromJson(doc.data()!) : null);
  }
}

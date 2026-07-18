import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Centralized Firebase service for all database operations
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  
  late final FirebaseFirestore _firestore;
  late final FirebaseAuth _auth;

  factory FirebaseService() => _instance;

  FirebaseService._internal() {
    _firestore = FirebaseFirestore.instance;
    _auth = FirebaseAuth.instance;
  }

  // Collections
  static const String productsCollection = 'products';
  static const String stockInCollection = 'stock_in_entries';
  static const String stockOutCollection = 'stock_out_entries';
  static const String usersCollection = 'users';
  static const String shiftsCollection = 'shift_schedules';

  // Getters
  FirebaseFirestore get firestore => _firestore;
  FirebaseAuth get auth => _auth;

  // Auth Methods
  Future<UserCredential> signUp(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  User? getCurrentUser() => _auth.currentUser;

  // Product Methods
  Future<void> addProduct({
    required String productCode,
    required String nameTh,
    required String nameEn,
    required String unit,
  }) async {
    await _firestore.collection(productsCollection).doc(productCode).set({
      'product_code': productCode,
      'name_th': nameTh,
      'name_en': nameEn,
      'unit': unit,
      'active': true,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getProducts() {
    return _firestore
        .collection(productsCollection)
        .where('active', isEqualTo: true)
        .snapshots();
  }

  // Stock In Methods
  Future<void> addStockInEntry({
    required String id,
    required DateTime dateReceived,
    required String senderName,
    required String productCode,
    required double quantityKg,
    required String recordedBy,
    required String shift,
    String? note,
  }) async {
    await _firestore.collection(stockInCollection).doc(id).set({
      'id': id,
      'date_received': Timestamp.fromDate(dateReceived),
      'sender_name': senderName,
      'product_code': productCode,
      'quantity_kg': quantityKg,
      'recorded_by': recordedBy,
      'shift': shift,
      'note': note,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getStockInEntries({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    Query query = _firestore.collection(stockInCollection);

    if (startDate != null) {
      query = query.where(
        'date_received',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
      );
    }

    if (endDate != null) {
      query = query.where(
        'date_received',
        isLessThanOrEqualTo: Timestamp.fromDate(endDate),
      );
    }

    return query.snapshots();
  }

  // Stock Out Methods
  Future<void> addStockOutEntry({
    required String id,
    required DateTime dateIssued,
    required String productCode,
    required double quantityKg,
    required String recordedBy,
    String? purpose,
  }) async {
    await _firestore.collection(stockOutCollection).doc(id).set({
      'id': id,
      'date_issued': Timestamp.fromDate(dateIssued),
      'product_code': productCode,
      'quantity_kg': quantityKg,
      'recorded_by': recordedBy,
      'purpose': purpose,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getStockOutEntries({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    Query query = _firestore.collection(stockOutCollection);

    if (startDate != null) {
      query = query.where(
        'date_issued',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
      );
    }

    if (endDate != null) {
      query = query.where(
        'date_issued',
        isLessThanOrEqualTo: Timestamp.fromDate(endDate),
      );
    }

    return query.snapshots();
  }

  // Batch Operations
  Future<void> batch({
    required Future<void> Function(WriteBatch) operation,
  }) async {
    WriteBatch batch = _firestore.batch();
    await operation(batch);
    await batch.commit();
  }

  // Transaction Support
  Future<T> transaction<T>({
    required Future<T> Function(Transaction) operation,
  }) async {
    return await _firestore.runTransaction(operation);
  }
}

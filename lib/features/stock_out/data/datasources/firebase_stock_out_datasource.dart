// lib/features/stock_out/data/datasources/firebase_stock_out_datasource.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/error/failure.dart';
import '../models/stock_out_request.dart';
import 'stock_out_datasource.dart';

class FirebaseStockOutDataSource implements StockOutDataSource {
  final FirebaseFirestore _firestore;

  FirebaseStockOutDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<StockOutEntry> createStockOutEntry(
    StockOutRequest request,
    String userId,
  ) async {
    try {
      // Verify stock availability first
      final isAvailable = await verifyStockAvailability(
        request.productCode,
        request.quantityKg,
      );
      
      if (!isAvailable) {
        throw ValidationFailure(
          message: 'Insufficient stock for product: ${request.productCode}',
        );
      }

      final id = const Uuid().v4();
      final now = DateTime.now();

      final entry = StockOutEntry(
        id: id,
        dateIssued: DateTime.parse(request.dateIssued),
        productCode: request.productCode,
        quantityKg: request.quantityKg,
        recordedBy: userId,
        purpose: request.purpose,
        note: request.note,
        createdAt: now,
        updatedAt: now,
      );

      await _firestore
          .collection('stock_out_entries')
          .doc(id)
          .set(entry.toJson());

      return entry;
    } on FirebaseException catch (e) {
      throw _mapFirebaseException(e);
    } catch (e) {
      throw UnknownFailure(message: e.toString());
    }
  }

  @override
  Future<StockOutEntry> getStockOutEntry(String id) async {
    try {
      final doc = await _firestore
          .collection('stock_out_entries')
          .doc(id)
          .get();

      if (!doc.exists) {
        throw NotFoundFailure(message: 'Stock out entry not found');
      }

      return StockOutEntry.fromJson(doc.data()!);
    } on FirebaseException catch (e) {
      throw _mapFirebaseException(e);
    } catch (e) {
      throw UnknownFailure(message: e.toString());
    }
  }

  @override
  Future<List<StockOutEntry>> getStockOutEntriesByProduct(
    String productCode,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('stock_out_entries')
          .where('product_code', isEqualTo: productCode)
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => StockOutEntry.fromJson(doc.data()))
          .toList();
    } on FirebaseException catch (e) {
      throw _mapFirebaseException(e);
    } catch (e) {
      throw UnknownFailure(message: e.toString());
    }
  }

  @override
  Future<List<StockOutEntry>> getStockOutEntriesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('stock_out_entries')
          .where('date_issued',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date_issued',
              isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('date_issued', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => StockOutEntry.fromJson(doc.data()))
          .toList();
    } on FirebaseException catch (e) {
      throw _mapFirebaseException(e);
    } catch (e) {
      throw UnknownFailure(message: e.toString());
    }
  }

  @override
  Stream<List<StockOutEntry>> watchStockOutEntries() {
    return _firestore
        .collection('stock_out_entries')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => StockOutEntry.fromJson(doc.data()))
              .toList(),
        );
  }

  @override
  Future<List<StockOutEntry>> getRecentStockOutEntries(int limit) async {
    try {
      final snapshot = await _firestore
          .collection('stock_out_entries')
          .orderBy('created_at', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => StockOutEntry.fromJson(doc.data()))
          .toList();
    } on FirebaseException catch (e) {
      throw _mapFirebaseException(e);
    } catch (e) {
      throw UnknownFailure(message: e.toString());
    }
  }

  @override
  Future<bool> verifyStockAvailability(
    String productCode,
    double quantityToWithdraw,
  ) async {
    try {
      // Get total stock in
      final inSnapshot = await _firestore
          .collection('stock_in_entries')
          .where('product_code', isEqualTo: productCode)
          .get();

      final totalIn = inSnapshot.docs.fold<double>(
        0.0,
        (sum, doc) => sum + (doc['quantity_kg'] as num).toDouble(),
      );

      // Get total stock out
      final outSnapshot = await _firestore
          .collection('stock_out_entries')
          .where('product_code', isEqualTo: productCode)
          .get();

      final totalOut = outSnapshot.docs.fold<double>(
        0.0,
        (sum, doc) => sum + (doc['quantity_kg'] as num).toDouble(),
      );

      final remaining = totalIn - totalOut;
      return remaining >= quantityToWithdraw;
    } on FirebaseException catch (e) {
      throw _mapFirebaseException(e);
    } catch (e) {
      throw UnknownFailure(message: e.toString());
    }
  }

  Failure _mapFirebaseException(FirebaseException e) {
    return FirebaseFailure(
      code: e.code,
      message: e.message ?? 'Firebase error occurred',
    );
  }
}
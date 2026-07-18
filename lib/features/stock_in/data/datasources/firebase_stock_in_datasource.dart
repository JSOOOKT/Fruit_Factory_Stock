import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/error/failure.dart';
import '../models/stock_in_request.dart';
import '../models/stock_in_response.dart';
import 'stock_in_datasource.dart';

class FirebaseStockInDataSource implements StockInDataSource {
  final FirebaseFirestore _firestore;

  FirebaseStockInDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<StockInEntry> createStockInEntry(
    StockInRequest request,
    String userId,
  ) async {
    try {
      final id = const Uuid().v4();
      final now = DateTime.now();

      final entry = StockInEntry(
        id: id,
        dateReceived: request.dateReceived,
        senderName: request.senderName,
        productCode: request.productCode,
        quantityKg: request.quantityKg,
        recordedBy: userId,
        shift: request.shift,
        note: request.note,
        createdAt: now,
        updatedAt: now,
      );

      await _firestore
          .collection('stock_in_entries')
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
  Future<StockInEntry> getStockInEntry(String id) async {
    try {
      final doc = await _firestore.collection('stock_in_entries').doc(id).get();

      if (!doc.exists) {
        throw NotFoundFailure(message: 'Stock in entry not found');
      }

      return StockInEntry.fromJson(doc.data() as Map<String, dynamic>);
    } on FirebaseException catch (e) {
      throw _mapFirebaseException(e);
    } catch (e) {
      throw UnknownFailure(message: e.toString());
    }
  }

  @override
  Future<List<StockInEntry>> getStockInEntriesByProduct(
    String productCode,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('stock_in_entries')
          .where('product_code', isEqualTo: productCode)
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => StockInEntry.fromJson(doc.data()))
          .toList();
    } on FirebaseException catch (e) {
      throw _mapFirebaseException(e);
    } catch (e) {
      throw UnknownFailure(message: e.toString());
    }
  }

  @override
  Future<List<StockInEntry>> getStockInEntriesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('stock_in_entries')
          .where('date_received',
              isGreaterThanOrEqualTo: startDate.toIso8601String())
          .where('date_received', isLessThanOrEqualTo: endDate.toIso8601String())
          .orderBy('date_received', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => StockInEntry.fromJson(doc.data()))
          .toList();
    } on FirebaseException catch (e) {
      throw _mapFirebaseException(e);
    } catch (e) {
      throw UnknownFailure(message: e.toString());
    }
  }

  @override
  Future<List<StockInEntry>> getStockInEntriesBySender(String senderName) async {
    try {
      final snapshot = await _firestore
          .collection('stock_in_entries')
          .where('sender_name', isEqualTo: senderName)
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => StockInEntry.fromJson(doc.data()))
          .toList();
    } on FirebaseException catch (e) {
      throw _mapFirebaseException(e);
    } catch (e) {
      throw UnknownFailure(message: e.toString());
    }
  }

  @override
  Stream<List<StockInEntry>> watchStockInEntries() {
    return _firestore
        .collection('stock_in_entries')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => StockInEntry.fromJson(doc.data()))
              .toList(),
        );
  }

  @override
  Future<List<StockInEntry>> getRecentStockInEntries(int limit) async {
    try {
      final snapshot = await _firestore
          .collection('stock_in_entries')
          .orderBy('created_at', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => StockInEntry.fromJson(doc.data()))
          .toList();
    } on FirebaseException catch (e) {
      throw _mapFirebaseException(e);
    } catch (e) {
      throw UnknownFailure(message: e.toString());
    }
  }

  @override
  Future<StockBalance> getStockBalance(String productCode) async {
    try {
      // Get all stock in for this product
      final inSnapshot = await _firestore
          .collection('stock_in_entries')
          .where('product_code', isEqualTo: productCode)
          .get();

      final totalIn = inSnapshot.docs.fold<double>(
        0.0,
        (sum, doc) => sum + (doc['quantity_kg'] as num).toDouble(),
      );

      // Get all stock out for this product (assuming stock_out_entries collection exists)
      QuerySnapshot outSnapshot;
      try {
        outSnapshot = await _firestore
            .collection('stock_out_entries')
            .where('product_code', isEqualTo: productCode)
            .get();
      } catch (e) {
        // stock_out_entries might not exist yet
        outSnapshot = await _firestore
            .collection('stock_out_entries')
            .limit(0)
            .get();
      }

      final totalOut = outSnapshot.docs.fold<double>(
        0.0,
        (sum, doc) => sum + (doc['quantity_kg'] as num).toDouble(),
      );

      final remaining = totalIn - totalOut;

      return StockBalance(
        productCode: productCode,
        totalIn: totalIn,
        totalOut: totalOut,
        remaining: remaining,
      );
    } on FirebaseException catch (e) {
      throw _mapFirebaseException(e);
    } catch (e) {
      throw UnknownFailure(message: e.toString());
    }
  }

  @override
  Future<bool> verifyStockBalance(
    String productCode,
    double quantityToWithdraw,
  ) async {
    try {
      final balance = await getStockBalance(productCode);
      return balance.remaining >= quantityToWithdraw;
    } on FirebaseException catch (e) {
      throw _mapFirebaseException(e);
    } catch (e) {
      throw UnknownFailure(message: e.toString());
    }
  }

  /// Map Firebase exceptions to custom failures
  Failure _mapFirebaseException(FirebaseException e) {
    return FirebaseFailure(
      code: e.code,
      message: e.message ?? 'Firebase error occurred',
    );
  }
}

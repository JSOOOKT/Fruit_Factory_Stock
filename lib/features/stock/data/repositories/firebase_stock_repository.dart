// lib/features/stock/data/repositories/firebase_stock_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/stock_entry.dart';

class FirebaseStockRepository {
  final FirebaseFirestore _firestore;

  FirebaseStockRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<Result<Failure, StockEntry>> processStockOut({
    required String productCode,
    required double quantityKg,
    required String purpose,
    required String recordedBy,
    String? note,
  }) async {
    try {
      // Validate inputs
      if (quantityKg <= 0) {
        return Result.failure(
          ValidationFailure(message: 'Quantity must be greater than 0'),
        );
      }
      if (purpose.isEmpty) {
        return Result.failure(
          ValidationFailure(message: 'Purpose is required'),
        );
      }

      // Use transaction for atomic operation
      final result = await _firestore.runTransaction((transaction) async {
        final now = DateTime.now();
        final id = const Uuid().v4();

        // Get product and check stock
        final productRef = _firestore
            .collection('products')
            .doc(productCode);
        
        final productDoc = await transaction.get(productRef);
        if (!productDoc.exists) {
          throw NotFoundFailure(message: 'Product not found: $productCode');
        }

        final currentStock = (productDoc.data()?['stock'] as num?)?.toDouble() ?? 0;
        if (currentStock < quantityKg) {
          throw ValidationFailure(
            message: 'Insufficient stock. Available: ${currentStock.toStringAsFixed(1)} KG',
            fieldErrors: {'quantity': 'Exceeds available stock'},
          );
        }

        // Create stock out entry
        final stockOut = StockEntry.stockOut(
          id: id,
          productCode: productCode,
          quantityKg: quantityKg,
          date: now,
          recordedBy: recordedBy,
          purpose: purpose,
          note: note,
          createdAt: now,
          updatedAt: now,
        );

        // Save stock out entry
        final entryRef = _firestore
            .collection('stock_out_entries')
            .doc(id);
        transaction.set(entryRef, _toJson(stockOut));

        // Update product stock
        transaction.update(productRef, {
          'stock': currentStock - quantityKg,
          'updated_at': FieldValue.serverTimestamp(),
        });

        return stockOut;
      });

      return Result.success(result);
      
    } on FirebaseException catch (e) {
      return Result.failure(FirebaseFailure(e.message ?? 'Transaction failed', e.code));
    } on Failure catch (e) {
      return Result.failure(e);
    } catch (e) {
      return Result.failure(UnknownFailure(e.toString()));
    }
  }

  Map<String, dynamic> _toJson(StockEntry entry) {
    return entry.map(
      stockIn: (e) => {
        'id': e.id,
        'product_code': e.productCode,
        'quantity_kg': e.quantityKg,
        'date': e.date.toIso8601String(),
        'recorded_by': e.recordedBy,
        'sender_name': e.senderName,
        'shift': e.shift,
        'note': e.note,
        'created_at': e.createdAt.toIso8601String(),
        'updated_at': e.updatedAt.toIso8601String(),
        'edited_by': e.editedBy,
        'edited_at': e.editedAt?.toIso8601String(),
      },
      stockOut: (e) => {
        'id': e.id,
        'product_code': e.productCode,
        'quantity_kg': e.quantityKg,
        'date': e.date.toIso8601String(),
        'recorded_by': e.recordedBy,
        'purpose': e.purpose,
        'note': e.note,
        'created_at': e.createdAt.toIso8601String(),
        'updated_at': e.updatedAt.toIso8601String(),
        'edited_by': e.editedBy,
        'edited_at': e.editedAt?.toIso8601String(),
      },
    );
  }
}

// Simple Result class
sealed class Result<T> {
  const Result();

  factory Result.success(T data) = Success;
  factory Result.failure(Failure error) = FailureResult;
}

final class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

final class FailureResult<T> extends Result<T> {
  final Failure error;
  const FailureResult(this.error);
}
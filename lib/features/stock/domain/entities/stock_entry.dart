// lib/features/stock/domain/entities/stock_entry.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'stock_entry.freezed.dart';

@freezed
sealed class StockEntry with _$StockEntry {
  const StockEntry._();

  const factory StockEntry.stockIn({
    required String id,
    required String productCode,
    required double quantityKg,
    required DateTime date,
    required String recordedBy,
    required String senderName,
    required String shift,
    String? note,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? editedBy,
    DateTime? editedAt,
  }) = StockIn;

  const factory StockEntry.stockOut({
    required String id,
    required String productCode,
    required double quantityKg,
    required DateTime date,
    required String recordedBy,
    required String purpose,
    String? note,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? editedBy,
    DateTime? editedAt,
  }) = StockOut;

  String get id => map(
    stockIn: (e) => e.id,
    stockOut: (e) => e.id,
  );

  String get productCode => map(
    stockIn: (e) => e.productCode,
    stockOut: (e) => e.productCode,
  );

  double get quantityKg => map(
    stockIn: (e) => e.quantityKg,
    stockOut: (e) => e.quantityKg,
  );

  DateTime get date => map(
    stockIn: (e) => e.date,
    stockOut: (e) => e.date,
  );

  String get recordedBy => map(
    stockIn: (e) => e.recordedBy,
    stockOut: (e) => e.recordedBy,
  );

  String? get note => map(
    stockIn: (e) => e.note,
    stockOut: (e) => e.note,
  );

  bool get isStockIn => this is StockIn;
  bool get isStockOut => this is StockOut;
}
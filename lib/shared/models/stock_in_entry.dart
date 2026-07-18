import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

part 'stock_in_entry.freezed.dart';
part 'stock_in_entry.g.dart';

@freezed
class StockInEntry with _$StockInEntry {
  const StockInEntry._();

  const factory StockInEntry({
    required String id,
    required DateTime dateReceived,
    required String senderName,
    required String productCode,
    required String productType,
    required double quantityKg,
    required String recordedBy,
    required String shift,
    String? note,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? editedBy,
    DateTime? editedAt,
  }) = _StockInEntry;

  factory StockInEntry.fromJson(Map<String, dynamic> json) =>
      _$StockInEntryFromJson(json);

  bool get isDraft => false; // Can extend with draft status
}

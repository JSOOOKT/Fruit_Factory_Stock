import 'package:freezed_annotation/freezed_annotation.dart';

part 'stock_out_entry.freezed.dart';
part 'stock_out_entry.g.dart';

@freezed
class StockOutEntry with _$StockOutEntry {
  const StockOutEntry._();

  const factory StockOutEntry({
    required String id,
    required DateTime dateIssued,
    required String productCode,
    required String productType,
    required double quantityKg,
    required String recordedBy,
    String? purpose,
    String? note,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? editedBy,
    DateTime? editedAt,
  }) = _StockOutEntry;

  factory StockOutEntry.fromJson(Map<String, dynamic> json) =>
      _$StockOutEntryFromJson(json);
}

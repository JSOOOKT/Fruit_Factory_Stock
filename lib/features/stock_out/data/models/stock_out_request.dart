// lib/features/stock_out/data/models/stock_out_request.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'stock_out_request.freezed.dart';
part 'stock_out_request.g.dart';

@freezed
class StockOutRequest with _$StockOutRequest {
  const factory StockOutRequest({
    required String dateIssued,
    required String productCode,
    required double quantityKg,
    required String purpose,
    String? note,
  }) = _StockOutRequest;

  factory StockOutRequest.fromJson(Map<String, dynamic> json) =>
      _$StockOutRequestFromJson(json);
}

@freezed
class StockOutEntry with _$StockOutEntry {
  const factory StockOutEntry({
    required String id,
    required DateTime dateIssued,
    required String productCode,
    required double quantityKg,
    required String recordedBy,
    required String purpose,
    String? note,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? editedBy,
    DateTime? editedAt,
  }) = _StockOutEntry;

  factory StockOutEntry.fromJson(Map<String, dynamic> json) =>
      _$StockOutEntryFromJson(json);
}
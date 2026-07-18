import 'package:freezed_annotation/freezed_annotation.dart';

part 'stock_in_response.freezed.dart';
part 'stock_in_response.g.dart';

@freezed
class StockInEntry with _$StockInEntry {
  const factory StockInEntry({
    required String id,
    required String dateReceived,
    required String senderName,
    required String productCode,
    required double quantityKg,
    required String recordedBy,
    required String shift,
    String? note,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _StockInEntry;

  factory StockInEntry.fromJson(Map<String, dynamic> json) =>
      _$StockInEntryFromJson(json);
}

@freezed
class StockInResponse with _$StockInResponse {
  const factory StockInResponse({
    required String id,
    required StockInEntry entry,
    required DateTime timestamp,
  }) = _StockInResponse;

  factory StockInResponse.fromJson(Map<String, dynamic> json) =>
      _$StockInResponseFromJson(json);
}

@freezed
class StockBalance with _$StockBalance {
  const factory StockBalance({
    required String productCode,
    required double totalIn,
    required double totalOut,
    required double remaining,
  }) = _StockBalance;

  factory StockBalance.fromJson(Map<String, dynamic> json) =>
      _$StockBalanceFromJson(json);
}

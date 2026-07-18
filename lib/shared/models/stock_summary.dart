import 'package:freezed_annotation/freezed_annotation.dart';

part 'stock_summary.freezed.dart';
part 'stock_summary.g.dart';

@freezed
class StockSummary with _$StockSummary {
  const StockSummary._();

  const factory StockSummary({
    required String productCode,
    required String productType,
    required String unit, // 'KG'
    required double totalIn,
    required double totalOut,
    required double balance,
    required DateTime lastUpdated,
  }) = _StockSummary;

  factory StockSummary.fromJson(Map<String, dynamic> json) =>
      _$StockSummaryFromJson(json);

  bool get isLowStock => balance < 100.0; // Can be customizable
}

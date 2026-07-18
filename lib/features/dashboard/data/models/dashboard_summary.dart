// lib/features/dashboard/data/models/dashboard_summary.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'dashboard_summary.freezed.dart';
part 'dashboard_summary.g.dart';

@freezed
class DashboardSummary with _$DashboardSummary {
  const factory DashboardSummary({
    required double totalStockIn,
    required double totalStockOut,
    required double totalBalance,
    required int totalProducts,
    required int totalEntries,
    required List<ProductSummary> productSummaries,
    required List<DailySummary> dailySummaries,
    required DateTime lastUpdated,
  }) = _DashboardSummary;

  factory DashboardSummary.fromJson(Map<String, dynamic> json) =>
      _$DashboardSummaryFromJson(json);
}

@freezed
class ProductSummary with _$ProductSummary {
  const factory ProductSummary({
    required String productCode,
    required String productName,
    required double totalIn,
    required double totalOut,
    required double balance,
    required String unit,
    required DateTime lastUpdated,
  }) = _ProductSummary;

  factory ProductSummary.fromJson(Map<String, dynamic> json) =>
      _$ProductSummaryFromJson(json);
}

@freezed
class DailySummary with _$DailySummary {
  const factory DailySummary({
    required DateTime date,
    required double totalIn,
    required double totalOut,
    required double balance,
  }) = _DailySummary;

  factory DailySummary.fromJson(Map<String, dynamic> json) =>
      _$DailySummaryFromJson(json);
}

@freezed
class LowStockAlert with _$LowStockAlert {
  const factory LowStockAlert({
    required String productCode,
    required String productName,
    required double currentBalance,
    required double threshold,
    required String unit,
    required bool isCritical,
  }) = _LowStockAlert;

  factory LowStockAlert.fromJson(Map<String, dynamic> json) =>
      _$LowStockAlertFromJson(json);
}
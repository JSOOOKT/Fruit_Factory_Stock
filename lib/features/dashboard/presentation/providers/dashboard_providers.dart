// lib/features/dashboard/presentation/providers/dashboard_providers.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/dashboard_service.dart';
import '../../data/models/dashboard_summary.dart';

// Service provider
final dashboardServiceProvider = Provider<DashboardService>((ref) {
  return DashboardService();
});

// Dashboard summary provider with filter
final dashboardSummaryProvider =
    FutureProvider.family<DashboardSummary, DateFilter>((ref, filter) async {
  final service = ref.watch(dashboardServiceProvider);
  return await service.getDashboardSummary(
    startDate: filter.startDate,
    endDate: filter.endDate,
  );
});

// Low stock alerts provider
final lowStockAlertsProvider =
    FutureProvider.family<List<LowStockAlert>, double>((ref, threshold) async {
  final service = ref.watch(dashboardServiceProvider);
  return await service.getLowStockAlerts(threshold: threshold);
});

// CSV export provider
final csvReportProvider = FutureProvider.family<String, DateFilter>((ref, filter) async {
  final service = ref.watch(dashboardServiceProvider);
  return await service.generateCSVReport(
    startDate: filter.startDate,
    endDate: filter.endDate,
  );
});

// Date filter state
class DateFilter {
  final DateTime? startDate;
  final DateTime? endDate;

  const DateFilter({this.startDate, this.endDate});

  bool get hasFilter => startDate != null || endDate != null;

  DateFilter copyWith({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return DateFilter(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}

// Date filter notifier
class DateFilterNotifier extends StateNotifier<DateFilter> {
  DateFilterNotifier() : super(const DateFilter());

  void updateStartDate(DateTime? date) {
    state = state.copyWith(startDate: date);
  }

  void updateEndDate(DateTime? date) {
    state = state.copyWith(endDate: date);
  }

  void clearFilter() {
    state = const DateFilter();
  }
}

final dateFilterProvider =
    StateNotifierProvider<DateFilterNotifier, DateFilter>((ref) {
  return DateFilterNotifier();
});

// Chart data models
class ChartData {
  final String label;
  final double value;
  final Color color;

  ChartData({required this.label, required this.value, required this.color});
}

// Chart data provider
final stockChartDataProvider = Provider<List<ChartData>>((ref) {
  final summary = ref.watch(dashboardSummaryProvider(
    ref.watch(dateFilterProvider),
  ));
  
  return summary.when(
    data: (data) {
      return data.productSummaries
          .take(10)
          .map((product) => ChartData(
                label: product.productCode,
                value: product.balance,
                color: _getColorForIndex(
                  data.productSummaries.indexOf(product),
                ),
              ))
          .toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

Color _getColorForIndex(int index) {
  const colors = [
    Color(0xFF4CAF50),
    Color(0xFF2196F3),
    Color(0xFFFF9800),
    Color(0xFFE91E63),
    Color(0xFF9C27B0),
    Color(0xFF00BCD4),
    Color(0xFFFF5722),
    Color(0xFF795548),
    Color(0xFF607D8B),
    Color(0xFF8BC34A),
  ];
  return colors[index % colors.length];
}
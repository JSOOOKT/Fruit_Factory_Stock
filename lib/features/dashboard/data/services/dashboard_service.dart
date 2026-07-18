// lib/features/dashboard/data/services/dashboard_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';

import '../models/dashboard_summary.dart';
import '../../../../shared/models/product_type.dart';

class DashboardService {
  final FirebaseFirestore _firestore;

  DashboardService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get complete dashboard summary
  Future<DashboardSummary> getDashboardSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Get all products
      final productsSnapshot = await _firestore
          .collection('products')
          .where('active', isEqualTo: true)
          .get();

      final products = productsSnapshot.docs
          .map((doc) => ProductType.fromJson(doc.data()))
          .toList();

      // Get stock in entries
      final inQuery = _firestore.collection('stock_in_entries');
      var inSnapshot = await inQuery.get();
      
      if (startDate != null && endDate != null) {
        inSnapshot = await inQuery
            .where('created_at', isGreaterThanOrEqualTo: startDate)
            .where('created_at', isLessThanOrEqualTo: endDate)
            .get();
      }

      final inEntries = inSnapshot.docs.map((doc) => doc.data()).toList();

      // Get stock out entries
      final outQuery = _firestore.collection('stock_out_entries');
      var outSnapshot = await outQuery.get();
      
      if (startDate != null && endDate != null) {
        outSnapshot = await outQuery
            .where('created_at', isGreaterThanOrEqualTo: startDate)
            .where('created_at', isLessThanOrEqualTo: endDate)
            .get();
      }

      final outEntries = outSnapshot.docs.map((doc) => doc.data()).toList();

      // Calculate summaries
      final productSummaries = _calculateProductSummaries(
        products,
        inEntries,
        outEntries,
      );

      final dailySummaries = _calculateDailySummaries(
        inEntries,
        outEntries,
        startDate,
        endDate,
      );

      // Calculate totals
      final totalIn = inEntries.fold<double>(
        0.0,
        (sum, doc) => sum + (doc['quantity_kg'] as num).toDouble(),
      );

      final totalOut = outEntries.fold<double>(
        0.0,
        (sum, doc) => sum + (doc['quantity_kg'] as num).toDouble(),
      );

      final totalBalance = totalIn - totalOut;

      return DashboardSummary(
        totalStockIn: totalIn,
        totalStockOut: totalOut,
        totalBalance: totalBalance,
        totalProducts: products.length,
        totalEntries: inEntries.length + outEntries.length,
        productSummaries: productSummaries,
        dailySummaries: dailySummaries,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Failed to load dashboard: $e');
    }
  }

  /// Calculate product-wise summaries
  List<ProductSummary> _calculateProductSummaries(
    List<ProductType> products,
    List<Map<String, dynamic>> inEntries,
    List<Map<String, dynamic>> outEntries,
  ) {
    final summaries = <ProductSummary>[];

    for (final product in products) {
      final productIn = inEntries
          .where((doc) => doc['product_code'] == product.productCode)
          .fold<double>(
            0.0,
            (sum, doc) => sum + (doc['quantity_kg'] as num).toDouble(),
          );

      final productOut = outEntries
          .where((doc) => doc['product_code'] == product.productCode)
          .fold<double>(
            0.0,
            (sum, doc) => sum + (doc['quantity_kg'] as num).toDouble(),
          );

      summaries.add(
        ProductSummary(
          productCode: product.productCode,
          productName: product.nameTh,
          totalIn: productIn,
          totalOut: productOut,
          balance: productIn - productOut,
          unit: product.unit,
          lastUpdated: DateTime.now(),
        ),
      );
    }

    // Sort by balance descending
    summaries.sort((a, b) => b.balance.compareTo(a.balance));
    return summaries;
  }

  /// Calculate daily summaries
  List<DailySummary> _calculateDailySummaries(
    List<Map<String, dynamic>> inEntries,
    List<Map<String, dynamic>> outEntries,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    // Group entries by date
    final dailyMap = <String, DailySummary>{};

    // Process stock in
    for (final entry in inEntries) {
      final date = (entry['created_at'] as Timestamp).toDate();
      final dateKey = '${date.year}-${date.month}-${date.day}';
      final quantity = (entry['quantity_kg'] as num).toDouble();

      final summary = dailyMap[dateKey] ?? DailySummary(
            date: date,
            totalIn: 0,
            totalOut: 0,
            balance: 0,
          );
      
      dailyMap[dateKey] = summary.copyWith(
        totalIn: summary.totalIn + quantity,
        totalOut: summary.totalOut,
        balance: summary.totalIn + quantity - summary.totalOut,
      );
    }

    // Process stock out
    for (final entry in outEntries) {
      final date = (entry['created_at'] as Timestamp).toDate();
      final dateKey = '${date.year}-${date.month}-${date.day}';
      final quantity = (entry['quantity_kg'] as num).toDouble();

      final summary = dailyMap[dateKey] ?? DailySummary(
            date: date,
            totalIn: 0,
            totalOut: 0,
            balance: 0,
          );
      
      dailyMap[dateKey] = summary.copyWith(
        totalIn: summary.totalIn,
        totalOut: summary.totalOut + quantity,
        balance: summary.totalIn - (summary.totalOut + quantity),
      );
    }

    // Convert to list and sort by date
    var dailyList = dailyMap.values.toList();
    dailyList.sort((a, b) => a.date.compareTo(b.date));

    // Filter by date range
    if (startDate != null && endDate != null) {
      dailyList = dailyList
          .where((d) => d.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
              d.date.isBefore(endDate.add(const Duration(days: 1))))
          .toList();
    }

    // Calculate running balance
    var runningBalance = 0.0;
    for (var i = 0; i < dailyList.length; i++) {
      runningBalance += dailyList[i].totalIn - dailyList[i].totalOut;
      dailyList[i] = dailyList[i].copyWith(balance: runningBalance);
    }

    return dailyList;
  }

  /// Get low stock alerts
  Future<List<LowStockAlert>> getLowStockAlerts({
    double threshold = 100.0,
  }) async {
    try {
      final summary = await getDashboardSummary();
      final alerts = <LowStockAlert>[];

      for (final product in summary.productSummaries) {
        if (product.balance <= threshold) {
          alerts.add(
            LowStockAlert(
              productCode: product.productCode,
              productName: product.productName,
              currentBalance: product.balance,
              threshold: threshold,
              unit: product.unit,
              isCritical: product.balance <= threshold / 2,
            ),
          );
        }
      }

      alerts.sort((a, b) => a.currentBalance.compareTo(b.currentBalance));
      return alerts;
    } catch (e) {
      throw Exception('Failed to get low stock alerts: $e');
    }
  }

  /// Generate CSV data for export
  Future<String> generateCSVReport({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final summary = await getDashboardSummary(
      startDate: startDate,
      endDate: endDate,
    );

    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('Product Code,Product Name,Total In (KG),Total Out (KG),Balance (KG),Unit');
    
    // Data rows
    for (final product in summary.productSummaries) {
      buffer.writeln(
        '${product.productCode},${product.productName},'
        '${product.totalIn.toStringAsFixed(2)},'
        '${product.totalOut.toStringAsFixed(2)},'
        '${product.balance.toStringAsFixed(2)},'
        '${product.unit}',
      );
    }

    // Summary row
    buffer.writeln('');
    buffer.writeln(
      'TOTAL,,${summary.totalStockIn.toStringAsFixed(2)},'
      '${summary.totalStockOut.toStringAsFixed(2)},'
      '${summary.totalBalance.toStringAsFixed(2)},KG',
    );
    buffer.writeln('Last Updated: ${DateTime.now().toIso8601String()}');

    return buffer.toString();
  }
}
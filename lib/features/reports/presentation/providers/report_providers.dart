// lib/features/reports/presentation/providers/report_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/report_model.dart';

final reportSummaryProvider = FutureProvider<ReportSummary>((ref) async {
  // Get products
  final productsSnapshot = await FirebaseFirestore.instance
      .collection('products')
      .get();

  final products = productsSnapshot.docs.map((doc) {
    final data = doc.data();
    return {
      'id': doc.id,
      'name': data['name'] ?? '',
      'code': data['code'] ?? '',
      'stock': data['stock'] ?? 0,
      'unit': data['unit'] ?? 'KG',
    };
  }).toList();

  // Get stock in
  final stockInSnapshot = await FirebaseFirestore.instance
      .collection('stock_in')
      .get();

  final stockIns = stockInSnapshot.docs.map((doc) {
    final data = doc.data();
    return {
      'product_id': data['product_id'] ?? '',
      'quantity': data['quantity'] ?? 0,
      'date': data['date'] != null ? DateTime.parse(data['date']) : DateTime.now(),
    };
  }).toList();

  // Get stock out
  final stockOutSnapshot = await FirebaseFirestore.instance
      .collection('stock_out')
      .get();

  final stockOuts = stockOutSnapshot.docs.map((doc) {
    final data = doc.data();
    return {
      'product_id': data['product_id'] ?? '',
      'quantity': data['quantity'] ?? 0,
      'date': data['date'] != null ? DateTime.parse(data['date']) : DateTime.now(),
    };
  }).toList();

  // Calculate product reports
  final productReports = products.map((product) {
    final productId = product['id'] as String;
    final stockIn = stockIns
        .where((s) => s['product_id'] == productId)
        .fold<int>(0, (sum, s) => sum + (s['quantity'] as int));
    
    final stockOut = stockOuts
        .where((s) => s['product_id'] == productId)
        .fold<int>(0, (sum, s) => sum + (s['quantity'] as int));

    return ProductReport(
      id: productId,
      name: product['name'] as String,
      code: product['code'] as String,
      stockIn: stockIn,
      stockOut: stockOut,
      balance: (product['stock'] as int),
      unit: product['unit'] as String,
    );
  }).toList();

  // Calculate daily reports
  final dailyMap = <String, DailyReport>{};
  
  for (final stockIn in stockIns) {
    final date = stockIn['date'] as DateTime;
    final key = '${date.year}-${date.month}-${date.day}';
    if (dailyMap.containsKey(key)) {
      dailyMap[key] = DailyReport(
        date: date,
        stockIn: dailyMap[key]!.stockIn + (stockIn['quantity'] as int),
        stockOut: dailyMap[key]!.stockOut,
        netChange: dailyMap[key]!.netChange + (stockIn['quantity'] as int),
      );
    } else {
      dailyMap[key] = DailyReport(
        date: date,
        stockIn: stockIn['quantity'] as int,
        stockOut: 0,
        netChange: stockIn['quantity'] as int,
      );
    }
  }

  for (final stockOut in stockOuts) {
    final date = stockOut['date'] as DateTime;
    final key = '${date.year}-${date.month}-${date.day}';
    if (dailyMap.containsKey(key)) {
      dailyMap[key] = DailyReport(
        date: date,
        stockIn: dailyMap[key]!.stockIn,
        stockOut: dailyMap[key]!.stockOut + (stockOut['quantity'] as int),
        netChange: dailyMap[key]!.netChange - (stockOut['quantity'] as int),
      );
    } else {
      dailyMap[key] = DailyReport(
        date: date,
        stockIn: 0,
        stockOut: stockOut['quantity'] as int,
        netChange: -(stockOut['quantity'] as int),
      );
    }
  }

  final dailyReports = dailyMap.values.toList()
    ..sort((a, b) => a.date.compareTo(b.date));

  final totalProducts = products.length;
  final totalStockIn = stockIns.fold<int>(0, (sum, s) => sum + (s['quantity'] as int));
  final totalStockOut = stockOuts.fold<int>(0, (sum, s) => sum + (s['quantity'] as int));
  final currentStock = products.fold<int>(0, (sum, p) => sum + (p['stock'] as int));

  return ReportSummary(
    totalProducts: totalProducts,
    totalStockIn: totalStockIn,
    totalStockOut: totalStockOut,
    currentStock: currentStock,
    productReports: productReports,
    dailyReports: dailyReports,
  );
});
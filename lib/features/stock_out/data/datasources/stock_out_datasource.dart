// lib/features/stock_out/data/datasources/stock_out_datasource.dart
import '../models/stock_out_request.dart';

abstract class StockOutDataSource {
  Future<StockOutEntry> createStockOutEntry(
    StockOutRequest request,
    String userId,
  );

  Future<StockOutEntry> getStockOutEntry(String id);
  
  Future<List<StockOutEntry>> getStockOutEntriesByProduct(String productCode);
  
  Future<List<StockOutEntry>> getStockOutEntriesByDateRange(
    DateTime startDate,
    DateTime endDate,
  );
  
  Stream<List<StockOutEntry>> watchStockOutEntries();
  
  Future<List<StockOutEntry>> getRecentStockOutEntries(int limit);
  
  /// Check if sufficient stock exists before withdrawal
  Future<bool> verifyStockAvailability(
    String productCode,
    double quantityToWithdraw,
  );
}
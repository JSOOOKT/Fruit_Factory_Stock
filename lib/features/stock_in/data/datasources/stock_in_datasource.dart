import '../models/stock_in_request.dart';
import '../models/stock_in_response.dart';

abstract class StockInDataSource {
  /// Create a new stock in entry
  Future<StockInEntry> createStockInEntry(
    StockInRequest request,
    String userId,
  );

  /// Get stock in entry by ID
  Future<StockInEntry> getStockInEntry(String id);

  /// Get all stock in entries for a product
  Future<List<StockInEntry>> getStockInEntriesByProduct(String productCode);

  /// Get all stock in entries within a date range
  Future<List<StockInEntry>> getStockInEntriesByDateRange(
    DateTime startDate,
    DateTime endDate,
  );

  /// Get stock in entries by sender
  Future<List<StockInEntry>> getStockInEntriesBySender(String senderName);

  /// Stream all stock in entries (for real-time updates)
  Stream<List<StockInEntry>> watchStockInEntries();

  /// Get recent stock in entries (last N entries)
  Future<List<StockInEntry>> getRecentStockInEntries(int limit);

  /// Calculate balance for a specific product
  /// Returns: totalIn, totalOut (from stock_out), and remaining
  Future<StockBalance> getStockBalance(String productCode);

  /// Verify stock balance before allowing withdrawal
  /// Returns true if sufficient stock exists
  Future<bool> verifyStockBalance(String productCode, double quantityToWithdraw);
}

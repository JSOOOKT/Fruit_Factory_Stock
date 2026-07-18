import '../../../../core/error/failure.dart';
import '../datasources/stock_in_datasource.dart';
import '../models/stock_in_request.dart';
import '../models/stock_in_response.dart';

class StockInRepository {
  final StockInDataSource _dataSource;

  StockInRepository({required StockInDataSource dataSource})
      : _dataSource = dataSource;

  /// Create a new stock in entry with validation
  Future<Result<Failure, StockInEntry>> createStockInEntry(
    StockInRequest request,
    String userId,
  ) async {
    try {
      // Validate input
      if (request.senderName.isEmpty) {
        return Result.failure(
          ValidationFailure(message: 'Sender name cannot be empty'),
        );
      }
      if (request.quantityKg <= 0) {
        return Result.failure(
          ValidationFailure(message: 'Quantity must be greater than 0'),
        );
      }
      if (request.productCode.isEmpty) {
        return Result.failure(
          ValidationFailure(message: 'Product code is required'),
        );
      }

      final entry = await _dataSource.createStockInEntry(request, userId);
      return Result.success(entry);
    } on Failure catch (e) {
      return Result.failure(e);
    }
  }

  /// Get stock in entry
  Future<Result<Failure, StockInEntry>> getStockInEntry(String id) async {
    try {
      final entry = await _dataSource.getStockInEntry(id);
      return Result.success(entry);
    } on Failure catch (e) {
      return Result.failure(e);
    }
  }

  /// Get entries by product code
  Future<Result<Failure, List<StockInEntry>>> getStockInEntriesByProduct(
    String productCode,
  ) async {
    try {
      final entries = await _dataSource.getStockInEntriesByProduct(productCode);
      return Result.success(entries);
    } on Failure catch (e) {
      return Result.failure(e);
    }
  }

  /// Get entries by date range
  Future<Result<Failure, List<StockInEntry>>> getStockInEntriesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      if (endDate.isBefore(startDate)) {
        return Result.failure(
          ValidationFailure(message: 'End date must be after start date'),
        );
      }
      final entries =
          await _dataSource.getStockInEntriesByDateRange(startDate, endDate);
      return Result.success(entries);
    } on Failure catch (e) {
      return Result.failure(e);
    }
  }

  /// Get entries by sender name
  Future<Result<Failure, List<StockInEntry>>> getStockInEntriesBySender(
    String senderName,
  ) async {
    try {
      if (senderName.isEmpty) {
        return Result.failure(
          ValidationFailure(message: 'Sender name cannot be empty'),
        );
      }
      final entries = await _dataSource.getStockInEntriesBySender(senderName);
      return Result.success(entries);
    } on Failure catch (e) {
      return Result.failure(e);
    }
  }

  /// Stream all stock in entries
  Stream<List<StockInEntry>> watchStockInEntries() {
    return _dataSource.watchStockInEntries();
  }

  /// Get recent stock in entries
  Future<Result<Failure, List<StockInEntry>>> getRecentStockInEntries(
    int limit,
  ) async {
    try {
      if (limit <= 0) {
        return Result.failure(
          ValidationFailure(message: 'Limit must be greater than 0'),
        );
      }
      final entries = await _dataSource.getRecentStockInEntries(limit);
      return Result.success(entries);
    } on Failure catch (e) {
      return Result.failure(e);
    }
  }

  /// Get stock balance for a product
  Future<Result<Failure, StockBalance>> getStockBalance(
    String productCode,
  ) async {
    try {
      if (productCode.isEmpty) {
        return Result.failure(
          ValidationFailure(message: 'Product code cannot be empty'),
        );
      }
      final balance = await _dataSource.getStockBalance(productCode);
      return Result.success(balance);
    } on Failure catch (e) {
      return Result.failure(e);
    }
  }

  /// Verify stock balance before withdrawal
  Future<Result<Failure, bool>> verifyStockBalance(
    String productCode,
    double quantityToWithdraw,
  ) async {
    try {
      if (productCode.isEmpty) {
        return Result.failure(
          ValidationFailure(message: 'Product code cannot be empty'),
        );
      }
      if (quantityToWithdraw <= 0) {
        return Result.failure(
          ValidationFailure(message: 'Quantity must be greater than 0'),
        );
      }

      final isValid =
          await _dataSource.verifyStockBalance(productCode, quantityToWithdraw);
      return Result.success(isValid);
    } on Failure catch (e) {
      return Result.failure(e);
    }
  }
}

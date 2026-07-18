// lib/features/stock_out/data/repositories/stock_out_repository_impl.dart
import '../../../../core/error/failure.dart';
import '../datasources/stock_out_datasource.dart';
import '../models/stock_out_request.dart';

class StockOutRepository {
  final StockOutDataSource _dataSource;

  StockOutRepository({required StockOutDataSource dataSource})
      : _dataSource = dataSource;

  Future<Result<Failure, StockOutEntry>> createStockOutEntry(
    StockOutRequest request,
    String userId,
  ) async {
    try {
      // Validate input
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
      if (request.purpose.isEmpty) {
        return Result.failure(
          ValidationFailure(message: 'Purpose is required'),
        );
      }

      final entry = await _dataSource.createStockOutEntry(request, userId);
      return Result.success(entry);
    } on Failure catch (e) {
      return Result.failure(e);
    }
  }

  Future<Result<Failure, List<StockOutEntry>>> getStockOutEntriesByProduct(
    String productCode,
  ) async {
    try {
      final entries = await _dataSource.getStockOutEntriesByProduct(productCode);
      return Result.success(entries);
    } on Failure catch (e) {
      return Result.failure(e);
    }
  }

  Future<Result<Failure, List<StockOutEntry>>> getStockOutEntriesByDateRange(
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
          await _dataSource.getStockOutEntriesByDateRange(startDate, endDate);
      return Result.success(entries);
    } on Failure catch (e) {
      return Result.failure(e);
    }
  }

  Stream<List<StockOutEntry>> watchStockOutEntries() {
    return _dataSource.watchStockOutEntries();
  }

  Future<Result<Failure, List<StockOutEntry>>> getRecentStockOutEntries(
    int limit,
  ) async {
    try {
      if (limit <= 0) {
        return Result.failure(
          ValidationFailure(message: 'Limit must be greater than 0'),
        );
      }
      final entries = await _dataSource.getRecentStockOutEntries(limit);
      return Result.success(entries);
    } on Failure catch (e) {
      return Result.failure(e);
    }
  }

  Future<Result<Failure, bool>> verifyStockAvailability(
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

      final isAvailable = await _dataSource.verifyStockAvailability(
        productCode,
        quantityToWithdraw,
      );
      return Result.success(isAvailable);
    } on Failure catch (e) {
      return Result.failure(e);
    }
  }
}
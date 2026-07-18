// lib/features/stock_out/presentation/providers/stock_out_providers.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/firebase_stock_out_datasource.dart';
import '../../data/datasources/stock_out_datasource.dart';
import '../../data/repositories/stock_out_repository_impl.dart';
import '../../data/models/stock_out_request.dart';

// Providers
final stockOutDataSourceProvider = Provider<StockOutDataSource>((ref) {
  return FirebaseStockOutDataSource();
});

final stockOutRepositoryProvider = Provider<StockOutRepository>((ref) {
  final dataSource = ref.watch(stockOutDataSourceProvider);
  return StockOutRepository(dataSource: dataSource);
});

// Watch all stock out entries (real-time)
final watchStockOutEntriesProvider =
    StreamProvider<List<StockOutEntry>>((ref) {
  final repository = ref.watch(stockOutRepositoryProvider);
  return repository.watchStockOutEntries();
});

// Get recent stock out entries
final getRecentStockOutEntriesProvider =
    FutureProvider.family<List<StockOutEntry>, int>((ref, limit) async {
  final repository = ref.watch(stockOutRepositoryProvider);
  final result = await repository.getRecentStockOutEntries(limit);
  return result.fold(
    (failure) => throw Exception(failure.toString()),
    (entries) => entries,
  );
});

// Get stock out entries by product
final getStockOutEntriesByProductProvider =
    FutureProvider.family<List<StockOutEntry>, String>((ref, productCode) async {
  final repository = ref.watch(stockOutRepositoryProvider);
  final result = await repository.getStockOutEntriesByProduct(productCode);
  return result.fold(
    (failure) => throw Exception(failure.toString()),
    (entries) => entries,
  );
});

// Stock Out Notifier
class StockOutNotifier extends StateNotifier<AsyncValue<void>> {
  final StockOutRepository _repository;

  StockOutNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> createStockOutEntry(StockOutRequest request, String userId) async {
    state = const AsyncValue.loading();
    
    // Verify stock availability first
    final availability = await _repository.verifyStockAvailability(
      request.productCode,
      request.quantityKg,
    );
    
    final isAvailable = availability.fold(
      (failure) => false,
      (available) => available,
    );

    if (!isAvailable) {
      state = AsyncValue.error(
        Exception('Insufficient stock for product: ${request.productCode}'),
        StackTrace.current,
      );
      return;
    }

    final result = await _repository.createStockOutEntry(request, userId);
    result.fold(
      (failure) {
        state = AsyncValue.error(failure, StackTrace.current);
      },
      (entry) {
        state = const AsyncValue.data(null);
        // Invalidate relevant providers
        ref.invalidate(getRecentStockOutEntriesProvider);
      },
    );
  }
}

final stockOutNotifierProvider =
    StateNotifierProvider<StockOutNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(stockOutRepositoryProvider);
  return StockOutNotifier(repository);
});

// Form state
class StockOutFormState {
  final String productCode;
  final double quantityKg;
  final String purpose;
  final String dateIssued;
  final String note;
  final bool isValid;

  const StockOutFormState({
    this.productCode = '',
    this.quantityKg = 0.0,
    this.purpose = '',
    this.dateIssued = '',
    this.note = '',
    this.isValid = false,
  });

  StockOutFormState copyWith({
    String? productCode,
    double? quantityKg,
    String? purpose,
    String? dateIssued,
    String? note,
    bool? isValid,
  }) {
    return StockOutFormState(
      productCode: productCode ?? this.productCode,
      quantityKg: quantityKg ?? this.quantityKg,
      purpose: purpose ?? this.purpose,
      dateIssued: dateIssued ?? this.dateIssued,
      note: note ?? this.note,
      isValid: isValid ?? this.isValid,
    );
  }
}

class StockOutFormNotifier extends StateNotifier<StockOutFormState> {
  StockOutFormNotifier() : super(const StockOutFormState());

  void updateProductCode(String value) {
    state = state.copyWith(productCode: value);
    _validateForm();
  }

  void updateQuantityKg(double value) {
    state = state.copyWith(quantityKg: value);
    _validateForm();
  }

  void updatePurpose(String value) {
    state = state.copyWith(purpose: value);
    _validateForm();
  }

  void updateDateIssued(String value) {
    state = state.copyWith(dateIssued: value);
    _validateForm();
  }

  void updateNote(String value) {
    state = state.copyWith(note: value);
  }

  void _validateForm() {
    final isValid = state.productCode.isNotEmpty &&
        state.quantityKg > 0 &&
        state.purpose.isNotEmpty &&
        state.dateIssued.isNotEmpty;
    state = state.copyWith(isValid: isValid);
  }

  void reset() {
    state = const StockOutFormState();
  }
}

final stockOutFormProvider =
    StateNotifierProvider<StockOutFormNotifier, StockOutFormState>((ref) {
  return StockOutFormNotifier();
});
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../data/datasources/firebase_stock_in_datasource.dart';
import '../../data/models/stock_in_request.dart';
import '../../data/models/stock_in_response.dart';
import '../../data/repositories/stock_in_repository.dart';
import '../../presentation/utils/stock_in_validators.dart';
import '../utils/voice_nlu_parser.dart';
import '../pages/stock_in_manual_screen.dart';
import '../../presentation/widgets/stock_in_confirmation_widget.dart';

part 'stock_in_providers.g.dart';

/// Firebase Firestore instance provider
@riverpod
FirebaseFirestore firebaseFirestore(FirebaseFirestoreRef ref) {
  return FirebaseFirestore.instance;
}

/// Stock In DataSource provider
@riverpod
FirebaseStockInDataSource stockInDataSource(StockInDataSourceRef ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return FirebaseStockInDataSource(firestore: firestore);
}

/// Stock In Repository provider
@riverpod
StockInRepository stockInRepository(StockInRepositoryRef ref) {
  final dataSource = ref.watch(stockInDataSourceProvider);
  return StockInRepository(dataSource: dataSource);
}

/// Watch all stock in entries (real-time updates)
@riverpod
Stream<List<StockInEntry>> watchStockInEntries(WatchStockInEntriesRef ref) {
  final repository = ref.watch(stockInRepositoryProvider);
  return repository.watchStockInEntries();
}

/// Get all stock in entries (async)
@riverpod
Future<List<StockInEntry>> getAllStockInEntries(GetAllStockInEntriesRef ref) {
  return ref.watch(watchStockInEntriesProvider).first;
}

/// Get recent stock in entries
@riverpod
Future<List<StockInEntry>> getRecentStockInEntries(
  GetRecentStockInEntriesRef ref, {
  required int limit,
}) async {
  final repository = ref.watch(stockInRepositoryProvider);
  final result = await repository.getRecentStockInEntries(limit);
  return result.fold(
    (failure) => throw Exception(failure.toString()),
    (entries) => entries,
  );
}

/// Get stock in entries by product
@riverpod
Future<List<StockInEntry>> getStockInEntriesByProduct(
  GetStockInEntriesByProductRef ref, {
  required String productCode,
}) async {
  final repository = ref.watch(stockInRepositoryProvider);
  final result = await repository.getStockInEntriesByProduct(productCode);
  return result.fold(
    (failure) => throw Exception(failure.toString()),
    (entries) => entries,
  );
}

/// Get stock in entries by date range
@riverpod
Future<List<StockInEntry>> getStockInEntriesByDateRange(
  GetStockInEntriesByDateRangeRef ref, {
  required DateTime startDate,
  required DateTime endDate,
}) async {
  final repository = ref.watch(stockInRepositoryProvider);
  final result =
      await repository.getStockInEntriesByDateRange(startDate, endDate);
  return result.fold(
    (failure) => throw Exception(failure.toString()),
    (entries) => entries,
  );
}

/// Get stock balance for a product
@riverpod
Future<StockBalance> getStockBalance(
  GetStockBalanceRef ref, {
  required String productCode,
}) async {
  final repository = ref.watch(stockInRepositoryProvider);
  final result = await repository.getStockBalance(productCode);
  return result.fold(
    (failure) => throw Exception(failure.toString()),
    (balance) => balance,
  );
}

/// Verify stock balance before withdrawal
@riverpod
Future<bool> verifyStockBalance(
  VerifyStockBalanceRef ref, {
  required String productCode,
  required double quantityToWithdraw,
}) async {
  final repository = ref.watch(stockInRepositoryProvider);
  final result =
      await repository.verifyStockBalance(productCode, quantityToWithdraw);
  return result.fold(
    (failure) => throw Exception(failure.toString()),
    (isValid) => isValid,
  );
}

/// Stock In Entry Notifier for CRUD operations
@riverpod
class StockInNotifier extends _$StockInNotifier {
  @override
  FutureOr<void> build() {
    // Initial state is void (no-op)
  }

  Future<StockInEntry?> createStockInEntry(
    StockInRequest request,
    String userId,
  ) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.watch(stockInRepositoryProvider);
      final result = await repository.createStockInEntry(request, userId);
      return result.fold(
        (failure) => throw Exception(failure.toString()),
        (entry) {
          // Refresh recent entries
          ref.invalidate(getRecentStockInEntriesProvider);
          return entry;
        },
      );
    });
    return null;
  }
}

/// Manual Entry Form State
@riverpod
class ManualEntryFormNotifier extends _$ManualEntryFormNotifier {
  @override
  ManualEntryFormState build() {
    return const ManualEntryFormState(
      senderName: '',
      dateReceived: '',
      productCode: '',
      quantityKg: 0.0,
      shift: 'morning',
      note: '',
      isValid: false,
    );
  }

  void updateSenderName(String value) {
    state = state.copyWith(senderName: value);
    _validateForm();
  }

  void updateDateReceived(String value) {
    state = state.copyWith(dateReceived: value);
    _validateForm();
  }

  void updateProductCode(String value) {
    state = state.copyWith(productCode: value);
    _validateForm();
  }

  void updateQuantityKg(double value) {
    state = state.copyWith(quantityKg: value);
    _validateForm();
  }

  void updateShift(String value) {
    state = state.copyWith(shift: value);
    _validateForm();
  }

  void updateNote(String value) {
    state = state.copyWith(note: value);
    _validateForm();
  }

  void reset() {
    state = const ManualEntryFormState(
      senderName: '',
      dateReceived: '',
      productCode: '',
      quantityKg: 0.0,
      shift: 'morning',
      note: '',
      isValid: false,
    );
  }

  void _validateForm() {
    final isValid = state.senderName.isNotEmpty &&
        state.dateReceived.isNotEmpty &&
        state.productCode.isNotEmpty &&
        state.quantityKg > 0;
    state = state.copyWith(isValid: isValid);
  }
}

/// Voice Entry State
@riverpod
class VoiceEntryNotifier extends _$VoiceEntryNotifier {
  @override
  VoiceEntryState build() {
    return const VoiceEntryState(
      isListening: false,
      transcript: '',
      parsedData: null,
      error: '',
    );
  }

  void setListening(bool value) {
    state = state.copyWith(isListening: value);
  }

  void setTranscript(String transcript) {
    state = state.copyWith(transcript: transcript);
  }

  void setParsedData(ParsedVoiceData? data) {
    state = state.copyWith(parsedData: data);
  }

  void setError(String error) {
    state = state.copyWith(error: error);
  }

  void reset() {
    state = const VoiceEntryState(
      isListening: false,
      transcript: '',
      parsedData: null,
      error: '',
    );
  }
}

// MODELS

class ManualEntryFormState {
  final String senderName;
  final String dateReceived;
  final String productCode;
  final double quantityKg;
  final String shift;
  final String note;
  final bool isValid;

  const ManualEntryFormState({
    required this.senderName,
    required this.dateReceived,
    required this.productCode,
    required this.quantityKg,
    required this.shift,
    required this.note,
    required this.isValid,
  });

  ManualEntryFormState copyWith({
    String? senderName,
    String? dateReceived,
    String? productCode,
    double? quantityKg,
    String? shift,
    String? note,
    bool? isValid,
  }) {
    return ManualEntryFormState(
      senderName: senderName ?? this.senderName,
      dateReceived: dateReceived ?? this.dateReceived,
      productCode: productCode ?? this.productCode,
      quantityKg: quantityKg ?? this.quantityKg,
      shift: shift ?? this.shift,
      note: note ?? this.note,
      isValid: isValid ?? this.isValid,
    );
  }
}

class VoiceEntryState {
  final bool isListening;
  final String transcript;
  final ParsedVoiceData? parsedData;
  final String error;

  const VoiceEntryState({
    required this.isListening,
    required this.transcript,
    required this.parsedData,
    required this.error,
  });

  VoiceEntryState copyWith({
    bool? isListening,
    String? transcript,
    ParsedVoiceData? parsedData,
    String? error,
  }) {
    return VoiceEntryState(
      isListening: isListening ?? this.isListening,
      transcript: transcript ?? this.transcript,
      parsedData: parsedData ?? this.parsedData,
      error: error ?? this.error,
    );
  }
}

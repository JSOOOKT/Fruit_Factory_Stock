// lib/features/stock/presentation/providers/stock_balance_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/services/stock_balance_service.dart';

final stockBalanceServiceProvider = Provider<StockBalanceService>((ref) {
  return StockBalanceService(
    firestore: FirebaseFirestore.instance,
  );
});

final stockOutListProvider = FutureProvider<List>((ref) async {
  // TODO: Implement actual stock out list
  return [];
});
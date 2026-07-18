import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/product/presentation/providers/product_providers.dart';
import '../../features/stock_in/presentation/providers/stock_in_providers.dart';
import '../../features/stock_out/presentation/providers/stock_out_providers.dart';

final appBootstrapProvider = Provider<bool>((ref) {
  ref.watch(authStateProvider);
  ref.watch(activeProductsProvider);
  ref.watch(stockInRepositoryProvider);
  ref.watch(stockOutRepositoryProvider);
  return true;
});
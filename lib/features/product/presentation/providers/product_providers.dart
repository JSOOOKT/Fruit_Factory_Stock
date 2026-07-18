import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fruit_factory_stock/features/product/data/datasources/firebase_product_datasource.dart';
import 'package:fruit_factory_stock/features/product/data/repositories/product_repository_impl.dart';
import 'package:fruit_factory_stock/features/product/data/datasources/product_datasource.dart';
import 'package:fruit_factory_stock/shared/models/product_type.dart';
import 'package:fruit_factory_stock/core/error/failure.dart';

// Firebase instance (using existing provider)
final productFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

// DataSource
final productDataSourceProvider = Provider<ProductDataSource>((ref) {
  final firestore = ref.watch(productFirestoreProvider);
  return FirebaseProductDataSource(firestore: firestore);
});

// Repository
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final dataSource = ref.watch(productDataSourceProvider);
  return ProductRepositoryImpl(dataSource: dataSource);
});

// Get all products (one-time fetch)
final allProductsProvider = FutureProvider<List<ProductType>>((ref) async {
  final repository = ref.watch(productRepositoryProvider);
  final result = await repository.getAllProducts();
  return result.fold(
    (failure) => throw failure,
    (products) => products,
  );
});

// Get active products only
final activeProductsProvider = FutureProvider<List<ProductType>>((ref) async {
  final repository = ref.watch(productRepositoryProvider);
  final result = await repository.getActiveProducts();
  return result.fold(
    (failure) => throw failure,
    (products) => products,
  );
});

// Watch products (real-time updates)
final watchProductsProvider = StreamProvider<List<ProductType>>((ref) async* {
  final repository = ref.watch(productRepositoryProvider);
  await for (final result in repository.watchProducts()) {
    yield result.fold(
      (failure) => throw failure,
      (products) => products,
    );
  }
});

// Search products
final searchProductsProvider =
    FutureProvider.family<List<ProductType>, String>((ref, query) async {
  if (query.isEmpty) {
    return ref.watch(activeProductsProvider).value ?? [];
  }
  
  final repository = ref.watch(productRepositoryProvider);
  final result = await repository.searchProducts(query);
  return result.fold(
    (failure) => throw failure,
    (products) => products,
  );
});

// Get product by code
final productByCodeProvider =
    FutureProvider.family<ProductType?, String>((ref, code) async {
  final repository = ref.watch(productRepositoryProvider);
  final result = await repository.getProductByCode(code);
  return result.fold(
    (failure) => throw failure,
    (product) => product,
  );
});

// Product create/update notifier
class ProductNotifier extends StateNotifier<AsyncValue<void>> {
  final ProductRepository _repository;

  ProductNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> createProduct(ProductType product) async {
    state = const AsyncValue.loading();
    final result = await _repository.createProduct(product);
    result.fold(
      (failure) {
        state = AsyncValue.error(failure, StackTrace.current);
      },
      (_) {
        state = const AsyncValue.data(null);
      },
    );
  }

  Future<void> updateProduct(ProductType product) async {
    state = const AsyncValue.loading();
    final result = await _repository.updateProduct(product);
    result.fold(
      (failure) {
        state = AsyncValue.error(failure, StackTrace.current);
      },
      (_) {
        state = const AsyncValue.data(null);
      },
    );
  }

  Future<void> deleteProduct(String code) async {
    state = const AsyncValue.loading();
    final result = await _repository.deleteProduct(code);
    result.fold(
      (failure) {
        state = AsyncValue.error(failure, StackTrace.current);
      },
      (_) {
        state = const AsyncValue.data(null);
      },
    );
  }

  Future<void> bulkImportProducts(List<ProductType> products) async {
    state = const AsyncValue.loading();
    final result = await _repository.bulkImportProducts(products);
    result.fold(
      (failure) {
        state = AsyncValue.error(failure, StackTrace.current);
      },
      (_) {
        state = const AsyncValue.data(null);
      },
    );
  }

  void clearError() {
    state = const AsyncValue.data(null);
  }
}

// Product notifier provider
final productNotifierProvider =
    StateNotifierProvider<ProductNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(productRepositoryProvider);
  return ProductNotifier(repository);
});

// Filtered products provider
final filteredProductsProvider =
    StateNotifierProvider<FilteredProductsNotifier, List<ProductType>>((ref) {
  final allProducts = ref.watch(activeProductsProvider);
  return FilteredProductsNotifier(allProducts);
});

class FilteredProductsNotifier extends StateNotifier<List<ProductType>> {
  FilteredProductsNotifier(AsyncValue<List<ProductType>> products)
      : super(products.maybeWhen(
          data: (p) => p,
          orElse: () => [],
        ));

  void filterByName(String query) {
    // Implement filtering logic
  }

  void sortByCode() {
    state = [...state]..sort((a, b) => a.productCode.compareTo(b.productCode));
  }

  void sortByName() {
    state = [...state]..sort((a, b) => a.nameEn.compareTo(b.nameEn));
  }
}

import 'package:fruit_factory_stock/core/error/failure.dart';
import 'package:fruit_factory_stock/features/product/data/datasources/product_datasource.dart';
import 'package:fruit_factory_stock/shared/models/product_type.dart';

abstract class ProductRepository {
  Future<Result<Failure, List<ProductType>>> getAllProducts();
  Future<Result<Failure, List<ProductType>>> getActiveProducts();
  Future<Result<Failure, ProductType?>> getProductByCode(String code);
  Future<Result<Failure, void>> createProduct(ProductType product);
  Future<Result<Failure, void>> updateProduct(ProductType product);
  Future<Result<Failure, void>> deleteProduct(String code);
  Future<Result<Failure, List<ProductType>>> searchProducts(String query);
  Future<Result<Failure, void>> bulkImportProducts(List<ProductType> products);
  Stream<Result<Failure, List<ProductType>>> watchProducts();
}

class ProductRepositoryImpl implements ProductRepository {
  final ProductDataSource _dataSource;

  ProductRepositoryImpl({required ProductDataSource dataSource})
      : _dataSource = dataSource;

  @override
  Future<Result<Failure, List<ProductType>>> getAllProducts() async {
    try {
      final products = await _dataSource.getAllProducts();
      return Result.success(products);
    } catch (e) {
      return Result.failure(_mapException(e));
    }
  }

  @override
  Future<Result<Failure, List<ProductType>>> getActiveProducts() async {
    try {
      final products = await _dataSource.getActiveProducts();
      return Result.success(products);
    } catch (e) {
      return Result.failure(_mapException(e));
    }
  }

  @override
  Future<Result<Failure, ProductType?>> getProductByCode(String code) async {
    try {
      final product = await _dataSource.getProductByCode(code);
      return Result.success(product);
    } catch (e) {
      return Result.failure(_mapException(e));
    }
  }

  @override
  Future<Result<Failure, void>> createProduct(ProductType product) async {
    try {
      await _dataSource.createProduct(product);
      return Result.success(null);
    } catch (e) {
      return Result.failure(_mapException(e));
    }
  }

  @override
  Future<Result<Failure, void>> updateProduct(ProductType product) async {
    try {
      await _dataSource.updateProduct(product);
      return Result.success(null);
    } catch (e) {
      return Result.failure(_mapException(e));
    }
  }

  @override
  Future<Result<Failure, void>> deleteProduct(String code) async {
    try {
      await _dataSource.deleteProduct(code);
      return Result.success(null);
    } catch (e) {
      return Result.failure(_mapException(e));
    }
  }

  @override
  Future<Result<Failure, List<ProductType>>> searchProducts(String query) async {
    try {
      final products = await _dataSource.searchProducts(query);
      return Result.success(products);
    } catch (e) {
      return Result.failure(_mapException(e));
    }
  }

  @override
  Future<Result<Failure, void>> bulkImportProducts(
      List<ProductType> products) async {
    try {
      await _dataSource.bulkImportProducts(products);
      return Result.success(null);
    } catch (e) {
      return Result.failure(_mapException(e));
    }
  }

  @override
  Stream<Result<Failure, List<ProductType>>> watchProducts() {
    return _dataSource.watchProducts().map((products) {
      return Result.success(products);
    }).handleError((error) {
      return Result.failure(_mapException(error));
    });
  }

  Failure _mapException(Object exception) {
    if (exception is Failure) {
      return exception;
    }
    return UnknownFailure(exception.toString());
  }
}

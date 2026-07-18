import 'package:fruit_factory_stock/core/error/failure.dart';
import 'package:fruit_factory_stock/shared/models/product_type.dart';

abstract class ProductDataSource {
  /// Get all products
  Future<List<ProductType>> getAllProducts();

  /// Get active products only
  Future<List<ProductType>> getActiveProducts();

  /// Get product by code
  Future<ProductType?> getProductByCode(String productCode);

  /// Create new product
  Future<void> createProduct(ProductType product);

  /// Update product
  Future<void> updateProduct(ProductType product);

  /// Delete product (soft delete - set active to false)
  Future<void> deleteProduct(String productCode);

  /// Search products by name
  Future<List<ProductType>> searchProducts(String query);

  /// Get products by type (for grouping in dashboards)
  Future<List<ProductType>> getProductsByType(String type);

  /// Bulk import products
  Future<void> bulkImportProducts(List<ProductType> products);

  /// Stream of products (for real-time updates)
  Stream<List<ProductType>> watchProducts();
}

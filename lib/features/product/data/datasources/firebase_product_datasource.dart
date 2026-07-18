import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:fruit_factory_stock/core/error/failure.dart';
import 'package:fruit_factory_stock/features/product/data/datasources/product_datasource.dart';
import 'package:fruit_factory_stock/shared/models/product_type.dart';

class FirebaseProductDataSource implements ProductDataSource {
  static const String _collectionPath = 'products';
  
  final FirebaseFirestore _firestore;
  final Logger _logger = Logger();

  FirebaseProductDataSource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  @override
  Future<List<ProductType>> getAllProducts() async {
    try {
      final snapshot = await _firestore.collection(_collectionPath).get();
      final products = snapshot.docs
          .map((doc) => ProductType.fromJson(doc.data()))
          .toList();
      _logger.i('Retrieved ${products.length} products');
      return products;
    } catch (e) {
      _logger.e('Error getting all products', error: e);
      throw FirebaseFailure('Failed to get products');
    }
  }

  @override
  Future<List<ProductType>> getActiveProducts() async {
    try {
      final snapshot = await _firestore
          .collection(_collectionPath)
          .where('active', isEqualTo: true)
          .get();
      final products = snapshot.docs
          .map((doc) => ProductType.fromJson(doc.data()))
          .toList();
      _logger.i('Retrieved ${products.length} active products');
      return products;
    } catch (e) {
      _logger.e('Error getting active products', error: e);
      throw FirebaseFailure('Failed to get active products');
    }
  }

  @override
  Future<ProductType?> getProductByCode(String productCode) async {
    try {
      final doc =
          await _firestore.collection(_collectionPath).doc(productCode).get();
      if (!doc.exists) {
        _logger.w('Product not found: $productCode');
        return null;
      }
      return ProductType.fromJson(doc.data()!);
    } catch (e) {
      _logger.e('Error getting product by code', error: e);
      throw FirebaseFailure('Failed to get product');
    }
  }

  @override
  Future<void> createProduct(ProductType product) async {
    try {
      await _firestore
          .collection(_collectionPath)
          .doc(product.productCode)
          .set(product.toJson());
      _logger.i('Product created: ${product.productCode}');
    } catch (e) {
      _logger.e('Error creating product', error: e);
      throw FirebaseFailure('Failed to create product');
    }
  }

  @override
  Future<void> updateProduct(ProductType product) async {
    try {
      await _firestore
          .collection(_collectionPath)
          .doc(product.productCode)
          .update({
        ...product.toJson(),
        'updated_at': FieldValue.serverTimestamp(),
      });
      _logger.i('Product updated: ${product.productCode}');
    } catch (e) {
      _logger.e('Error updating product', error: e);
      throw FirebaseFailure('Failed to update product');
    }
  }

  @override
  Future<void> deleteProduct(String productCode) async {
    try {
      // Soft delete: set active to false
      await _firestore.collection(_collectionPath).doc(productCode).update({
        'active': false,
        'updated_at': FieldValue.serverTimestamp(),
      });
      _logger.i('Product deleted (soft): $productCode');
    } catch (e) {
      _logger.e('Error deleting product', error: e);
      throw FirebaseFailure('Failed to delete product');
    }
  }

  @override
  Future<List<ProductType>> searchProducts(String query) async {
    try {
      // Firestore text search is limited, so we fetch and filter locally
      final allProducts = await getActiveProducts();
      final searchLower = query.toLowerCase();
      
      final filtered = allProducts.where((product) {
        return product.nameEn.toLowerCase().contains(searchLower) ||
            product.nameTh.toLowerCase().contains(searchLower) ||
            product.productCode.toLowerCase().contains(searchLower);
      }).toList();

      _logger.i('Search found ${filtered.length} products for: $query');
      return filtered;
    } catch (e) {
      _logger.e('Error searching products', error: e);
      throw FirebaseFailure('Failed to search products');
    }
  }

  @override
  Future<List<ProductType>> getProductsByType(String type) async {
    try {
      final allProducts = await getActiveProducts();
      final filtered = allProducts.where((p) => p.nameTh.contains(type) || p.nameEn.contains(type)).toList();
      _logger.i('Retrieved ${filtered.length} products of type: $type');
      return filtered;
    } catch (e) {
      _logger.e('Error getting products by type', error: e);
      throw FirebaseFailure('Failed to get products');
    }
  }

  @override
  Future<void> bulkImportProducts(List<ProductType> products) async {
    try {
      final batch = _firestore.batch();
      
      for (final product in products) {
        final docRef =
            _firestore.collection(_collectionPath).doc(product.productCode);
        batch.set(docRef, product.toJson());
      }
      
      await batch.commit();
      _logger.i('Bulk imported ${products.length} products');
    } catch (e) {
      _logger.e('Error bulk importing products', error: e);
      throw FirebaseFailure('Failed to bulk import products');
    }
  }

  @override
  Stream<List<ProductType>> watchProducts() {
    return _firestore
        .collection(_collectionPath)
        .where('active', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final products = snapshot.docs
              .map((doc) => ProductType.fromJson(doc.data()))
              .toList();
          _logger.d('Products updated: ${products.length}');
          return products;
        })
        .handleError((error) {
          _logger.e('Error watching products', error: error);
          throw FirebaseFailure('Failed to watch products');
        });
  }
}

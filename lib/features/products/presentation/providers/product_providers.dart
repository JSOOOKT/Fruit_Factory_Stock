import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/product_model.dart';

final productCollectionProvider = Provider<CollectionReference>((ref) {
  return FirebaseFirestore.instance.collection('products');
});

final productListProvider = FutureProvider<List<Product>>((ref) async {
  final collection = ref.watch(productCollectionProvider);
  final snapshot = await collection.get();
  return snapshot.docs.map((doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Product.fromJson(data);
  }).toList();
});

final productNotifierProvider = StateNotifierProvider<ProductNotifier, List<Product>>((ref) {
  return ProductNotifier(ref);
});

class ProductNotifier extends StateNotifier<List<Product>> {
  final Ref ref;
  
  ProductNotifier(this.ref) : super([]);

  Future<void> addProduct(Product product) async {
    final collection = ref.read(productCollectionProvider);
    await collection.doc(product.id).set(product.toJson());
    state = [...state, product];
  }

  Future<void> updateProduct(Product product) async {
    final collection = ref.read(productCollectionProvider);
    await collection.doc(product.id).update(product.toJson());
    final index = state.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      state = [...state]..[index] = product;
    }
  }

  Future<void> deleteProduct(String id) async {
    final collection = ref.read(productCollectionProvider);
    await collection.doc(id).delete();
    state = state.where((p) => p.id != id).toList();
  }

  Future<void> loadProducts() async {
    final collection = ref.read(productCollectionProvider);
    final snapshot = await collection.get();
    state = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return Product.fromJson(data);
    }).toList();
  }
}

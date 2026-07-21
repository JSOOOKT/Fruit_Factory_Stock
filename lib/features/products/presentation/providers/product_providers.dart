import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/product_model.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

final productCollectionProvider = Provider<CollectionReference>((ref) {
  return FirebaseFirestore.instance.collection('products');
});

final productListProvider = FutureProvider<List<Product>>((ref) async {
  final collection = ref.watch(productCollectionProvider);
  final factoryId = ref.watch(currentFactoryIdProvider);
  
  // ✅ กรองเฉพาะสินค้าของโรงงานที่เลือก
  Query query = collection.where('factoryId', isEqualTo: factoryId);
  
  final snapshot = await query.get();
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
    final factoryId = ref.read(currentFactoryIdProvider);
    
    // ✅ บันทึกพร้อม factoryId
    final productWithFactory = product.copyWith(
      factoryId: factoryId,
    );
    
    await collection.doc(productWithFactory.id).set(productWithFactory.toJson());
    state = [...state, productWithFactory];
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
    final factoryId = ref.read(currentFactoryIdProvider);
    
    final snapshot = await collection
        .where('factoryId', isEqualTo: factoryId)
        .get();
        
    state = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return Product.fromJson(data);
    }).toList();
  }
}

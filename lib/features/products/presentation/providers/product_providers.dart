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
  
  if (factoryId == null) return [];
  
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
    final userData = await ref.read(currentUserDataProvider.future);
    final userName = userData?['name'] ?? 'unknown';
    
    // สร้างประวัติการสร้าง
    final history = [
      {
        'action': 'create',
        'user': userName,
        'timestamp': DateTime.now().toIso8601String(),
        'details': 'สร้างสินค้า: ${product.name} (${product.code})',
        'product_name': product.name,
        'product_code': product.code,
      }
    ];
    
    final productWithFactory = product.copyWith(
      factoryId: factoryId,
      history: history,
      createdBy: userName,
    );
    
    await collection.doc(productWithFactory.id).set(productWithFactory.toJson());
    state = [...state, productWithFactory];
    
    // บันทึกประวัติแยกใน collection product_history
    await _saveProductHistory(
      productId: product.id,
      action: 'create',
      userName: userName,
      details: 'สร้างสินค้า: ${product.name} (${product.code})',
      productName: product.name,
      productCode: product.code,
    );
  }

  Future<void> updateProduct(Product product) async {
    final collection = ref.read(productCollectionProvider);
    final userData = await ref.read(currentUserDataProvider.future);
    final userName = userData?['name'] ?? 'unknown';
    final factoryId = ref.read(currentFactoryIdProvider);
    
    // ✅ ดึงข้อมูลเก่า
    final doc = await collection.doc(product.id).get();
    if (!doc.exists) {
      print('❌ Product not found: ${product.id}');
      return;
    }
    
    final oldData = doc.data() as Map<String, dynamic>;
    final oldProduct = Product.fromJson(oldData);
    
    // ✅ สร้างประวัติการแก้ไข
    final newHistory = List<Map<String, dynamic>>.from(oldProduct.history ?? []);
    final historyEntry = {
      'action': 'update',
      'user': userName,
      'timestamp': DateTime.now().toIso8601String(),
      'details': 'แก้ไขสินค้า: ${oldProduct.name} -> ${product.name} (${oldProduct.code} -> ${product.code})',
      'product_name': product.name,
      'product_code': product.code,
      'old_name': oldProduct.name,
      'new_name': product.name,
      'old_code': oldProduct.code,
      'new_code': product.code,
    };
    newHistory.add(historyEntry);
    
    // ✅ เก็บ factoryId เดิมไว้
    final updatedProduct = product.copyWith(
      history: newHistory,
      updatedAt: DateTime.now(),
      updatedBy: userName,
      factoryId: oldProduct.factoryId ?? factoryId, // ✅ เก็บ factoryId เดิม
    );
    
    await collection.doc(product.id).update(updatedProduct.toJson());
    
    // ✅ อัปเดต state โดยเก็บ factoryId เดิม
    final index = state.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      state = [...state]..[index] = updatedProduct;
    } else {
      // ✅ ถ้าไม่เจอใน state ให้โหลดใหม่
      await loadProducts();
    }
    
    // ✅ บันทึกประวัติแยกใน collection product_history
    await _saveProductHistory(
      productId: product.id,
      action: 'update',
      userName: userName,
      details: 'แก้ไขสินค้า: ${oldProduct.name} -> ${product.name} (${oldProduct.code} -> ${product.code})',
      productName: product.name,
      productCode: product.code,
      oldData: {
        'old_name': oldProduct.name,
        'old_code': oldProduct.code,
      },
      newData: {
        'new_name': product.name,
        'new_code': product.code,
      },
    );
    
    // ✅ รีเฟรช productListProvider
    ref.refresh(productListProvider);
  }

  Future<void> deleteProduct(String id) async {
    final firestore = FirebaseFirestore.instance;
    final collection = ref.read(productCollectionProvider);
    final userData = await ref.read(currentUserDataProvider.future);
    final userName = userData?['name'] ?? 'unknown';
    
    try {
      // ดึงข้อมูลสินค้าก่อนลบ
      final doc = await collection.doc(id).get();
      if (!doc.exists) return;
      
      final data = doc.data() as Map<String, dynamic>;
      final product = Product.fromJson(data);
      
      // บันทึกประวัติการลบ
      await _saveProductHistory(
        productId: id,
        action: 'delete',
        userName: userName,
        details: 'ลบสินค้า: ${product.name} (${product.code})',
        productName: product.name,
        productCode: product.code,
        deletedData: data,
      );
      
      // 1. ลบ Stock In Entries
      final stockInSnapshot = await firestore
          .collection('stock_in_entries')
          .where('product_id', isEqualTo: id)
          .get();
      
      for (final doc in stockInSnapshot.docs) {
        await doc.reference.delete();
      }
      
      // 2. ลบ Stock Out Entries
      final stockOutSnapshot = await firestore
          .collection('stock_out_entries')
          .where('product_id', isEqualTo: id)
          .get();
      
      for (final doc in stockOutSnapshot.docs) {
        await doc.reference.delete();
      }
      
      // 3. ลบสินค้าเอง
      await collection.doc(id).delete();
      
      // 4. อัปเดต state
      state = state.where((p) => p.id != id).toList();
      
      // 5. รีเฟรช providers
      ref.refresh(productListProvider);
      
    } catch (e) {
      print('Error deleting product: $e');
      rethrow;
    }
  }

  Future<void> _saveProductHistory({
    required String productId,
    required String action,
    required String userName,
    required String details,
    required String productName,
    required String productCode,
    Map<String, dynamic>? oldData,
    Map<String, dynamic>? newData,
    Map<String, dynamic>? deletedData,
  }) async {
    try {
      final factoryId = ref.read(currentFactoryIdProvider);
      final historyData = {
        'product_id': productId,
        'product_name': productName,
        'product_code': productCode,
        'action': action,
        'user': userName,
        'timestamp': FieldValue.serverTimestamp(),
        'details': details,
        'factoryId': factoryId,
        'old_data': oldData,
        'new_data': newData,
        'deleted_data': deletedData,
      };
      
      await FirebaseFirestore.instance
          .collection('product_history')
          .add(historyData);
          
      print('✅ Saved product history: $action - $productName');
    } catch (e) {
      print('❌ Error saving product history: $e');
    }
  }

  Future<void> loadProducts() async {
    final collection = ref.read(productCollectionProvider);
    final factoryId = ref.read(currentFactoryIdProvider);
    
    if (factoryId == null) {
      state = [];
      return;
    }
    
    final snapshot = await collection
        .where('factoryId', isEqualTo: factoryId)
        .get();
        
    state = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return Product.fromJson(data);
    }).toList();
  }
}

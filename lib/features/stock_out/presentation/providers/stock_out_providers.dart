// lib/features/stock_out/presentation/providers/stock_out_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/stock_out_model.dart';

final stockOutCollectionProvider = Provider<CollectionReference>((ref) {
  return FirebaseFirestore.instance.collection('stock_out');
});

final stockOutListProvider = FutureProvider<List<StockOut>>((ref) async {
  final collection = ref.watch(stockOutCollectionProvider);
  final snapshot = await collection.orderBy('date', descending: true).get();
  return snapshot.docs.map((doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StockOut.fromJson(data);
  }).toList();
});

final stockOutNotifierProvider = StateNotifierProvider<StockOutNotifier, List<StockOut>>((ref) {
  return StockOutNotifier(ref);
});

class StockOutNotifier extends StateNotifier<List<StockOut>> {
  final Ref ref;
  
  StockOutNotifier(this.ref) : super([]);

  Future<bool> addStockOut(StockOut stockOut) async {
    // Check stock availability
    final productRef = FirebaseFirestore.instance.collection('products').doc(stockOut.productId);
    final productDoc = await productRef.get();
    final currentStock = productDoc.data()?['stock'] ?? 0;
    
    if (currentStock < stockOut.quantity) {
      return false; // Insufficient stock
    }

    final collection = ref.read(stockOutCollectionProvider);
    await collection.doc(stockOut.id).set(stockOut.toJson());
    state = [...state, stockOut];
    
    // Update product stock
    await productRef.update({
      'stock': FieldValue.increment(-stockOut.quantity),
    });
    
    return true;
  }

  Future<void> loadStockOut() async {
    final collection = ref.read(stockOutCollectionProvider);
    final snapshot = await collection.orderBy('date', descending: true).get();
    state = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return StockOut.fromJson(data);
    }).toList();
  }
}
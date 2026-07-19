// lib/features/stock_in/presentation/providers/stock_in_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/stock_in_model.dart';

final stockInCollectionProvider = Provider<CollectionReference>((ref) {
  return FirebaseFirestore.instance.collection('stock_in');
});

final stockInListProvider = FutureProvider<List<StockIn>>((ref) async {
  final collection = ref.watch(stockInCollectionProvider);
  final snapshot = await collection.orderBy('date', descending: true).get();
  return snapshot.docs.map((doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StockIn.fromJson(data);
  }).toList();
});

final stockInNotifierProvider = StateNotifierProvider<StockInNotifier, List<StockIn>>((ref) {
  return StockInNotifier(ref);
});

class StockInNotifier extends StateNotifier<List<StockIn>> {
  final Ref ref;
  
  StockInNotifier(this.ref) : super([]);

  Future<void> addStockIn(StockIn stockIn) async {
    final collection = ref.read(stockInCollectionProvider);
    await collection.doc(stockIn.id).set(stockIn.toJson());
    state = [...state, stockIn];
    
    // Update product stock
    final productRef = FirebaseFirestore.instance.collection('products').doc(stockIn.productId);
    await productRef.update({
      'stock': FieldValue.increment(stockIn.quantity),
    });
  }

  Future<void> loadStockIn() async {
    final collection = ref.read(stockInCollectionProvider);
    final snapshot = await collection.orderBy('date', descending: true).get();
    state = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return StockIn.fromJson(data);
    }).toList();
  }
}
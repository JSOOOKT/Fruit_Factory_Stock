import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/stock_in_model.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

final stockInCollectionProvider = Provider<CollectionReference>((ref) {
  return FirebaseFirestore.instance.collection('stock_in_entries');
});

final stockInListProvider = FutureProvider<List<StockIn>>((ref) async {
  final collection = ref.watch(stockInCollectionProvider);
  final factoryId = ref.watch(currentFactoryIdProvider);
  
  final snapshot = await collection
      .where('factoryId', isEqualTo: factoryId)
      .orderBy('date', descending: true)
      .get();
      
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
    final factoryId = ref.read(currentFactoryIdProvider);
    
    // ✅ บันทึกพร้อม factoryId และ tankType
    final stockInWithFactory = StockIn(
      id: stockIn.id,
      productId: stockIn.productId,
      productName: stockIn.productName,
      productCode: stockIn.productCode,
      quantity: stockIn.quantity,
      unit: stockIn.unit,
      supplierName: stockIn.supplierName,
      tankType: stockIn.tankType, // ✅ เก็บ tankType
      tankNumber: stockIn.tankNumber,
      note: stockIn.note,
      date: stockIn.date,
      recordedBy: stockIn.recordedBy,
      factoryId: factoryId,
      createdAt: stockIn.createdAt,
    );
    
    await collection.doc(stockInWithFactory.id).set(stockInWithFactory.toJson());
    state = [...state, stockInWithFactory];
    
    // Update product stock
    final productRef = FirebaseFirestore.instance.collection('products').doc(stockIn.productId);
    await productRef.update({
      'stock': FieldValue.increment(stockIn.quantity),
    });
  }

  Future<void> loadStockIn() async {
    final collection = ref.read(stockInCollectionProvider);
    final factoryId = ref.read(currentFactoryIdProvider);
    
    final snapshot = await collection
        .where('factoryId', isEqualTo: factoryId)
        .orderBy('date', descending: true)
        .get();
        
    state = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return StockIn.fromJson(data);
    }).toList();
  }
}

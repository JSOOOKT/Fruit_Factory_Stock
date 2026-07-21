import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/stock_out_model.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

final stockOutCollectionProvider = Provider<CollectionReference>((ref) {
  return FirebaseFirestore.instance.collection('stock_out_entries');
});

final stockOutListProvider = FutureProvider<List<StockOut>>((ref) async {
  final collection = ref.watch(stockOutCollectionProvider);
  final factoryId = ref.watch(currentFactoryIdProvider);
  
  if (factoryId == null) return [];
  
  final snapshot = await collection
      .where('factoryId', isEqualTo: factoryId)
      .orderBy('date', descending: true)
      .get();
      
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
    final collection = ref.read(stockOutCollectionProvider);
    final factoryId = ref.read(currentFactoryIdProvider);
    
    // ✅ ตรวจสอบ stock จาก product (คำนวณจาก stock_in - stock_out)
    final productRef = FirebaseFirestore.instance.collection('products').doc(stockOut.productId);
    final productDoc = await productRef.get();
    final currentStock = (productDoc.data()?['stock'] as num?)?.toDouble() ?? 0;
    
    if (currentStock < stockOut.quantity) {
      return false;
    }

    // ✅ บันทึกพร้อม factoryId
    final stockOutWithFactory = StockOut(
      id: stockOut.id,
      productId: stockOut.productId,
      productName: stockOut.productName,
      productCode: stockOut.productCode,
      quantity: stockOut.quantity,
      unit: stockOut.unit,
      purpose: stockOut.purpose,
      tankType: stockOut.tankType,
      tankNumber: stockOut.tankNumber,
      note: stockOut.note,
      date: stockOut.date,
      recordedBy: stockOut.recordedBy,
      factoryId: factoryId,
      createdAt: stockOut.createdAt,
    );
    
    await collection.doc(stockOutWithFactory.id).set(stockOutWithFactory.toJson());
    state = [...state, stockOutWithFactory];
    
    // ✅ Update product stock
    await productRef.update({
      'stock': FieldValue.increment(-stockOut.quantity),
    });
    
    return true;
  }

  Future<void> loadStockOut() async {
    final collection = ref.read(stockOutCollectionProvider);
    final factoryId = ref.read(currentFactoryIdProvider);
    
    if (factoryId == null) {
      state = [];
      return;
    }
    
    final snapshot = await collection
        .where('factoryId', isEqualTo: factoryId)
        .orderBy('date', descending: true)
        .get();
        
    state = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return StockOut.fromJson(data);
    }).toList();
  }
}

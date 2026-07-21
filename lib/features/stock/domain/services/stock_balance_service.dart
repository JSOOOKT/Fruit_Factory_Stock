import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

class StockBalanceService {
  final FirebaseFirestore _firestore;
  final Logger _logger = Logger();
  
  final Map<String, _CachedBalance> _cache = {};
  static const Duration _cacheDuration = Duration(seconds: 30);

  StockBalanceService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<double> getCurrentBalance(String productCode) async {
    try {
      final cached = _cache[productCode];
      if (cached != null && !cached.isExpired) {
        return cached.balance;
      }

      final results = await Future.wait([
        _getTotalIn(productCode),
        _getTotalOut(productCode),
      ]);

      final totalIn = results[0];
      final totalOut = results[1];
      final balance = totalIn - totalOut;

      _cache[productCode] = _CachedBalance(
        balance: balance,
        timestamp: DateTime.now(),
      );

      return balance;
    } catch (e) {
      return 0.0;
    }
  }

  Future<double> _getTotalIn(String productCode) async {
    try {
      final snapshot = await _firestore
          .collection('stock_in_entries')
          .where('product_code', isEqualTo: productCode)
          .get();

      return snapshot.docs.fold<double>(
        0.0,
        (sum, doc) => sum + (doc.data()['quantity_kg'] as num).toDouble(),
      );
    } catch (e) {
      return 0.0;
    }
  }

  Future<double> _getTotalOut(String productCode) async {
    try {
      final snapshot = await _firestore
          .collection('stock_out_entries')
          .where('product_code', isEqualTo: productCode)
          .get();

      return snapshot.docs.fold<double>(
        0.0,
        (sum, doc) => sum + (doc.data()['quantity_kg'] as num).toDouble(),
      );
    } catch (e) {
      return 0.0;
    }
  }

  void invalidateCache(String productCode) {
    _cache.remove(productCode);
  }

  void clearCache() {
    _cache.clear();
  }
}

class _CachedBalance {
  final double balance;
  final DateTime timestamp;

  _CachedBalance({
    required this.balance,
    required this.timestamp,
  });

  bool get isExpired =>
      DateTime.now().difference(timestamp) > _cacheDuration;
}

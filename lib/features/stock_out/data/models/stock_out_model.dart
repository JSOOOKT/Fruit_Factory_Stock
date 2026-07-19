// lib/features/stock_out/data/models/stock_out_model.dart
class StockOut {
  final String id;
  final String productId;
  final String productName;
  final String productCode;
  final int quantity;
  final String unit;
  final String? purpose;
  final String? note;
  final DateTime date;
  final String recordedBy;
  final DateTime createdAt;

  StockOut({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productCode,
    required this.quantity,
    required this.unit,
    this.purpose,
    this.note,
    required this.date,
    required this.recordedBy,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'product_id': productId,
    'product_name': productName,
    'product_code': productCode,
    'quantity': quantity,
    'unit': unit,
    'purpose': purpose,
    'note': note,
    'date': date.toIso8601String(),
    'recorded_by': recordedBy,
    'created_at': createdAt.toIso8601String(),
  };

  factory StockOut.fromJson(Map<String, dynamic> json) => StockOut(
    id: json['id'] ?? '',
    productId: json['product_id'] ?? '',
    productName: json['product_name'] ?? '',
    productCode: json['product_code'] ?? '',
    quantity: json['quantity'] ?? 0,
    unit: json['unit'] ?? 'KG',
    purpose: json['purpose'],
    note: json['note'],
    date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
    recordedBy: json['recorded_by'] ?? '',
    createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
  );
}
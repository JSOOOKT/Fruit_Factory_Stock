class StockIn {
  final String id;
  final String productId;
  final String productName;
  final String productCode;
  final double quantity;
  final String unit;
  final String? supplierName;
  final String? tankType;
  final String? tankNumber;
  final String? note;
  final DateTime date;
  final String recordedBy;
  final String? factoryId;
  final DateTime createdAt;

  StockIn({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productCode,
    required this.quantity,
    required this.unit,
    this.supplierName,
    this.tankType,
    this.tankNumber,
    this.note,
    required this.date,
    required this.recordedBy,
    this.factoryId,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'product_id': productId,
    'product_name': productName,
    'product_code': productCode,
    'quantity': quantity,
    'unit': unit,
    'supplier_name': supplierName,
    'tank_type': tankType,
    'tank_number': tankNumber,
    'note': note,
    'date': date.toIso8601String(),
    'recorded_by': recordedBy,
    'factoryId': factoryId,
    'created_at': createdAt.toIso8601String(),
  };

  factory StockIn.fromJson(Map<String, dynamic> json) => StockIn(
    id: json['id'] ?? '',
    productId: json['product_id'] ?? '',
    productName: json['product_name'] ?? '',
    productCode: json['product_code'] ?? '',
    quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
    unit: json['unit'] ?? 'KG',
    supplierName: json['supplier_name'],
    tankType: json['tank_type'],
    tankNumber: json['tank_number'],
    note: json['note'],
    date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
    recordedBy: json['recorded_by'] ?? '',
    factoryId: json['factoryId'],
    createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
  );
}

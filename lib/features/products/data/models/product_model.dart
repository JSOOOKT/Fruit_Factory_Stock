class Product {
  final String id;
  final String name;
  final String code;
  final double stock;
  final String unit;
  final String? factoryId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.name,
    required this.code,
    this.stock = 0.0,
    this.unit = 'KG',
    this.factoryId,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'code': code,
    'stock': stock,
    'unit': unit,
    'factoryId': factoryId,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    code: json['code'] ?? '',
    stock: (json['stock'] as num?)?.toDouble() ?? 0.0,
    unit: json['unit'] ?? 'KG',
    factoryId: json['factoryId'],
    createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
  );

  Product copyWith({
    String? id,
    String? name,
    String? code,
    double? stock,
    String? unit,
    String? factoryId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      stock: stock ?? this.stock,
      unit: unit ?? this.unit,
      factoryId: factoryId ?? this.factoryId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

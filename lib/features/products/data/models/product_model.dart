class Product {
  final String id;
  final String name;
  final String code;
  final String unit;
  final int stock;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.name,
    required this.code,
    this.unit = 'KG',
    this.stock = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'code': code,
    'unit': unit,
    'stock': stock,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    code: json['code'] ?? '',
    unit: json['unit'] ?? 'KG',
    stock: json['stock'] ?? 0,
    createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
  );

  Product copyWith({
    String? id,
    String? name,
    String? code,
    String? unit,
    int? stock,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      unit: unit ?? this.unit,
      stock: stock ?? this.stock,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class Factory {
  final String id;
  final String factoryCode;
  final String name;
  final String address;
  final String phone;
  final String adminId;
  final bool isActive;
  final String password;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? logoUrl;
  final String? description;

  Factory({
    required this.id,
    required this.factoryCode,
    required this.name,
    required this.address,
    required this.phone,
    required this.adminId,
    required this.isActive,
    required this.password,
    required this.createdAt,
    required this.updatedAt,
    this.logoUrl,
    this.description,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'factoryCode': factoryCode,
    'name': name,
    'address': address,
    'phone': phone,
    'adminId': adminId,
    'isActive': isActive,
    'password': password,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'logoUrl': logoUrl,
    'description': description,
  };

  factory Factory.fromJson(Map<String, dynamic> json) => Factory(
    id: json['id'] ?? '',
    factoryCode: json['factoryCode'] ?? '',
    name: json['name'] ?? '',
    address: json['address'] ?? '',
    phone: json['phone'] ?? '',
    adminId: json['adminId'] ?? '',
    isActive: json['isActive'] ?? true,
    password: json['password'] ?? '',
    createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    logoUrl: json['logoUrl'],
    description: json['description'],
  );

  Factory copyWith({
    String? id,
    String? factoryCode,
    String? name,
    String? address,
    String? phone,
    String? adminId,
    bool? isActive,
    String? password,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? logoUrl,
    String? description,
  }) {
    return Factory(
      id: id ?? this.id,
      factoryCode: factoryCode ?? this.factoryCode,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      adminId: adminId ?? this.adminId,
      isActive: isActive ?? this.isActive,
      password: password ?? this.password,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      logoUrl: logoUrl ?? this.logoUrl,
      description: description ?? this.description,
    );
  }
}

class Tank {
  final String id;
  final String factoryId;
  final String tankType;
  final String? tankNumber;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Tank({
    required this.id,
    required this.factoryId,
    required this.tankType,
    this.tankNumber,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'factoryId': factoryId,
    'tankType': tankType,
    'tankNumber': tankNumber,
    'isActive': isActive,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Tank.fromJson(Map<String, dynamic> json) => Tank(
    id: json['id'] ?? '',
    factoryId: json['factoryId'] ?? '',
    tankType: json['tankType'] ?? '',
    tankNumber: json['tankNumber'],
    isActive: json['isActive'] ?? true,
    createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
  );

  Tank copyWith({
    String? id,
    String? factoryId,
    String? tankType,
    String? tankNumber,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Tank(
      id: id ?? this.id,
      factoryId: factoryId ?? this.factoryId,
      tankType: tankType ?? this.tankType,
      tankNumber: tankNumber ?? this.tankNumber,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

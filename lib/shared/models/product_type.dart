import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_type.freezed.dart';
part 'product_type.g.dart';

@freezed
class ProductType with _$ProductType {
  const ProductType._();

  const factory ProductType({
    required String productCode,
    required String nameEn,
    required String nameTh,
    required String unit, // Default: 'KG'
    required bool active,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? description,
  }) = _ProductType;

  factory ProductType.fromJson(Map<String, dynamic> json) =>
      _$ProductTypeFromJson(json);

  String getName(String languageCode) {
    return languageCode == 'th' ? nameTh : nameEn;
  }
}

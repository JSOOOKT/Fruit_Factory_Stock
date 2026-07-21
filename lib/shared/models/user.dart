import 'package:freezed_annotation/freezed_annotation.dart';
import '../../core/enums/user_role.dart';
import '../../core/enums/language.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
class User with _$User {
  const User._();

  const factory User({
    required String uid,
    required String name,
    required String email,
    required UserRole role,
    required Language preferredLanguage,
    required bool active,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? lastLoginAt,
    String? phoneNumber,
    String? department,
    String? factoryId, // เพิ่ม factoryId
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  bool get isAdmin => role == UserRole.admin;
  bool get isManager => role == UserRole.manager || isAdmin;

  String getDisplayName(String lang) {
    return preferredLanguage == Language.th ? 'คุณ$name' : name;
  }
}

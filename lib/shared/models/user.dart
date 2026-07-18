import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
class User with _$User {
  const User._();

  const factory User({
    required String uid,
    required String name,
    required String email,
    required String role, // 'recorder', 'supervisor', 'manager', 'admin'
    required String preferredLanguage, // 'th', 'en'
    required bool active,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? lastLoginAt,
    String? phoneNumber,
    String? department,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  bool get isAdmin => role == 'admin';
  bool get isManager => role == 'manager' || isAdmin;
  bool get isSupervisor => role == 'supervisor' || isManager;
}

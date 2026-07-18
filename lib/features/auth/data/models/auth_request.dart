import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_request.freezed.dart';
part 'auth_request.g.dart';

@freezed
class LoginRequest with _$LoginRequest {
  const LoginRequest._();

  const factory LoginRequest({
    required String email,
    required String password,
  }) = _LoginRequest;

  factory LoginRequest.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestFromJson(json);
}

@freezed
class SignUpRequest with _$SignUpRequest {
  const SignUpRequest._();

  const factory SignUpRequest({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String role, // 'recorder', 'supervisor', 'manager'
    required String preferredLanguage, // 'th', 'en'
  }) = _SignUpRequest;

  factory SignUpRequest.fromJson(Map<String, dynamic> json) =>
      _$SignUpRequestFromJson(json);

  bool get passwordsMatch => password == passwordConfirmation;
}

@freezed
class ResetPasswordRequest with _$ResetPasswordRequest {
  const ResetPasswordRequest._();

  const factory ResetPasswordRequest({
    required String email,
  }) = _ResetPasswordRequest;

  factory ResetPasswordRequest.fromJson(Map<String, dynamic> json) =>
      _$ResetPasswordRequestFromJson(json);
}

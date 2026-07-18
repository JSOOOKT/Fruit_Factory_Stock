import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fruit_factory_stock/shared/models/user.dart';

part 'auth_response.freezed.dart';
part 'auth_response.g.dart';

@freezed
class AuthResponse with _$AuthResponse {
  const AuthResponse._();

  const factory AuthResponse({
    required User user,
    required String token,
  }) = _AuthResponse;

  factory AuthResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseFromJson(json);
}

@freezed
class AuthState with _$AuthState {
  const AuthState._();

  const factory AuthState.initial() = AuthInitial;
  
  const factory AuthState.loading() = AuthLoading;
  
  const factory AuthState.authenticated({
    required User user,
    required String token,
  }) = AuthAuthenticated;
  
  const factory AuthState.unauthenticated({
    required String? message,
  }) = AuthUnauthenticated;
  
  const factory AuthState.error({
    required String message,
  }) = AuthError;

  bool get isAuthenticated => this is AuthAuthenticated;
  bool get isLoading => this is AuthLoading;
  bool get isError => this is AuthError;

  User? get user => mapOrNull(authenticated: (state) => state.user);
  String? get token => mapOrNull(authenticated: (state) => state.token);
}

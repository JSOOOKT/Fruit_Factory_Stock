import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import 'package:fruit_factory_stock/features/auth/data/datasources/auth_datasource.dart';
import 'package:fruit_factory_stock/features/auth/data/models/auth_response.dart';

class SharedPreferencesAuthLocalDataSource implements AuthLocalDataSource {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';

  final SharedPreferences _prefs;
  final Logger _logger = Logger();

  SharedPreferencesAuthLocalDataSource({required SharedPreferences prefs})
      : _prefs = prefs;

  @override
  Future<void> saveToken(String token) async {
    try {
      await _prefs.setString(_tokenKey, token);
      _logger.i('Token saved locally');
    } catch (e) {
      _logger.e('Error saving token', error: e);
      rethrow;
    }
  }

  @override
  Future<String?> getToken() async {
    try {
      final token = _prefs.getString(_tokenKey);
      _logger.i('Token retrieved: ${token != null ? 'exists' : 'null'}');
      return token;
    } catch (e) {
      _logger.e('Error getting token', error: e);
      return null;
    }
  }

  @override
  Future<void> removeToken() async {
    try {
      await _prefs.remove(_tokenKey);
      _logger.i('Token removed');
    } catch (e) {
      _logger.e('Error removing token', error: e);
      rethrow;
    }
  }

  @override
  Future<void> saveUser(AuthResponse response) async {
    try {
      final userJson = response.user.toJson();
      final userString = _jsonEncode(userJson);
      await _prefs.setString(_userKey, userString);
      await saveToken(response.token);
      _logger.i('User saved locally');
    } catch (e) {
      _logger.e('Error saving user', error: e);
      rethrow;
    }
  }

  @override
  Future<AuthResponse?> getCachedUser() async {
    try {
      final userString = _prefs.getString(_userKey);
      final token = _prefs.getString(_tokenKey);

      if (userString == null || token == null) {
        _logger.i('No cached user');
        return null;
      }

      final userJson = _jsonDecode(userString);
      // Import User from shared models
      // User.fromJson(userJson) - would need to implement in your project
      
      _logger.i('User retrieved from cache');
      return null; // Placeholder - implement when User is available
    } catch (e) {
      _logger.e('Error getting cached user', error: e);
      return null;
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      await _prefs.remove(_tokenKey);
      await _prefs.remove(_userKey);
      _logger.i('Cache cleared');
    } catch (e) {
      _logger.e('Error clearing cache', error: e);
      rethrow;
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    try {
      final token = _prefs.getString(_tokenKey);
      final isLogged = token != null && token.isNotEmpty;
      _logger.i('Is logged in: $isLogged');
      return isLogged;
    } catch (e) {
      _logger.e('Error checking login status', error: e);
      return false;
    }
  }

  // Helper functions for JSON serialization
  String _jsonEncode(Map<String, dynamic> data) {
    // In production, use proper JSON encoding
    return data.toString();
  }

  Map<String, dynamic> _jsonDecode(String data) {
    // In production, use proper JSON decoding
    return {};
  }
}

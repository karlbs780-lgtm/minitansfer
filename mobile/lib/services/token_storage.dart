import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the JWT and a cached copy of the user profile in the platform's
/// secure storage (Keystore on Android, Keychain on iOS).
class TokenStorage {
  static const _tokenKey = 'jwt_token';
  static const _userKey = 'auth_user';

  final FlutterSecureStorage _storage;

  TokenStorage([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  Future<void> saveToken(String token) => _storage.write(key: _tokenKey, value: token);

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<void> saveUser(String userJson) => _storage.write(key: _userKey, value: userJson);

  Future<String?> readUser() => _storage.read(key: _userKey);

  Future<void> clear() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
  }
}

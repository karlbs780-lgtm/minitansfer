import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../models/auth_result.dart';
import '../services/auth_api.dart';
import '../services/token_storage.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

/// Owns the authentication state: the current user, the persisted JWT, and the
/// login/register/logout transitions. UI reacts to [status].
class AuthProvider extends ChangeNotifier {
  final AuthApi _authApi;
  final TokenStorage _tokenStorage;

  AuthProvider({required AuthApi authApi, required TokenStorage tokenStorage})
      : _authApi = authApi,
        _tokenStorage = tokenStorage;

  AuthStatus _status = AuthStatus.unknown;
  AppUser? _user;
  bool _submitting = false;

  AuthStatus get status => _status;
  AppUser? get user => _user;
  bool get submitting => _submitting;

  /// Restores a session from secure storage at startup (used by the splash gate).
  Future<void> tryAutoLogin() async {
    final token = await _tokenStorage.readToken();
    final userJson = await _tokenStorage.readUser();
    if (token != null && token.isNotEmpty && userJson != null) {
      try {
        _user = AppUser.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
        _status = AuthStatus.authenticated;
      } catch (_) {
        await _tokenStorage.clear();
        _status = AuthStatus.unauthenticated;
      }
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<void> login({required String email, required String password}) async {
    _setSubmitting(true);
    try {
      final result = await _authApi.login(email: email.trim(), password: password);
      await _persistSession(result);
    } finally {
      _setSubmitting(false);
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    _setSubmitting(true);
    try {
      final result = await _authApi.register(
        name: name.trim(),
        email: email.trim(),
        phone: phone.trim(),
        password: password,
      );
      await _persistSession(result);
    } finally {
      _setSubmitting(false);
    }
  }

  Future<void> logout() async {
    await _tokenStorage.clear();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// Keeps the cached profile in sync when the balance changes elsewhere.
  void updateBalance(int balance) {
    final current = _user;
    if (current == null) return;
    _user = current.copyWith(balance: balance);
    _tokenStorage.saveUser(jsonEncode(_user!.toJson()));
    notifyListeners();
  }

  Future<void> _persistSession(AuthResult result) async {
    await _tokenStorage.saveToken(result.token);
    await _tokenStorage.saveUser(jsonEncode(result.user.toJson()));
    _user = result.user;
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  void _setSubmitting(bool value) {
    _submitting = value;
    notifyListeners();
  }
}

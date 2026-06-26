import 'app_user.dart';

/// Result of a successful register/login call: the JWT and the user profile.
class AuthResult {
  final String token;
  final int expiresInMs;
  final AppUser user;

  const AuthResult({
    required this.token,
    required this.expiresInMs,
    required this.user,
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      token: json['token'] as String,
      expiresInMs: (json['expiresInMs'] as num?)?.toInt() ?? 0,
      user: AppUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

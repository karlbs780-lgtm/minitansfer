import '../models/auth_result.dart';
import 'api_client.dart';

class AuthApi {
  final ApiClient client;

  AuthApi(this.client);

  Future<AuthResult> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final json = await client.post('/api/auth/register', authenticated: false, body: {
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
    });
    return AuthResult.fromJson(json as Map<String, dynamic>);
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final json = await client.post('/api/auth/login', authenticated: false, body: {
      'email': email,
      'password': password,
    });
    return AuthResult.fromJson(json as Map<String, dynamic>);
  }
}

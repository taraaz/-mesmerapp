import 'api_client.dart';

class AuthService {
  final ApiClient _client = ApiClient.instance;

  Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final response = await _client.dio.post(
      '/auth/login',
      data: {
        'email': email,
        'password': password,
      },
    );

    final data = Map<String, dynamic>.from(response.data);

    await _client.saveToken(data['accessToken'] as String);

    return Map<String, dynamic>.from(
      data['user'] as Map,
    );
  }

  Future<Map<String, dynamic>> getMe() async {
    final response = await _client.dio.get('/auth/me');

    return Map<String, dynamic>.from(response.data);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _client.dio.patch(
      '/auth/change-password',
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
  }

  Future<String?> readToken() {
    return _client.readToken();
  }

  Future<void> logout() {
    return _client.clearToken();
  }
}

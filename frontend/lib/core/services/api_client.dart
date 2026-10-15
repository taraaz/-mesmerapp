import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../app/router/app_router.dart';

/// Single shared HTTP client for the whole app. Attaches the signed-in
/// user's JWT to every outgoing request and clears the session (routing
/// back to Login) if the server ever responds with 401 Unauthorized.
class ApiClient {
  ApiClient._internal() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: _tokenKey);

          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            await clearToken();
            AppRouter.router.go('/');
          }

          handler.next(error);
        },
      ),
    );
  }

  static final ApiClient instance = ApiClient._internal();

  // Set at build time for hosted builds:
  // flutter build web --dart-define=API_URL=https://your-backend.example
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:3000',
  );
  static const String _tokenKey = 'auth_token';

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  );

  final FlutterSecureStorage _storage =
      const FlutterSecureStorage();

  Dio get dio => _dio;

  Future<void> saveToken(String token) {
    return _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> readToken() {
    return _storage.read(key: _tokenKey);
  }

  Future<void> clearToken() {
    return _storage.delete(key: _tokenKey);
  }
}

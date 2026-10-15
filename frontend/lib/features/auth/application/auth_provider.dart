import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/auth_service.dart';
import '../domain/app_user.dart';

class AuthState {
  final AppUser? user;
  final bool isLoading;

  const AuthState({
    this.user,
    this.isLoading = false,
  });

  AuthState copyWith({
    AppUser? user,
    bool? isLoading,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  final AuthService _authService = AuthService();

  /// Called once at app startup: if a token is already stored, validates
  /// it against the server and restores the session. Returns whether a
  /// session was restored.
  Future<bool> tryRestoreSession() async {
    final token = await _authService.readToken();

    if (token == null) {
      return false;
    }

    try {
      final profile = await _authService.getMe();
      state = state.copyWith(user: AppUser.fromJson(profile));
      return true;
    } catch (_) {
      await _authService.logout();
      return false;
    }
  }

  /// Attempts to sign in. Returns null on success, or an error message
  /// to display to the user.
  Future<String?> login(String email, String password) async {
    state = state.copyWith(isLoading: true);

    try {
      final profile = await _authService.login(email, password);
      state = AuthState(user: AppUser.fromJson(profile));
      return null;
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false);
      return _extractMessage(e) ?? 'Could not sign in.';
    } catch (e) {
      state = state.copyWith(isLoading: false);
      return 'Could not sign in: $e';
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    state = const AuthState();
  }

  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return null;
    } on DioException catch (e) {
      return _extractMessage(e) ?? 'Could not change password.';
    }
  }

  String? _extractMessage(DioException e) {
    final data = e.response?.data;

    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }

    return null;
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);

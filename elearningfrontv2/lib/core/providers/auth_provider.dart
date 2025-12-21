// lib/core/providers/auth_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../utils/secure_storage.dart';

class AuthState {
  final bool isAuthenticated;
  final Map<String, dynamic>? user;
  final String? token;
  final String? error;

  AuthState({
    required this.isAuthenticated,
    this.user,
    this.token,
    this.error,
  });

  factory AuthState.initial() => AuthState(
        isAuthenticated: false,
        user: null,
        token: null,
        error: null,
      );

  AuthState copyWith({
    bool? isAuthenticated,
    Map<String, dynamic>? user,
    String? token,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      token: token ?? this.token,
      error: error,
    );
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState.initial());

  /// LOGIN
  Future<void> login(String email, String password) async {
    final result = await AuthService.instance.login(
      email: email,
      password: password,
    );

    if (result["success"] == true) {
      final Map<String, dynamic>? user = result["user"] is Map ? Map<String, dynamic>.from(result["user"]) : null;
      final String? token = result["token"] as String?;

      // save only if non-null
      if (token != null && token.isNotEmpty) await SecureStorage.saveToken(token);
      if (user != null) await SecureStorage.saveUser(user);

      state = state.copyWith(
        isAuthenticated: true,
        user: user,
        token: token,
        error: null,
      );
    } else {
      state = state.copyWith(
        isAuthenticated: false,
        error: result["error"]?.toString(),
      );
    }
  }

  /// REGISTER
  Future<void> register({
    required String nom,
    required String email,
    required String password,
    String? role,
  }) async {
    final result = await AuthService.instance.register(
      nom: nom,
      email: email,
      password: password,
      role: role,
    );

    if (result["success"] == true) {
      final Map<String, dynamic>? user = result["user"] is Map ? Map<String, dynamic>.from(result["user"]) : null;
      final String? token = result["token"] as String?;

      if (token != null && token.isNotEmpty) await SecureStorage.saveToken(token);
      if (user != null) await SecureStorage.saveUser(user);

      state = state.copyWith(
        isAuthenticated: true,
        user: user,
        token: token,
        error: null,
      );
    } else {
      state = state.copyWith(
        isAuthenticated: false,
        error: result["error"]?.toString(),
      );
    }
  }

  /// Load user + token at startup
  Future<void> loadFromStorage() async {
    try {
      final token = await SecureStorage.readToken();
      final savedUser = await SecureStorage.readUser();

      if (token != null && token.isNotEmpty) {
        // Attempt to refresh /me if backend accessible
        final response = await AuthService.instance.me();
        if (response["success"] == true && response["user"] != null) {
          final Map<String, dynamic>? freshUser = response["user"] is Map ? Map<String, dynamic>.from(response["user"]) : null;
          // persist fresh user
          if (freshUser != null) await SecureStorage.saveUser(freshUser);

          state = state.copyWith(
            isAuthenticated: true,
            user: freshUser ?? savedUser,
            token: token,
            error: null,
          );
          return;
        }

        // fallback to saved user if /me failed
        if (savedUser != null) {
          state = state.copyWith(
            isAuthenticated: true,
            user: savedUser,
            token: token,
            error: null,
          );
        }
      }
    } catch (e) {
      // keep initial state on error
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> logout() async {
    await AuthService.instance.logout();
    // clear storage and reset state
    await SecureStorage.deleteToken();
    await SecureStorage.deleteUser();
    state = AuthState.initial();
  }
}

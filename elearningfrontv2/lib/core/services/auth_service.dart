// lib/core/services/auth_service.dart

import 'package:dio/dio.dart';
import 'api_client.dart';
import '../constants/api_constants.dart';
import '../utils/secure_storage.dart';

class AuthService {
  AuthService._();
  static final instance = AuthService._();

  final Dio _dio = ApiClient().dio;

  // ----------------------------------------------------------
  // LOGIN
  // ----------------------------------------------------------
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.login,
        data: {"email": email, "password": password},
      );

      final data = response.data;

      final String? token =
          (data != null && data['token'] != null) ? data['token'].toString() : null;

      final Map<String, dynamic>? user =
          (data != null && data['user'] != null)
              ? Map<String, dynamic>.from(data['user'])
              : null;

      if (token != null && token.isNotEmpty) {
        await SecureStorage.saveToken(token);
      }
      if (user != null) {
        await SecureStorage.saveUser(user);
      }

      return {
        "success": true,
        "user": user,
        "token": token,
      };
    } on DioException catch (e) {
      final dynamic msg = e.response?.data ?? e.message;
      final String error = _normalizeErrorMessage(msg);
      return {"success": false, "error": error};
    } catch (e) {
      return {"success": false, "error": e.toString()};
    }
  }

  // ----------------------------------------------------------
  // REGISTER
  // ----------------------------------------------------------
  Future<Map<String, dynamic>> register({
    required String nom,
    required String email,
    required String password,
    String? role,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.register,
        data: {
          "nom": nom,
          "email": email,
          "password": password,
          if (role != null) "role": role,
        },
      );

      final data = response.data;

      final String? token =
          (data != null && data['token'] != null) ? data['token'].toString() : null;

      final Map<String, dynamic>? user =
          (data != null && data['user'] != null)
              ? Map<String, dynamic>.from(data['user'])
              : null;

      if (token != null && token.isNotEmpty) {
        await SecureStorage.saveToken(token);
      }
      if (user != null) {
        await SecureStorage.saveUser(user);
      }

      return {
        "success": true,
        "user": user,
        "token": token,
      };
    } on DioException catch (e) {
      final dynamic msg = e.response?.data ?? e.message;
      final String error = _normalizeErrorMessage(msg);
      return {"success": false, "error": error};
    } catch (e) {
      return {"success": false, "error": e.toString()};
    }
  }

  // ----------------------------------------------------------
  // GET /me
  // ----------------------------------------------------------
  Future<Map<String, dynamic>> me() async {
    try {
      final response = await _dio.get(ApiConstants.me);

      final data = response.data;

      final Map<String, dynamic>? user =
          (data is Map) ? Map<String, dynamic>.from(data) : null;

      if (user != null) {
        await SecureStorage.saveUser(user);
      }

      return {"success": true, "user": user};
    } on DioException catch (e) {
      final dynamic msg = e.response?.data ?? e.message;
      final String error = _normalizeErrorMessage(msg);
      return {"success": false, "error": error};
    } catch (e) {
      return {"success": false, "error": e.toString()};
    }
  }

  // ----------------------------------------------------------
  // LOGOUT
  // ----------------------------------------------------------
  Future<void> logout() async {
    await SecureStorage.deleteToken();
    await SecureStorage.deleteUser();
  }

  // ----------------------------------------------------------
  // ERROR NORMALIZER
  // ----------------------------------------------------------
  String _normalizeErrorMessage(dynamic serverMsg) {
    if (serverMsg == null) return "Erreur réseau inconnue";

    // If message is already a string
    if (serverMsg is String) return serverMsg;

    // If backend returned JSON {message: "..."}
    if (serverMsg is Map) {
      if (serverMsg.containsKey("message")) {
        return serverMsg["message"].toString();
      }
      if (serverMsg.containsKey("error")) {
        return serverMsg["error"].toString();
      }
      return serverMsg.toString();
    }

    // Fallback
    return serverMsg.toString();
  }
}

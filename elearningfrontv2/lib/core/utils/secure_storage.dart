// lib/core/utils/secure_storage.dart
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static final _storage = const FlutterSecureStorage();
  static const _keyToken = 'jwt_token';
  static const _keyUser = 'user_json';

  // Token
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _keyToken, value: token);
  }

  static Future<String?> readToken() async {
    return await _storage.read(key: _keyToken);
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: _keyToken);
  }

  // User (JSON) — useful to persist user.id, role, name, email, etc.
  static Future<void> saveUser(Map<String, dynamic> user) async {
    if (user == null) return;
    await _storage.write(key: _keyUser, value: jsonEncode(user));
  }

  static Future<Map<String, dynamic>?> readUser() async {
    final s = await _storage.read(key: _keyUser);
    if (s == null || s.isEmpty) return null;
    try {
      final data = jsonDecode(s);
      if (data is Map) {
        return Map<String, dynamic>.from(data as Map);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> deleteUser() async {
    await _storage.delete(key: _keyUser);
  }
}

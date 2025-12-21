import 'dart:convert';
import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../utils/secure_storage.dart';

class SessionService {
  SessionService._();
  static final instance = SessionService._();

  // 🔐 Authorization header
  Future<Map<String, String>> _authHeaders() async {
    final token = await SecureStorage.readToken();
    if (token == null || token.isEmpty) {
      throw Exception('Utilisateur non authentifié');
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // 🚀 NOUVELLE MÉTHODE : Enregistrement de la frustration
  // Appelé périodiquement pendant que l'élève étudie
  Future<void> recordFrustrationMetric({
    required String sessionId,
    required double score,
  }) async {
    final headers = await _authHeaders();

    final res = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/api/sessions/frustration-metric'),
      headers: headers,
      body: json.encode({
        'sessionId': sessionId,
        'score': score,
        'timestamp': DateTime.now().toIso8601String(),
      }),
    );

    // Note: Le backend renvoie 201 Created
    if (res.statusCode != 201) {
      throw Exception('Erreur enregistrement métrique (${res.statusCode})');
    }
  }

  // ▶️ START SESSION
  Future<void> startSession({
    required int enrollmentId,
  }) async {
    final headers = await _authHeaders();

    final res = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/api/sessions/start'),
      headers: headers,
      body: json.encode({
        'enrollmentId': enrollmentId,
      }),
    );

    // Correction : Le backend renvoie souvent 200 OK ou 201 Created
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception(
        'Erreur démarrage session (${res.statusCode}) : ${res.body}',
      );
    }
  }

  // ⏱️ UPDATE SESSION TIME
  Future<void> updateTime({
    required String sessionId,
    required int durationSeconds,
  }) async {
    final headers = await _authHeaders();

    final res = await http.put(
      Uri.parse('${ApiConstants.baseUrl}/api/sessions/$sessionId/time'),
      headers: headers,
      body: json.encode({
        'durationSeconds': durationSeconds,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception(
        'Erreur sauvegarde temps (${res.statusCode}) : ${res.body}',
      );
    }
  }

  // ⏹️ END SESSION
  Future<void> endSession({
    required String sessionId,
  }) async {
    final headers = await _authHeaders();

    final res = await http.put(
      Uri.parse('${ApiConstants.baseUrl}/api/sessions/$sessionId/end'),
      headers: headers,
    );

    if (res.statusCode != 200) {
      throw Exception(
        'Erreur fin de session (${res.statusCode}) : ${res.body}',
      );
    }
  }

  // 📥 GET MY SESSIONS
  Future<List<Map<String, dynamic>>> getMySessions({
    bool activeOnly = false,
  }) async {
    final headers = await _authHeaders();

    final res = await http.get(
      Uri.parse(
        '${ApiConstants.baseUrl}/api/sessions/my?activeOnly=$activeOnly',
      ),
      headers: headers,
    );

    if (res.statusCode == 200) {
      final List data = json.decode(res.body);
      return data.cast<Map<String, dynamic>>();
    }

    throw Exception(
      'Erreur chargement sessions (${res.statusCode}) : ${res.body}',
    );
  }

  // 🔍 GET ACTIVE SESSION
  Future<Map<String, dynamic>?> getActiveSession() async {
    final headers = await _authHeaders();

    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/api/sessions/active'),
      headers: headers,
    );

    if (res.statusCode == 200) {
      return json.decode(res.body);
    }

    if (res.statusCode == 204) {
      return null;
    }

    throw Exception(
      'Erreur récupération session active (${res.statusCode})',
    );
  }

  // 📊 GET SESSIONS FOR TEACHER MONITORING
  Future<List<Map<String, dynamic>>> getTeacherDashboardStats() async {
    final headers = await _authHeaders();

    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/api/sessions/teacher/monitor'),
      headers: headers,
    );

    if (res.statusCode == 200) {
      final List data = json.decode(res.body);
      return data.cast<Map<String, dynamic>>();
    }

    throw Exception(
      'Erreur chargement dashboard (${res.statusCode}) : ${res.body}',
    );
  }
}
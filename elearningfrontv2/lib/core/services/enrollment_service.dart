import 'dart:convert';
import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../utils/secure_storage.dart';

class EnrollmentService {
  EnrollmentService._();
  static final instance = EnrollmentService._();

  // ---------------- PRIVATE ----------------
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

  // ---------------- ENROLL ----------------
  Future<void> enroll({
    required int courseId,
  }) async {
    final headers = await _authHeaders();

    final res = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/api/enrollments'),
      headers: headers,
      body: json.encode({
        'courseId': courseId,
      }),
    );

    if (res.statusCode != 201) {
      throw Exception(
        'Erreur inscription (${res.statusCode}) : ${res.body}',
      );
    }
  }

  // ---------------- GET MY ENROLLMENTS ----------------
  Future<List<Map<String, dynamic>>> getMyEnrollments() async {
    final headers = await _authHeaders();

    final res = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/api/enrollments/my'),
      headers: headers,
    );

    if (res.statusCode == 200) {
      final List data = json.decode(res.body);
      return data.cast<Map<String, dynamic>>();
    }

    throw Exception(
      'Erreur chargement enrollments (${res.statusCode}) : ${res.body}',
    );
  }

  // ---------------- UNENROLL ----------------
  Future<void> unenroll({
    required int enrollmentId,
  }) async {
    final headers = await _authHeaders();

    final res = await http.delete(
      Uri.parse(
        '${ApiConstants.baseUrl}/api/enrollments/$enrollmentId',
      ),
      headers: headers,
    );

    if (res.statusCode != 204) {
      throw Exception(
        'Erreur désinscription (${res.statusCode}) : ${res.body}',
      );
    }
  }
}

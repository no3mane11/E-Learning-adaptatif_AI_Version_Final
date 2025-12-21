import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../utils/secure_storage.dart';

class QuizService {
  QuizService._();
  static final instance = QuizService._();

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

  // ---------------- LIST BY LESSON ----------------
  Future<List<Map<String, dynamic>>> getByLesson({
    required int lessonId,
  }) async {
    final headers = await _authHeaders();

    final res = await http.get(
      Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.quizzes}/lesson/$lessonId',
      ),
      headers: headers,
    );

    if (res.statusCode == 200) {
      final List data = json.decode(res.body);
      return data.cast<Map<String, dynamic>>();
    }

    throw Exception(
      'Erreur chargement quiz (${res.statusCode}) : ${res.body}',
    );
  }

  // ---------------- CREATE ----------------
  Future<void> create({
    required int lessonId,
    required String question,
    required List<String> choices,
    required int correctAnswer,
  }) async {
    final headers = await _authHeaders();

    final res = await http.post(
      Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.quizzes}?lessonId=$lessonId',
      ),
      headers: headers,
      body: json.encode({
        'question': question,
        'choices': choices,
        'correctAnswer': correctAnswer,
      }),
    );

    if (res.statusCode != 201) {
      throw Exception(
        'Erreur création quiz (${res.statusCode}) : ${res.body}',
      );
    }
  }
  
  // ---------------- SUBMIT ANSWERS ---------------- ⬅️ NOUVELLE MÉTHODE
  Future<void> submitAnswers({
    required String sessionId, // Requis par le backend
    required int lessonId, 
    required Map<int, int?> answers, // {quizId: selectedChoiceIndex}
  }) async {
    final headers = await _authHeaders();

    final res = await http.post(
      Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.quizzes}/submit-answers', // Endpoint du Controller Java
      ),
      headers: headers,
      body: json.encode({
        'sessionId': sessionId,
        'lessonId': lessonId,
        // Conversion de la Map Dart en List<Map> JSON pour correspondre au DTO Java (SubmitQuizRequest)
        'answers': answers.entries.map((e) => {
          'quizId': e.key,
          'selectedChoiceIndex': e.value,
        }).toList(),
      }),
    );

    // Le backend renvoie 200 OK ou 204 No Content en cas de succès
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception(
        'Erreur soumission quiz (${res.statusCode}) : ${res.body}',
      );
    }
  }

  // ---------------- DELETE ----------------
  Future<void> delete({
    required int id,
  }) async {
    final headers = await _authHeaders();

    final res = await http.delete(
      Uri.parse(
        '${ApiConstants.baseUrl}${ApiConstants.quizzes}/$id',
      ),
      headers: headers,
    );

    if (res.statusCode != 204) {
      throw Exception(
        'Erreur suppression quiz (${res.statusCode}) : ${res.body}',
      );
    }
  }
}
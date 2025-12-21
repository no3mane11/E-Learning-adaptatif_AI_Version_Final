// lib/services/frustration_api_service.dart

import 'dart:convert';
import 'package:dio/dio.dart';

class FrustrationAPIService {
  final Dio _dio;
  final String baseUrl; 

  static const String _apiPath = '/api/sessions';

  FrustrationAPIService(this._dio, {required this.baseUrl});

  /// Envoie la métrique de frustration au backend.
  Future<void> submitFrustrationMetric({
    required String sessionId,
    required double score,
    required String userToken,
  }) async {
    final Map<String, dynamic> body = {
      'sessionId': sessionId,
      'score': score,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    };

    // Construction de l'URL complète : baseUrl + _apiPath + path spécifique
    final String fullUrl = '${this.baseUrl}$_apiPath/frustration-metric';

    try {
      final response = await _dio.post(
        fullUrl,
        data: body,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $userToken',
          },
        ),
      );

      // Si le statut est entre 200 et 299, passez. Dio gère déjà les non-2xx
      if (response.statusCode != 201) {
        print('Erreur API Frustration: ${response.statusCode}, ${response.data}');
        // Si ce n'est pas un 201 (Created), nous considérons que c'est une erreur logique.
        throw DioException(
          requestOptions: response.requestOptions,
          message: 'Failed to submit metric with status: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      // 🎯 CORRECTION: Nous catchons l'exception (y compris les 500)
      // et nous nous contentons de la loguer. Le `rethrow` est supprimé
      // pour éviter le crash de l'application dû au Timer.
      print('Erreur Dio lors de l\'envoi de métrique: ${e.message}');
    }
  }

  /// Appeler cette méthode lorsque l'utilisateur quitte la leçon.
  Future<void> endSession({
    required String sessionId,
    required String userToken,
  }) async {
    // Construction de l'URL complète : baseUrl + _apiPath + path spécifique
    final String fullUrl = '${this.baseUrl}$_apiPath/$sessionId/end';

    try {
      await _dio.put(
        fullUrl,
        options: Options(
          headers: {'Authorization': 'Bearer $userToken'},
        ),
      );
    } on DioException catch (e) {
      // ⚠️ IMPORTANT: Nous GARDONS le rethrow ici car la fin de session est
      // une action critique et l'appelant DOIT être informé de l'échec.
      print('Erreur Dio lors de la fin de session: ${e.message}');
      rethrow;
    }
  }
}
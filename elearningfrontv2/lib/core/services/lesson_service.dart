import 'package:dio/dio.dart';
import 'api_client.dart';
import '../constants/api_constants.dart';

class LessonService {
  LessonService._();
  static final instance = LessonService._();

  final Dio _dio = ApiClient().dio;

  // -----------------------------
  // LIST LESSONS BY COURSE
  // -----------------------------
  Future<List<Map<String, dynamic>>> getLessonsByCourse(int courseId) async {
    final res = await _dio.get(
      '${ApiConstants.lessons}/course/$courseId',
    );

    final data = res.data;
    if (data is List) {
      return List<Map<String, dynamic>>.from(data);
    }
    return [];
  }

  // -----------------------------
  // CREATE
  // -----------------------------
  Future<void> createLesson({
    required int courseId,
    required String titre,
    required String typeContenu,
    required int ordre,
    String? contenu, // THEORY only
  }) async {
    await _dio.post(
      ApiConstants.lessons,
      data: {
        "courseId": courseId,
        "titre": titre,
        "typeContenu": typeContenu,
        "ordre": ordre,
        if (contenu != null) "contenu": contenu,
      },
    );
  }

  // -----------------------------
  // UPDATE
  // -----------------------------
  Future<void> updateLesson({
    required int id,
    required int courseId,
    required String titre,
    required String typeContenu,
    required int ordre,
    String? contenu,
  }) async {
    await _dio.put(
      '${ApiConstants.lessons}/$id',
      data: {
        "courseId": courseId,
        "titre": titre,
        "typeContenu": typeContenu,
        "ordre": ordre,
        if (contenu != null) "contenu": contenu,
      },
    );
  }
   // UPLOAD VIDEO
  // -----------------------------
  Future<void> uploadVideo({
    required int lessonId,
    required String filePath,
  }) async {
    final fileName = filePath.split('/').last;

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        filePath,
        filename: fileName,
      ),
    });

    await _dio.post(
      '${ApiConstants.lessons}/$lessonId/video',
      data: formData,
    );
  }

  // -----------------------------
  // DELETE
  // -----------------------------
  Future<void> deleteLesson(int id) async {
    await _dio.delete('${ApiConstants.lessons}/$id');
  }
}

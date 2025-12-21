import 'package:dio/dio.dart';
import 'api_client.dart';
import '../constants/api_constants.dart';

class CourseService {
  CourseService._();
  static final instance = CourseService._();

  final Dio _dio = ApiClient().dio;

  // ----------------------------
  // LIST COURSES (Page<CourseDTO>)
  // ----------------------------
  Future<List<Map<String, dynamic>>> getAllCourses() async {
    final response = await _dio.get(ApiConstants.courses);

    print("RAW /api/courses RESPONSE = ${response.data}");

    final data = response.data;
    if (data is Map && data['content'] is List) {
      return List<Map<String, dynamic>>.from(data['content']);
    }
    return [];
  }

  // ----------------------------
  // GET LESSONS BY COURSE (STUDENT)
  // ----------------------------
  Future<List<Map<String, dynamic>>> getLessonsByCourse(int courseId) async {
    final response = await _dio.get(
      '${ApiConstants.courses}/$courseId/lessons',
    );

    if (response.data is List) {
      return List<Map<String, dynamic>>.from(response.data);
    }

    return [];
  }

  // ----------------------------
  // CREATE COURSE (TEACHER)
  // ----------------------------
  Future<void> createCourse({
    required String titre,
    required String description,
  }) async {
    await _dio.post(
      ApiConstants.courses,
      data: {
        "titre": titre,
        "description": description,
      },
    );
  }

  // ----------------------------
  // UPDATE COURSE (TEACHER)
  // ----------------------------
  Future<void> updateCourse({
    required int id,
    required String titre,
    required String description,
  }) async {
    await _dio.put(
      '${ApiConstants.courses}/$id',
      data: {
        "titre": titre,
        "description": description,
      },
    );
  }

  // ----------------------------
  // DELETE COURSE (TEACHER)
  // ----------------------------
  Future<void> deleteCourse(int id) async {
    await _dio.delete('${ApiConstants.courses}/$id');
  }
}

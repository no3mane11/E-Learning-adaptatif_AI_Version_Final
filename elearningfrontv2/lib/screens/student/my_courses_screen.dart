import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/enrollment_service.dart';
import '../../core/services/session_service.dart';

class MyCoursesScreen extends ConsumerStatefulWidget {
  const MyCoursesScreen({super.key});

  @override
  ConsumerState<MyCoursesScreen> createState() => _MyCoursesScreenState();
}

class _MyCoursesScreenState extends ConsumerState<MyCoursesScreen> {
  bool loading = true;
  List<Map<String, dynamic>> enrollments = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await EnrollmentService.instance.getMyEnrollments();
      if (!mounted) return;
      setState(() {
        enrollments = data;
        loading = false;
      });
    } catch (e) {
      debugPrint('❌ LOAD MY COURSES ERROR = $e');
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes cours')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : enrollments.isEmpty
              ? const Center(child: Text('Aucun cours inscrit'))
              : ListView.builder(
                  itemCount: enrollments.length,
                  itemBuilder: (_, i) {
                    final e = enrollments[i];
                    return Card(
                      child: ListTile(
                        title: Text(e['courseTitle']),
                        subtitle: Text(
                          'Inscrit le ${e['enrolledAt'].toString().substring(0, 10)}',
                        ),
                        trailing: ElevatedButton(
                          child: const Text('Commencer le cours'),
                          onPressed: () async {
                            Map<String, dynamic>? session;
                            try {
                              await SessionService.instance.startSession(
                                enrollmentId: e['id'],
                              );
                            } catch (_) {
                              debugPrint('ℹ️ Session déjà active, récupération...');
                            }

                            session = await SessionService.instance.getActiveSession();
                            if (session == null) {
                              throw Exception('Impossible de récupérer la session active');
                            }

                            if (!mounted) return;
                            context.push(
                              '/lessons',
                              extra: {
                                'courseId': e['courseId'],
                                'courseTitle': e['courseTitle'],
                                'sessionId': session['id'],
                              },
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
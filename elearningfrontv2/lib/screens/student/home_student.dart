import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/auth_provider.dart';
import '../../core/services/course_service.dart';
import '../../core/services/enrollment_service.dart';
import '../../core/services/session_service.dart';

class HomeStudent extends ConsumerStatefulWidget {
  const HomeStudent({super.key});

  @override
  ConsumerState<HomeStudent> createState() => _HomeStudentState();
}

class _HomeStudentState extends ConsumerState<HomeStudent> {
  bool _loading = true;
  List<Map<String, dynamic>> _allCourses = [];
  List<Map<String, dynamic>> _enrollments = [];
  Map<int, String> _courseStatuses = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        CourseService.instance.getAllCourses(),
        EnrollmentService.instance.getMyEnrollments(),
        SessionService.instance.getMySessions(),
      ]);

      final courses = results[0] as List<Map<String, dynamic>>;
      final enrollments = results[1] as List<Map<String, dynamic>>;
      final sessions = results[2] as List<Map<String, dynamic>>;

      final statusMap = <int, String>{};
      for (var s in sessions) {
        int cId = s['courseId'];
        String status = s['status'];
        if (statusMap[cId] != 'COMPLETED') {
          statusMap[cId] = status;
        }
      }

      if (!mounted) return;
      setState(() {
        _allCourses = courses;
        _enrollments = enrollments;
        _courseStatuses = statusMap;
        _loading = false;
      });
    } catch (e) {
      debugPrint('❌ LOAD STUDENT DATA ERROR = $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _isEnrolled(int courseId) => _enrollments.any((e) => e['courseId'] == courseId);

  Map<String, dynamic>? _enrollmentFor(int courseId) {
    try {
      return _enrollments.firstWhere((e) => e['courseId'] == courseId);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F4F9),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : RefreshIndicator(
              onRefresh: _loadData,
              edgeOffset: 100,
              color: const Color(0xFF3F51B5),
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildSliverAppBar(user),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 25, 20, 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Formations',
                                  style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF1A1C1E))),
                              Text('Explorez vos nouveaux défis',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 13)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12)),
                            child: Text('${_allCourses.length} cours',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _allCourses.isEmpty
                      ? const SliverFillRemaining(
                          child: Center(child: Text('Aucun cours disponible')))
                      : SliverPadding(
                          padding: const EdgeInsets.all(20),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                return _buildAnimatedCourseCard(_allCourses[index], index);
                              },
                              childCount: _allCourses.length,
                            ),
                          ),
                        ),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
    );
  }

  Widget _buildSliverAppBar(Map<String, dynamic>? user) {
    return SliverAppBar(
      expandedHeight: 180,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF1A237E),
      leading: const Padding(
        padding: EdgeInsets.only(left: 15),
        child: Icon(Icons.dashboard_rounded, color: Colors.white),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 15),
          child: CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.1),
            child: IconButton(
              icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
              onPressed: () => ref.read(authProvider.notifier).logout(),
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                top: -20,
                child: CircleAvatar(
                    radius: 80, backgroundColor: Colors.white.withOpacity(0.05)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(25, 80, 25, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                          color: Colors.white24, shape: BoxShape.circle),
                      child: CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white,
                        child: Text(user?['nom']?[0].toUpperCase() ?? 'U',
                            style: const TextStyle(
                                color: Color(0xFF1A237E),
                                fontWeight: FontWeight.w900)),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Bonjour,',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 14)),
                          Text(user?['nom'] ?? 'Étudiant',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedCourseCard(Map<String, dynamic> course, int index) {
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 400 + (index * 100)),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: child,
          ),
        );
      },
      child: _buildCourseCard(course),
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> course) {
    final bool enrolled = _isEnrolled(course['id']);
    final String status = _courseStatuses[course['id']] ?? (enrolled ? 'NOT_STARTED' : 'AVAILABLE');

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF1A237E).withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, 10))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => _handleAction(course, enrolled),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatusBadge(status),
                    Row(
                      children: [
                        const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(course['teacherName'] ?? 'Professeur',
                            style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Text(
                  course['titre'],
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2D3142),
                      letterSpacing: -0.5),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Illustration icon
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: _getStatusColor(status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12)),
                      child: Icon(_getStatusIcon(status),
                          size: 20, color: _getStatusColor(status)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getBtnColor(status),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => _handleAction(course, enrolled),
                      child: Row(
                        children: [
                          Text(_getBtnLabel(status),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13)),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
                color: _getStatusColor(status), shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            _getStatusText(status),
            style: TextStyle(
                color: _getStatusColor(status),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }

  // --- LOGIQUE VISUELLE ---

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'COMPLETED': return Icons.verified_rounded;
      case 'IN_PROGRESS': return Icons.auto_graph_rounded;
      case 'NOT_STARTED': return Icons.bookmark_added_rounded;
      default: return Icons.school_rounded;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'COMPLETED': return const Color(0xFF4CAF50);
      case 'IN_PROGRESS': return const Color(0xFFFF9800);
      case 'NOT_STARTED': return const Color(0xFF2196F3);
      default: return const Color(0xFF9E9E9E);
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'COMPLETED': return 'TERMINÉ';
      case 'IN_PROGRESS': return 'EN COURS';
      case 'NOT_STARTED': return 'INSCRIT';
      default: return 'DISPONIBLE';
    }
  }

  String _getBtnLabel(String status) {
    if (status == 'AVAILABLE') return 'S\'inscrire';
    if (status == 'COMPLETED') return 'Revoir';
    return 'Continuer';
  }

  Color _getBtnColor(String status) {
    if (status == 'AVAILABLE') return const Color(0xFF1A237E);
    if (status == 'COMPLETED') return const Color(0xFF4CAF50);
    return const Color(0xFFFF9800);
  }

  // --- LOGIQUE MÉTIER (STRICTEMENT IDENTIQUE) ---

  Future<void> _handleAction(Map<String, dynamic> course, bool enrolled) async {
    if (!enrolled) {
      try {
        await EnrollmentService.instance.enroll(courseId: course['id']);
        await _loadData();
        return;
      } catch (e) {
        debugPrint('Erreur inscription: $e');
        return;
      }
    }

    final enrollment = _enrollmentFor(course['id']);
    if (enrollment == null) return;

    try {
      await SessionService.instance.startSession(enrollmentId: enrollment['id']);
    } catch (_) {}

    final session = await SessionService.instance.getActiveSession();
    if (session == null) return;

    if (!mounted) return;
    context.push('/lessons', extra: {
      'courseId': course['id'],
      'courseTitle': course['titre'],
      'sessionId': session['id'],
    }).then((_) => _loadData());
  }
}
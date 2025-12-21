import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/course_service.dart';
import '../lesson/lesson_screen.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> with TickerProviderStateMixin {
  List<Map<String, dynamic>> courses = [];
  bool isLoading = true;

  // Couleurs personnalisées
  final Color slate500 = const Color(0xFF64748B);
  final Color slate600 = const Color(0xFF475569);
  final Color slate400 = const Color(0xFF94A3B8);

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    try {
      final data = await CourseService.instance.getAllCourses();
      if (!mounted) return;
      setState(() {
        courses = data;
        isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ================= LOGIQUE MÉTIER CORRIGÉE (OVERFLOW) =================

  void _openDialog({Map<String, dynamic>? course}) {
    final titleCtrl = TextEditingController(text: course?['titre'] ?? '');
    final descCtrl = TextEditingController(text: course?['description'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Crucial pour que le contenu puisse s'étendre
      backgroundColor: Colors.transparent,
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          // On s'assure que le conteneur prend en compte le clavier
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
          ),
          child: SingleChildScrollView( // CORRECTION ICI : Permet le défilement
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 30),
              child: Column(
                mainAxisSize: MainAxisSize.min, // S'adapte au contenu
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    course == null ? 'Nouveau Cours' : 'Éditer le Cours',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 25),
                  _inputField(
                    controller: titleCtrl,
                    label: 'Titre de la formation',
                    icon: Icons.auto_stories_rounded,
                  ),
                  const SizedBox(height: 16),
                  _inputField(
                    controller: descCtrl,
                    label: 'Objectifs pédagogiques',
                    icon: Icons.notes_rounded,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (course == null) {
                          await CourseService.instance.createCourse(
                            titre: titleCtrl.text,
                            description: descCtrl.text,
                          );
                        } else {
                          await CourseService.instance.updateCourse(
                            id: course['id'],
                            titre: titleCtrl.text,
                            description: descCtrl.text,
                          );
                        }
                        if (!mounted) return;
                        Navigator.pop(context);
                        _loadCourses();
                      },
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'Publier le cours',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteCourse(int id) async {
    await CourseService.instance.deleteCourse(id);
    _loadCourses();
  }

  // ================= UI RESTANTE =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildHeader(context),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            sliver: isLoading
                ? const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5))),
                  )
                : courses.isEmpty 
                  ? const SliverFillRemaining(child: Center(child: Text("Aucun cours publié pour le moment")))
                  : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildAnimatedCourseCard(context, courses[index], index),
                      childCount: courses.length,
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openDialog(),
        elevation: 4,
        highlightElevation: 0,
        backgroundColor: const Color(0xFF4F46E5),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Créer un cours',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.2, color: Colors.white),
        ),
      ),
    );
  }

  SliverAppBar _buildHeader(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      stretch: true,
      elevation: 0,
      backgroundColor: const Color(0xFF4F46E5),
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Center(
          child: _glassIconButton(
            icon: Icons.chevron_left_rounded,
            tooltip: 'Retour',
            onTap: () => context.go('/professor'),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        centerTitle: true,
        title: const Text(
          'Catalogue Enseignant',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: -0.5),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF4338CA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Positioned(
              right: -50,
              top: -20,
              child: Icon(Icons.school_rounded, size: 200, color: Colors.white.withOpacity(0.05)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedCourseCard(BuildContext context, Map<String, dynamic> c, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + (index * 150)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 50 * (1 - value)),
            child: child,
          ),
        );
      },
      child: _buildCourseCard(context, c),
    );
  }

  Widget _buildCourseCard(BuildContext context, Map<String, dynamic> c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white,
        border: Border.all(color: Colors.indigo.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => LessonScreen(course: c)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F46E5).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.collections_bookmark_rounded, color: Color(0xFF4F46E5), size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c['titre'] ?? '',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Module de formation',
                            style: TextStyle(color: Colors.indigo.shade400, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                          ),
                        ],
                      ),
                    ),
                    _buildActionMenu(c),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  c['description'] ?? 'Aucune description disponible pour ce cours.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: slate500, height: 1.5, fontSize: 14),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(height: 1),
                ),
                Row(
                  children: [
                    Icon(Icons.layers_outlined, size: 16, color: slate400),
                    const SizedBox(width: 6),
                    Text(
                      'Structure complète',
                      style: TextStyle(fontSize: 13, color: slate600, fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    const Text('Gérer', style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.w700, fontSize: 13)),
                    const Icon(Icons.chevron_right_rounded, color: Color(0xFF4F46E5), size: 18),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionMenu(Map<String, dynamic> c) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      icon: Icon(Icons.more_vert_rounded, color: slate400),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onSelected: (value) {
        if (value == 'edit') _openDialog(course: c);
        if (value == 'delete') _deleteCourse(c['id']);
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(children: [Icon(Icons.edit_note_rounded, size: 20), SizedBox(width: 12), Text('Modifier')]),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(children: [Icon(Icons.delete_sweep_rounded, size: 20, color: Colors.red), SizedBox(width: 12), Text('Supprimer', style: TextStyle(color: Colors.red))]),
        ),
      ],
    );
  }

  Widget _glassIconButton({required IconData icon, required VoidCallback onTap, String? tooltip}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white),
            tooltip: tooltip,
            onPressed: onTap,
          ),
        ),
      ),
    );
  }

  Widget _inputField({required TextEditingController controller, required String label, required IconData icon, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF64748B))),
        ),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20, color: const Color(0xFF4F46E5)),
            filled: true,
            fillColor: const Color(0xFFF1F5F9),
            contentPadding: const EdgeInsets.all(20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
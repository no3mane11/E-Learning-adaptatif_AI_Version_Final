import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/services/lesson_service.dart';
import 'lesson_reader_screen.dart';
import 'lesson_video_screen.dart';
import '../quiz/quiz_screen.dart';

class LessonScreen extends StatefulWidget {
  final Map<String, dynamic> course;

  const LessonScreen({super.key, required this.course});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> lessons = [];
  bool isLoading = true;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _loadLessons();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadLessons() async {
    try {
      final data = await LessonService.instance
          .getLessonsByCourse(widget.course['id']);
      if (!mounted) return;
      setState(() {
        lessons = data;
        isLoading = false;
      });
      _controller.forward(from: 0);
    } catch (_) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ================= LOGIQUE MÉTIER PRÉSERVÉE (UI AMÉLIORÉE) =================

  void _openDialog({Map<String, dynamic>? lesson}) {
    final titreCtrl = TextEditingController(text: lesson?['titre'] ?? '');
    final ordreCtrl = TextEditingController(text: lesson?['ordre']?.toString() ?? '');
    final contenuCtrl = TextEditingController(text: lesson?['contenu'] ?? '');
    String typeContenu = lesson?['typeContenu'] ?? 'THEORY';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 24, right: 24, top: 12,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
                const SizedBox(height: 24),
                Text(lesson == null ? 'Nouvelle Leçon' : 'Modifier la Leçon',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                const SizedBox(height: 24),
                _input(titreCtrl, 'Titre de la leçon', Icons.title_rounded),
                _input(ordreCtrl, 'Position (Ordre)', Icons.format_list_numbered_rounded, isNumber: true),
                
                StatefulBuilder(builder: (context, setLocalState) {
                  return Column(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(16)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButtonFormField<String>(
                          value: typeContenu,
                          decoration: const InputDecoration(border: InputBorder.none, labelText: 'Type de support'),
                          items: const [
                            DropdownMenuItem(value: 'THEORY', child: Text('📖 Théorie / Texte')),
                            DropdownMenuItem(value: 'VIDEO', child: Text('🎬 Vidéo éducative')),
                            DropdownMenuItem(value: 'QUIZ', child: Text('🧠 Quiz d\'évaluation')),
                          ],
                          onChanged: (v) => setLocalState(() => typeContenu = v!),
                        ),
                      ),
                    ),
                    if (typeContenu == 'THEORY') ...[
                      const SizedBox(height: 16),
                      _input(contenuCtrl, 'Contenu Markdown / Texte', Icons.article_rounded, maxLines: 5),
                    ],
                  ]);
                }),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (lesson == null) {
                        await LessonService.instance.createLesson(
                          courseId: widget.course['id'], titre: titreCtrl.text,
                          typeContenu: typeContenu, ordre: int.parse(ordreCtrl.text),
                          contenu: typeContenu == 'THEORY' ? contenuCtrl.text : null,
                        );
                      } else {
                        await LessonService.instance.updateLesson(
                          id: lesson['id'], courseId: widget.course['id'],
                          titre: titreCtrl.text, typeContenu: typeContenu,
                          ordre: int.parse(ordreCtrl.text),
                          contenu: typeContenu == 'THEORY' ? contenuCtrl.text : null,
                        );
                      }
                      Navigator.pop(context);
                      _loadLessons();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text('Enregistrer la leçon', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteLesson(int id) async {
    await LessonService.instance.deleteLesson(id);
    _loadLessons();
  }

  // ================= UI MODERNE =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openDialog(),
        backgroundColor: const Color(0xFF4F46E5),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Ajouter', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(),
          if (isLoading)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
          else if (lessons.isEmpty)
            _buildEmptyState()
          else
            _buildLessonList(),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      stretch: true,
      elevation: 0,
      backgroundColor: const Color(0xFF4F46E5),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
        titlePadding: const EdgeInsets.only(left: 50, bottom: 16),
        title: Text(widget.course['titre'], 
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.white)),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF6366F1), Color(0xFF4338CA)],
                ),
              ),
            ),
            Positioned(
              right: -20, bottom: -20,
              child: Icon(Icons.auto_stories_rounded, size: 150, color: Colors.white.withOpacity(0.1)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SliverFillRemaining(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.layers_clear_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('Aucune leçon disponible', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildLessonList() {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) {
            final animation = CurvedAnimation(
              parent: _controller,
              curve: Interval((i / lessons.length).clamp(0, 1), 1.0, curve: Curves.easeOutBack),
            );
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: animation,
                child: _lessonCard(lessons[i], i + 1),
              ),
            );
          },
          childCount: lessons.length,
        ),
      ),
    );
  }

  Widget _lessonCard(Map<String, dynamic> l, int index) {
    final color = switch (l['typeContenu']) {
      'VIDEO' => Colors.redAccent,
      'QUIZ' => Colors.orangeAccent,
      _ => Colors.indigoAccent,
    };
    
    final icon = switch (l['typeContenu']) {
      'VIDEO' => Icons.play_circle_fill_rounded,
      'QUIZ' => Icons.psychology_rounded,
      _ => Icons.menu_book_rounded,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _handleLessonNavigation(l),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 55, height: 55,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Center(child: Icon(icon, color: color, size: 28)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("LEÇON $index", 
                          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.2)),
                        const SizedBox(height: 4),
                        Text(l['titre'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1F2937))),
                      ],
                    ),
                  ),
                  _buildActionMenu(l),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionMenu(Map<String, dynamic> l) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert_rounded, color: Colors.grey[400]),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (v) {
        if (v == 'edit') _openDialog(lesson: l);
        if (v == 'delete') _deleteLesson(l['id']);
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_rounded, size: 18), SizedBox(width: 8), Text('Modifier')])),
        PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18), SizedBox(width: 8), Text('Supprimer', style: TextStyle(color: Colors.red))])),
      ],
    );
  }

  void _handleLessonNavigation(Map<String, dynamic> l) {
    Widget? screen;
    if (l['typeContenu'] == 'THEORY') screen = LessonReaderScreen(lesson: l);
    if (l['typeContenu'] == 'VIDEO') screen = LessonVideoScreen(lesson: l);
    if (l['typeContenu'] == 'QUIZ') screen = QuizScreen(lesson: l);

    if (screen != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen!));
    }
  }

  Widget _input(TextEditingController c, String label, IconData icon, {bool isNumber = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: c,
        maxLines: maxLines,
        keyboardType: isNumber ? TextInputType.number : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20, color: const Color(0xFF4F46E5)),
          filled: true,
          fillColor: Colors.grey[100],
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5)),
        ),
      ),
    );
  }
}
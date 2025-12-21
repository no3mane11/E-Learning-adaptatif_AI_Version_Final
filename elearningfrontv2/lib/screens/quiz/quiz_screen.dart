import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/quiz_service.dart';
import '../../core/providers/auth_provider.dart';

class QuizScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> lesson;

  const QuizScreen({super.key, required this.lesson});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> quizzes = [];
  bool loading = true;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    try {
      final lessonId = widget.lesson['id'];
      final data = await QuizService.instance.getByLesson(lessonId: lessonId);
      if (!mounted) return;
      setState(() {
        quizzes = data;
        loading = false;
      });
      _controller.forward(from: 0);
    } catch (e) {
      if (mounted) setState(() => loading = false);
    }
  }

  // ---------------- MODAL D'AJOUT (AMÉLIORÉ) ----------------
  void _openDialog() {
    final qCtrl = TextEditingController();
    final c1 = TextEditingController();
    final c2 = TextEditingController();
    final c3 = TextEditingController();
    int correct = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
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
                const Text('Nouvelle Question', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 24),
                _input(qCtrl, 'Énoncé de la question', Icons.quiz_rounded),
                _input(c1, 'Option 1', Icons.looks_one_rounded),
                _input(c2, 'Option 2', Icons.looks_two_rounded),
                _input(c3, 'Option 3', Icons.looks_3_rounded),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: correct,
                  decoration: InputDecoration(
                    labelText: 'Réponse correcte',
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('Réponse 1')),
                    DropdownMenuItem(value: 1, child: Text('Réponse 2')),
                    DropdownMenuItem(value: 2, child: Text('Réponse 3')),
                  ],
                  onChanged: (v) => correct = v!,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () async {
                      await QuizService.instance.create(
                        lessonId: widget.lesson['id'],
                        question: qCtrl.text,
                        choices: [c1.text, c2.text, c3.text],
                        correctAnswer: correct,
                      );
                      Navigator.pop(context);
                      _load();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Enregistrer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: auth.isAuthenticated ? _openDialog : null,
        backgroundColor: const Color(0xFF4F46E5),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Question', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(),
          if (loading)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
          else if (quizzes.isEmpty)
            _buildEmptyState()
          else
            _buildQuizList(),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      stretch: true,
      elevation: 0,
      backgroundColor: const Color(0xFF4F46E5),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Quiz Builder', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: Colors.white70)),
            Text(widget.lesson['titre'], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.white)),
          ],
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF4338CA)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
          child: Stack(
            children: [
              Positioned(right: -20, top: 40, child: Icon(Icons.psychology_rounded, size: 140, color: Colors.white.withOpacity(0.1))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons. help_outline_rounded, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('Aucune question pour le moment', style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizList() {
    return SliverPadding(
      padding: const EdgeInsets.all(20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) {
            final animation = CurvedAnimation(parent: _controller, curve: Interval(i / quizzes.length, 1.0, curve: Curves.easeOutBack));
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: animation, child: _quizCard(quizzes[i], i + 1)),
            );
          },
          childCount: quizzes.length,
        ),
      ),
    );
  }

  Widget _quizCard(Map<String, dynamic> q, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: const EdgeInsets.fromLTRB(20, 10, 10, 0),
            title: Text("QUESTION $index", style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.2)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(q['question'], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Color(0xFF1E293B))),
            ),
            trailing: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
              ),
              onPressed: () async {
                await QuizService.instance.delete(id: q['id']);
                _load();
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(q['choices'].length, (idx) {
                bool isCorrect = idx == q['correctAnswer'];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isCorrect ? const Color(0xFF10B981).withOpacity(0.1) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isCorrect ? const Color(0xFF10B981).withOpacity(0.3) : Colors.transparent),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isCorrect) const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF10B981)),
                      if (isCorrect) const SizedBox(width: 6),
                      Text(q['choices'][idx], style: TextStyle(fontSize: 13, fontWeight: isCorrect ? FontWeight.bold : FontWeight.normal, color: isCorrect ? const Color(0xFF065F46) : Colors.grey[700])),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _input(TextEditingController c, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: c,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20, color: const Color(0xFF4F46E5)),
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5)),
        ),
      ),
    );
  }
}
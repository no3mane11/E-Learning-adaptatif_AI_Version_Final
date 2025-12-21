import 'dart:async';
import 'dart:collection';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../main.dart' show globalAvailableCameras;
import '../../core/constants/api_constants.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/lesson_service.dart';
import '../../core/services/session_service.dart';
import '../../core/services/quiz_service.dart';
import '../../core/services/frustration_api_service.dart';
import '../../core/utils/image_converter.dart';
import '../../models/frustration_model.dart';

class LessonStudentScreen extends ConsumerStatefulWidget {
  final int courseId;
  final String courseTitle;
  final String sessionId;

  const LessonStudentScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
    required this.sessionId,
  });

  @override
  ConsumerState<LessonStudentScreen> createState() => _LessonStudentScreenState();
}

class _LessonStudentScreenState extends ConsumerState<LessonStudentScreen> {
  // ---------------- ÉTAT ----------------
  bool _loading = true;
  List<Map<String, dynamic>> _lessons = [];
  int _currentLessonIndex = 0;
  List<Map<String, dynamic>> _currentQuizzes = [];
  bool _loadingQuiz = false;
  final Map<int, int?> _selectedAnswers = {};
  final Map<int, bool?> _quizResults = {};

  // ---------------- TIMERS ----------------
  Timer? _timer, _syncTimer, _apiTimer;
  int _seconds = 0;

  // ---------------- CAMERA / IA ----------------
  CameraController? _cameraController;
  FrustrationModel? _model;
  bool _cameraReady = false;
  bool _detecting = false;
  double _currentScore = 0.0;
  final Queue<double> _history = Queue<double>();
  static const int _windowSize = 25; // Fenêtre lissée
  double _averageScore = 0.0;

  final Duration _inferenceInterval = const Duration(milliseconds: 600);
  DateTime _lastInference = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _initializeAll();
    _startTimers();
  }

  // --- INITIALISATION ---
  Future<void> _initializeAll() async {
    // Charger le modèle TFLite
    final buffer = await FrustrationModel.loadModelBuffer();
    _model = FrustrationModel.fromBuffer(buffer);
    
    await _initializeCamera();
    await _loadLessons();
    
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _initializeCamera() async {
    if (globalAvailableCameras.isEmpty) { _cameraReady = true; return; }
    
    final cam = globalAvailableCameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => globalAvailableCameras.first,
    );

    _cameraController = CameraController(
      cam, 
      ResolutionPreset.medium, 
      enableAudio: false, 
      imageFormatGroup: ImageFormatGroup.yuv420
    );

    try {
      await _cameraController!.initialize();
      if (mounted) {
        await _cameraController!.startImageStream(_onCameraImage);
        setState(() => _cameraReady = true);
      }
    } catch (e) {
      debugPrint("Camera Init Error: $e");
    }
  }

  // --- LOGIQUE IA ---
  void _onCameraImage(CameraImage image) {
    if (!mounted || _cameraController == null || !_cameraReady || _detecting) return;
    
    final now = DateTime.now();
    if (now.difference(_lastInference) < _inferenceInterval) return;
    
    _detecting = true;
    _lastInference = now;

    try {
      final img = convertYUV420ToImage(image);
      if (img != null && _model != null) {
        final score = _model!.predict(img);
        _updateScores(score);
      }
    } catch (e) {
      debugPrint("Inference Error: $e");
    } finally {
      _detecting = false;
    }
  }

  void _updateScores(double score) {
    if (!mounted) return;
    setState(() {
      _currentScore = score;
      _history.add(score);
      if (_history.length > _windowSize) _history.removeFirst();
      if (_history.isNotEmpty) {
        _averageScore = _history.reduce((a, b) => a + b) / _history.length;
      }
    });
  }

  // --- TIMERS & SYNC ---
  void _startTimers() {
    // Timer de durée de session (UI)
    _timer = Timer.periodic(const Duration(seconds: 1), 
      (_) => mounted ? setState(() => _seconds++) : null);

    // Sync temps passé vers DB (30s)
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) => _saveTime());

    // Sync IA Frustration vers DB (5s)
    _apiTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (mounted && widget.sessionId.isNotEmpty) {
        try {
          // Utilise le service qui exploite déjà votre ApiClient (et donc le token automatique)
          await SessionService.instance.recordFrustrationMetric(
            sessionId: widget.sessionId, 
            score: _averageScore
          );
        } catch (e) {
          debugPrint("Sync Frustration Error: $e");
        }
      }
    });
  }

  Future<void> _saveTime() async {
    try { 
      await SessionService.instance.updateTime(
        sessionId: widget.sessionId, 
        durationSeconds: _seconds
      ); 
    } catch (_) {}
  }

  Future<void> _handleFinishCourse() async {
    if (!mounted) return;
    try {
      // Stopper les captures avant de quitter
      _apiTimer?.cancel();
      if (_cameraController != null && _cameraController!.value.isStreamingImages) {
        await _cameraController!.stopImageStream();
      }

      showDialog(
        context: context, 
        barrierDismissible: false, 
        builder: (_) => const Center(child: CircularProgressIndicator())
      );

      await _saveTime();
      await SessionService.instance.endSession(sessionId: widget.sessionId);
      
      if (!mounted) return;
      Navigator.pop(context); // Ferme le loader
      context.pop(); // Retour à la liste des cours
    } catch (e) {
      if (mounted) Navigator.pop(context);
    }
  }

  // --- CHARGEMENT CONTENU ---
  Future<void> _loadLessons() async {
    _lessons = await LessonService.instance.getLessonsByCourse(widget.courseId);
    if (_lessons.isNotEmpty) _loadLessonContent(_lessons.first);
  }

  Future<void> _loadLessonContent(Map<String, dynamic> lesson) async {
    _currentQuizzes.clear(); 
    _selectedAnswers.clear(); 
    _quizResults.clear();
    
    if (lesson['typeContenu'] == 'QUIZ') {
      setState(() => _loadingQuiz = true);
      _currentQuizzes = await QuizService.instance.getByLesson(lessonId: lesson['id']);
      setState(() => _loadingQuiz = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _syncTimer?.cancel();
    _apiTimer?.cancel();
    if (_cameraController != null && _cameraController!.value.isStreamingImages) {
      _cameraController!.stopImageStream();
    }
    _cameraController?.dispose();
    _model?.close();
    super.dispose();
  }

  // --- STYLING ---
  Color get _themeColor {
    if (_averageScore < 0.35) return const Color(0xFF6366F1); // Indigo (Calme)
    if (_averageScore < 0.60) return Colors.amber.shade700;    // Orange (Stressé)
    return Colors.redAccent.shade700;                         // Rouge (Frustré)
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    
    final lesson = _lessons[_currentLessonIndex];
    final isQuiz = lesson['typeContenu'] == 'QUIZ';

    return PopScope(
      onPopInvoked: (didPop) { if (didPop) _saveTime(); },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
            onPressed: () => context.pop(),
          ),
          title: Text(widget.courseTitle, 
            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 17)),
          actions: [_buildTimerBadge(), const SizedBox(width: 16)],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                _buildTopProgress(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 140),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(lesson['titre'] ?? '', 
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                        const SizedBox(height: 20),
                        isQuiz ? _buildQuizSection() : _buildLessonContent(lesson['contenu'] ?? ''),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            // Caméra et Jauges IA
            if (_cameraReady && _cameraController != null) _buildAIFloatingOverlay(),
            
            // Navigation Basse
            Positioned(bottom: 0, left: 0, right: 0, child: _buildBottomActionBar()),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS UI ---

  Widget _buildTopProgress() {
    return LinearProgressIndicator(
      value: (_currentLessonIndex + 1) / _lessons.length,
      backgroundColor: Colors.indigo.withOpacity(0.05),
      valueColor: AlwaysStoppedAnimation(_themeColor),
      minHeight: 4,
    );
  }

  Widget _buildTimerBadge() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _themeColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '${_seconds ~/ 60}:${(_seconds % 60).toString().padLeft(2, '0')}',
          style: TextStyle(color: _themeColor, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildLessonContent(String content) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15)],
      ),
      child: Text(content, 
        style: const TextStyle(fontSize: 18, height: 1.6, color: Color(0xFF475569))),
    );
  }

  Widget _buildAIFloatingOverlay() {
    return Positioned(
      top: 15, right: 15,
      child: Column(
        children: [
          Container(
            width: 90, height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _themeColor, width: 2),
              boxShadow: [BoxShadow(color: _themeColor.withOpacity(0.4), blurRadius: 12)],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: CameraPreview(_cameraController!),
            ),
          ),
          const SizedBox(height: 8),
          _buildGlassMetricCard(),
        ],
      ),
    );
  }

  Widget _buildGlassMetricCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          width: 90, padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withOpacity(0.4)),
          ),
          child: Column(
            children: [
              _metricLinear("LIVE", _currentScore),
              const SizedBox(height: 8),
              _metricLinear("MOY", _averageScore),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metricLinear(String label, double val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.black54)),
        const SizedBox(height: 3),
        LinearProgressIndicator(
          value: val, 
          minHeight: 4, 
          borderRadius: BorderRadius.circular(2),
          backgroundColor: Colors.black.withOpacity(0.05),
          valueColor: AlwaysStoppedAnimation(_themeColor),
        ),
      ],
    );
  }

  Widget _buildQuizSection() {
    if (_loadingQuiz) return const Center(child: CircularProgressIndicator());
    return Column(
      children: _currentQuizzes.map((quiz) {
        final id = quiz['id'];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(quiz['question'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ...(quiz['choices'] as List).asMap().entries.map((e) {
                final isSel = _selectedAnswers[id] == e.key;
                return GestureDetector(
                  onTap: () => setState(() => _selectedAnswers[id] = e.key),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: isSel ? _themeColor.withOpacity(0.1) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: isSel ? _themeColor : Colors.transparent),
                    ),
                    child: Row(
                      children: [
                        Icon(isSel ? Icons.check_circle : Icons.circle_outlined, 
                             color: isSel ? _themeColor : Colors.black26),
                        const SizedBox(width: 12),
                        Expanded(child: Text(e.value)),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomActionBar() {
    bool isLast = _currentLessonIndex == _lessons.length - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 35),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Row(
        children: [
          if (_currentLessonIndex > 0)
            IconButton.filledTonal(
              onPressed: () => setState(() { 
                _currentLessonIndex--; 
                _loadLessonContent(_lessons[_currentLessonIndex]); 
              }),
              icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isLast ? Colors.green.shade600 : _themeColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 0,
              ),
              onPressed: isLast ? _handleFinishCourse : () {
                setState(() {
                  _currentLessonIndex++;
                  _loadLessonContent(_lessons[_currentLessonIndex]);
                });
              },
              child: Text(isLast ? 'TERMINER LE COURS' : 'LEÇON SUIVANTE', 
                style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5)),
            ),
          ),
        ],
      ),
    );
  }
}
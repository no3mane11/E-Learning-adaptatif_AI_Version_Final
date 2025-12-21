import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/services/session_service.dart';

class TeacherDashboardStudent extends StatefulWidget {
  const TeacherDashboardStudent({super.key});

  @override
  State<TeacherDashboardStudent> createState() => _TeacherDashboardStudentState();
}

class _TeacherDashboardStudentState extends State<TeacherDashboardStudent> {
  bool _loading = true;
  List<Map<String, dynamic>> _allStudentData = []; // Stockage complet
  List<Map<String, dynamic>> _filteredData = [];   // Stockage filtré pour l'affichage
  Timer? _refreshTimer;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAllStudentsStats();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), 
        (_) => _loadAllStudentsStats(isAutoRefresh: true));
    
    // Écouteur pour la recherche
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllStudentsStats({bool isAutoRefresh = false}) async {
    try {
      final data = await SessionService.instance.getTeacherDashboardStats();
      if (mounted) {
        setState(() {
          _allStudentData = data;
          _applyFilter(); // Réappliquer le filtre sur les nouvelles données reçues
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted && !isAutoRefresh) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), behavior: SnackBarBehavior.floating)
        );
      }
    }
  }

  void _applyFilter() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredData = _allStudentData;
      } else {
        _filteredData = _allStudentData.where((session) {
          final studentName = (session['studentName'] ?? "").toString().toLowerCase();
          final courseTitle = (session['courseTitle'] ?? "").toString().toLowerCase();
          return studentName.contains(query) || courseTitle.contains(query);
        }).toList();
      }
    });
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    return "${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(),
          _buildSearchBox(), // Nouveau composant de recherche
          if (_loading && _allStudentData.isEmpty)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
          else if (_filteredData.isEmpty)
            SliverFillRemaining(child: _buildEmptyState(isSearch: _searchController.text.isNotEmpty))
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = _filteredData[index];
                    return _buildAnimatedCard(item, index);
                  },
                  childCount: _filteredData.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 100,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: const Text('Analyse des Étudiants', 
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 18)),
      ),
      actions: [
        _buildSyncIndicator(),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildSearchBox() {
    return SliverToBoxAdapter(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: "Rechercher un étudiant ou un cours...",
              hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
              prefixIcon: Icon(Icons.search, color: Colors.indigo, size: 20),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSyncIndicator() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.indigo.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 8, height: 8, child: CircularProgressIndicator(strokeWidth: 2)),
            const SizedBox(width: 8),
            Text("LIVE", style: TextStyle(fontSize: 9, color: Colors.indigo.shade700, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedCard(Map<String, dynamic> item, int index) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(item['sessionId'] ?? index),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(offset: Offset(0, 20 * (1 - value)), child: child),
        );
      },
      child: _buildStudentCard(item),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> session) {
    final String name = session['studentName'] ?? "Étudiant";
    final String course = session['courseTitle'] ?? "Session";
    final double frustration = (session['averageFrustrationScore'] ?? 0.0).toDouble();
    final bool isOnline = session['status'] == "IN_PROGRESS";
    final Color mainColor = _getFrustrationColor(frustration);

    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                _buildAvatar(name, isOnline),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF1E293B))),
                      Text(course, style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                _buildStatusTag(isOnline),
              ],
            ),
            const SizedBox(height: 16),
            _buildMetricsRow(session, frustration, mainColor),
            const SizedBox(height: 16),
            _buildFrustrationGraph(frustration, mainColor),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String name, bool isOnline) {
    return CircleAvatar(
      radius: 22,
      backgroundColor: Colors.indigo.shade50,
      child: Text(name.isNotEmpty ? name[0].toUpperCase() : "?", 
        style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildMetricsRow(Map<String, dynamic> session, double frustration, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _infoItem("Temps", _formatDuration(session['durationSeconds'] ?? 0), Icons.timer_outlined),
        _infoItem("Score IA", "${(frustration * 100).toStringAsFixed(0)}%", Icons.analytics_outlined, valueColor: color),
      ],
    );
  }

  Widget _infoItem(String label, String value, IconData icon, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: Colors.grey),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
          ],
        ),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: valueColor ?? const Color(0xFF1E293B))),
      ],
    );
  }

  Widget _buildFrustrationGraph(double score, Color color) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: LinearProgressIndicator(
        value: score.clamp(0.05, 1.0),
        minHeight: 6,
        backgroundColor: const Color(0xFFF1F5F9),
        valueColor: AlwaysStoppedAnimation(color),
      ),
    );
  }

  Widget _buildStatusTag(bool isOnline) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isOnline ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(isOnline ? "LIVE" : "FINI", 
        style: TextStyle(color: isOnline ? Colors.green : Colors.grey, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }

  Color _getFrustrationColor(double score) {
    if (score < 0.35) return const Color(0xFF10B981);
    if (score < 0.60) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  Widget _buildEmptyState({bool isSearch = false}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(isSearch ? Icons.search_off : Icons.people_outline, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(isSearch ? "Aucun résultat trouvé" : "Aucune session active", 
            style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
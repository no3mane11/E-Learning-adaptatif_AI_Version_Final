import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/auth_provider.dart';

class HomeTeacher extends ConsumerStatefulWidget {
  const HomeTeacher({super.key});

  @override
  ConsumerState<HomeTeacher> createState() => _HomeTeacherState();
}

class _HomeTeacherState extends ConsumerState<HomeTeacher> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final user = auth.user;
    final name = user?['nom'] ?? 'Teacher';
    final email = user?['email'] ?? '';

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Fond gris très clair moderne
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(colorScheme, theme),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 👤 PROFIL SECTION (STYLE INNOVANT)
                    _buildHeroHeader(name, email, colorScheme, theme),

                    const SizedBox(height: 30),

                    // 📊 STATS AVEC EFFET DE GRILLE
                    _buildSectionTitle(theme, "Vue d'ensemble"),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _StatCard(
                          title: 'Cours',
                          value: '12',
                          icon: Icons.auto_stories_rounded,
                          gradient: [const Color(0xFF6366F1), const Color(0xFF4338CA)],
                        ),
                        const SizedBox(width: 16),
                        _StatCard(
                          title: 'Étudiants',
                          value: '180',
                          icon: Icons.group_rounded,
                          gradient: [const Color(0xFFF59E0B), const Color(0xFFD97706)],
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // 🚀 ACTIONS RAPIDES
                    _buildSectionTitle(theme, "Outils de gestion"),
                    const SizedBox(height: 16),
                    _buildActionCard(
                      title: "Analyse des Étudiants",
                      subtitle: "Détection de frustration par IA",
                      icon: Icons.psychology_rounded,
                      color: Colors.deepPurple,
                      onTap: () => context.push('/teacher-dashboard-student'),
                    ),
                    const SizedBox(height: 12),
                    _buildActionCard(
                      title: "Bibliothèque de Cours",
                      subtitle: "Éditer vos supports pédagogiques",
                      icon: Icons.collections_bookmark_rounded,
                      color: Colors.blueAccent,
                      onTap: () => context.go('/courses'),
                    ),

                    const SizedBox(height: 32),

                    // ℹ️ IA BANNER
                    _buildAIBanner(colorScheme),
                    const SizedBox(height: 100), // Espace pour le bottom bar
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context, colorScheme),
    );
  }

  Widget _buildSliverAppBar(ColorScheme colorScheme, ThemeData theme) {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      title: Text('Zenith Teacher', 
        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
          child: IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroHeader(String name, String email, ColorScheme colorScheme, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.06),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 45,
            backgroundColor: Colors.indigo.shade50,
            child: CircleAvatar(
              radius: 40,
              backgroundColor: Colors.indigo.shade400,
              child: Text(name[0].toUpperCase(), 
                style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 16),
          Text("Ravi de vous revoir,", style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
          Text(name, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, color: const Color(0xFF1E293B))),
          const SizedBox(height: 4),
          Text(email, style: theme.textTheme.labelMedium?.copyWith(color: Colors.indigo.withOpacity(0.7))),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Text(title, 
      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: const Color(0xFF334155)));
  }

  Widget _buildActionCard({
    required String title, 
    required String subtitle, 
    required IconData icon, 
    required Color color, 
    required VoidCallback onTap
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
      ),
    );
  }

  Widget _buildAIBanner(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.7)]),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Colors.white, size: 30),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              "Découvrez les nouveaux insights IA basés sur l'engagement émotionnel de vos classes.",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: NavigationBar(
          height: 65,
          elevation: 0,
          backgroundColor: Colors.transparent,
          selectedIndex: _currentIndex,
          indicatorColor: colorScheme.primary.withOpacity(0.1),
          onDestinationSelected: (index) {
            setState(() => _currentIndex = index);
            if (index == 1) context.go('/courses');
            if (index == 2) context.push('/teacher-dashboard-student');
          },
          destinations: const [
            NavigationDestination(icon: Icon(Icons.grid_view_rounded), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.layers_rounded), label: 'Cours'),
            NavigationDestination(icon: Icon(Icons.analytics_rounded), label: 'Stats'),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final List<Color> gradient;

  const _StatCard({required this.title, required this.value, required this.icon, required this.gradient});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(color: gradient.first.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
            Text(title, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
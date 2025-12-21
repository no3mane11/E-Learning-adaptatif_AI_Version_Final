import 'dart:ui';
import 'package:flutter/material.dart';

class LessonReaderScreen extends StatefulWidget {
  final Map<String, dynamic> lesson;

  const LessonReaderScreen({
    super.key,
    required this.lesson,
  });

  @override
  State<LessonReaderScreen> createState() => _LessonReaderScreenState();
}

class _LessonReaderScreenState extends State<LessonReaderScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ================= HEADER INNOVANT =================
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            stretch: true,
            elevation: 0,
            backgroundColor: const Color(0xFF4F46E5),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Dégradé de fond
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF4338CA)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  // Formes décoratives en arrière-plan
                  Positioned(
                    top: -50,
                    right: -50,
                    child: CircleAvatar(
                      radius: 100,
                      backgroundColor: Colors.white.withOpacity(0.05),
                    ),
                  ),
                  Center(
                    child: Icon(
                      Icons.auto_stories_rounded,
                      size: 80,
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ================= CONTENU READER =================
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -30),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withOpacity(0.06),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // BADGE TYPE
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4F46E5).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            (lesson['typeContenu'] ?? 'THEORY').toString().toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFF4F46E5),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // TITRE
                        Text(
                          lesson['titre'] ?? 'Sans titre',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF1E293B),
                            letterSpacing: -0.5,
                          ),
                        ),
                        
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Divider(color: Color(0xFFF1F5F9), thickness: 2),
                        ),

                        // CORPS DU TEXTE
                        Text(
                          lesson['contenu'] ?? 'Aucun contenu disponible pour cette leçon.',
                          style: const TextStyle(
                            fontSize: 17,
                            height: 1.8,
                            color: Color(0xFF475569),
                            fontFamily: 'Georgia', // Optionnel : donne un aspect plus "lecteur"
                          ),
                        ),
                        
                        const SizedBox(height: 40),
                        
                        // INFOS DE BAS DE PAGE
                        _buildFooterInfo(
                          Icons.tag_rounded, 
                          'Ordre de lecture : ${lesson['ordre'] ?? 'N/A'}'
                        ),
                        const SizedBox(height: 8),
                        _buildFooterInfo(
                          Icons.collections_bookmark_rounded, 
                          'Cours : ${lesson['courseTitle'] ?? 'Formation générale'}'
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Espace de fin pour le scroll
          const SliverToBoxAdapter(child: SizedBox(height: 50)),
        ],
      ),
    );
  }

  Widget _buildFooterInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
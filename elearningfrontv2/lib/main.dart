import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:camera/camera.dart'; 

import 'core/providers/auth_provider.dart';

// ================= AUTH =================
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';

// ================= TEACHER =================
import 'screens/teacher/home_teacher.dart';
import 'screens/teacher/dashboard_student.dart'; // ⬅️ NOUVEL IMPORT
import 'screens/course/courses_screen.dart';
import 'screens/lesson/lesson_screen.dart';

// ================= STUDENT =================
import 'screens/student/home_student.dart';
import 'screens/student/my_courses_screen.dart';
import 'screens/student/lesson_student.dart';


// ---------------------------------------------------------------------
// 1. DÉCLARATION GLOBALE DE LA LISTE DES CAMÉRAS
// ---------------------------------------------------------------------
late List<CameraDescription> globalAvailableCameras;


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ---------------------------------------------------------------------
  // 2. INITIALISATION DE LA CAMÉRA DANS LA FONCTION MAIN
  // ---------------------------------------------------------------------
  try {
    globalAvailableCameras = await availableCameras(); 
    debugPrint('✅ Caméras disponibles chargées.');
  } on CameraException catch (e) {
    globalAvailableCameras = []; 
    debugPrint('❌ Erreur lors du chargement des caméras: $e');
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.read(authProvider.notifier).loadFromStorage();

    final router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),
        
        // 🏠 ACCUEIL PROFESSEUR
        GoRoute(
          path: '/professor',
          builder: (context, state) {
            final auth = ref.watch(authProvider);
            return auth.isAuthenticated ? const HomeTeacher() : const LoginScreen();
          },
        ),

        // 📊 DASHBOARD SUIVI ÉTUDIANTS (NOUVELLE ROUTE)
        GoRoute(
          path: '/teacher-dashboard-student',
          builder: (context, state) {
            final auth = ref.watch(authProvider);
            return auth.isAuthenticated ? const TeacherDashboardStudent() : const LoginScreen();
          },
        ),

        // 📚 GESTION DES COURS (TEACHER)
        GoRoute(
          path: '/courses',
          builder: (context, state) {
            final auth = ref.watch(authProvider);
            return auth.isAuthenticated ? const CoursesScreen() : const LoginScreen();
          },
        ),

        // 💡 ROUTE DE L'ÉTUDIANT (LessonStudentScreen)
        GoRoute(
          path: '/lessons',
          builder: (context, state) {
            final auth = ref.watch(authProvider);
            if (!auth.isAuthenticated) return const LoginScreen();

            final data = state.extra as Map<String, dynamic>?;
            if (data == null) {
              return const Scaffold(
                body: Center(child: Text('❌ Aucun cours sélectionné')),
              );
            }

            return LessonStudentScreen(
              courseId: data['courseId'] as int,
              courseTitle: data['courseTitle'] as String,
              sessionId: data['sessionId'] as String,
            );
          },
        ),

        // 🏠 ACCUEIL ÉTUDIANT
        GoRoute(
          path: '/student',
          builder: (context, state) {
            final auth = ref.watch(authProvider);
            return auth.isAuthenticated ? const HomeStudent() : const LoginScreen();
          },
        ),

        // 🎓 MES INSCRIPTIONS (STUDENT)
        GoRoute(
          path: '/my-courses',
          builder: (context, state) {
            final auth = ref.watch(authProvider);
            return auth.isAuthenticated ? const MyCoursesScreen() : const LoginScreen();
          },
        ),

        GoRoute(path: '/', builder: (_, __) => const LoginScreen()),
      ],
      errorBuilder: (context, state) => Scaffold(
        appBar: AppBar(title: const Text('Page introuvable')),
        body: Center(
          child: ElevatedButton(
            onPressed: () => context.go('/login'),
            child: const Text('Retour à la connexion'),
          ),
        ),
      ),
    );

    return MaterialApp.router(
      title: 'Elearning AI Platform',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
      ),
    );
  }
}
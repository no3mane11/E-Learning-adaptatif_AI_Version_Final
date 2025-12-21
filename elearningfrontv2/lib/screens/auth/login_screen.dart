import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/validators.dart';
import '../../core/utils/helpers.dart';
import '../../core/providers/auth_provider.dart';

import '../../shared/widgets/buttons/primary_button.dart';
import '../../shared/widgets/buttons/button_size.dart';
import '../../shared/widgets/inputs/text_input.dart';
import '../../shared/widgets/role_selector.dart';

/// Écran de connexion
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String _selectedRole = 'student';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // -----------------------------
  // ROLE HELPERS
  // -----------------------------

  String? _roleFromUser(AuthState state) {
    final user = state.user;
    if (user == null) return null;
    final raw = user['role'];
    if (raw == null) return null;
    return raw.toString().toUpperCase();
  }

  String? _roleFromToken(String? token) {
    if (token == null) return null;
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final map = json.decode(payload) as Map<String, dynamic>;
      final role = map['role'];
      return role?.toString().toUpperCase();
    } catch (_) {
      return null;
    }
  }

  String _normalizeRole(String? raw) {
    if (raw == null) return '';
    var r = raw.toUpperCase().trim();
    if (r.startsWith('ROLE_')) r = r.substring(5);
    return r;
  }

  // -----------------------------
  // LOGIN HANDLER
  // -----------------------------
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(authProvider.notifier).login(
            _emailController.text.trim(),
            _passwordController.text,
          );

      final authState = ref.read(authProvider);

      if (!authState.isAuthenticated || authState.user == null) {
        Helpers.showSnackBar(
          context,
          authState.error ?? 'Erreur de connexion',
          backgroundColor: AppColors.error,
        );
        return;
      }

      // 🔑 Détermination du rôle
      final role = _normalizeRole(
        _roleFromUser(authState) ??
            _roleFromToken(authState.token) ??
            _selectedRole,
      );

      Helpers.showSnackBar(
        context,
        '✅ Connexion réussie',
        backgroundColor: AppColors.primary,
      );

      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;

      // 🚦 REDIRECTION SELON LE RÔLE
      if (role == 'TEACHER') {
        context.go('/professor');
      } else if (role == 'STUDENT') {
        context.go('/student');
      } else {
        // sécurité
        context.go('/login');
      }
    } catch (e) {
      Helpers.showSnackBar(
        context,
        '❌ ${e.toString()}',
        backgroundColor: AppColors.error,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // -----------------------------
  // UI
  // -----------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: AppSpacing.xxl),

                Icon(Icons.school, size: 64, color: AppColors.primary)
                    .animate()
                    .fadeIn()
                    .scale(),

                SizedBox(height: AppSpacing.lg),

                Text(
                  'Connexion',
                  style: AppTextStyles.h1,
                  textAlign: TextAlign.center,
                ).animate().fadeIn(),

                SizedBox(height: AppSpacing.sm),

                Text(
                  'Connectez-vous pour continuer',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: AppSpacing.xxl),

                RoleSelector(
                  selectedRole: _selectedRole,
                  onRoleChanged: (r) => setState(() => _selectedRole = r),
                ),

                SizedBox(height: AppSpacing.lg),

                TextInput(
                  label: 'Email',
                  hint: 'votre@email.com',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email,
                  prefixIcon: const Icon(Icons.email),
                ),

                SizedBox(height: AppSpacing.md),

                TextInput(
                  label: 'Mot de passe',
                  hint: '••••••••',
                  controller: _passwordController,
                  obscureText: true,
                  validator: Validators.password,
                  prefixIcon: const Icon(Icons.lock),
                  onSubmitted: (_) => _handleLogin(),
                ),

                SizedBox(height: AppSpacing.xl),

                PrimaryButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  label: 'Se connecter',
                  isLoading: _isLoading,
                  size: ButtonSize.large,
                ),

                SizedBox(height: AppSpacing.md),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Pas encore de compte ?'),
                    TextButton(
                      onPressed: () => context.go('/signup'),
                      child: const Text('S’inscrire'),
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
}

// lib/screens/auth/signup_screen.dart
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

/// Écran d'inscription
class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String _selectedRole = 'student';

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _extractRoleFromToken(String? token) {
    if (token == null) return null;
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final Map<String, dynamic> map =
          json.decode(decoded) as Map<String, dynamic>;
      final role =
          (map['role'] ?? map['roles'] ?? map['authorities'] ?? map['authority']);
      if (role == null) return null;
      if (role is List && role.isNotEmpty) {
        return role.first.toString().toUpperCase();
      }
      return role.toString().toUpperCase();
    } catch (_) {
      return null;
    }
  }

  String? _getUserRoleFromState(AuthState authState) {
    final user = authState.user;
    if (user == null) return null;
    try {
      if (user is Map<String, dynamic>) {
        final r = user['role'] ?? user['roles'] ?? user['authority'] ?? user['authorities'];
        if (r == null) return null;
        if (r is List && r.isNotEmpty) return r.first.toString().toUpperCase();
        return r.toString().toUpperCase();
      }
      return user.toString().toUpperCase();
    } catch (_) {
      return null;
    }
  }

  /// Mappe diverses variantes (fr/en/fautes) vers TEACHER ou STUDENT
  String _mapRoleToServer(String raw) {
    final r = (raw ?? '').toString().trim().toLowerCase();
    if (r.contains('teach') || r.contains('prof') || r.contains('professeur')) {
      return 'TEACHER';
    }
    return 'STUDENT';
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(authProvider.notifier);

      // Normalize + map role to server-friendly values
      final rawRole = _selectedRole;
      final roleToSend = _mapRoleToServer(rawRole);
      debugPrint('DEBUG signup: selectedRole="$rawRole" -> roleToSend="$roleToSend"');

      await notifier.register(
        nom: '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: roleToSend,
      );

      final authState = ref.read(authProvider);

      // UX: send user to /login after register success (do not auto-login here)
      if (authState.error == null) {
        if (!mounted) return;
        Helpers.showSnackBar(
          context,
          '✅ Inscription réussie — veuillez vous connecter.',
          backgroundColor: AppColors.primary,
        );
        // small delay to let user see the snackbar, then go to login
        await Future.delayed(const Duration(milliseconds: 600));
        if (!mounted) return;
        context.go('/login');
      } else {
        // failure
        if (!mounted) return;
        Helpers.showSnackBar(
          context,
          '❌ ${authState.error ?? 'Erreur d\'inscription'}',
          backgroundColor: AppColors.error,
        );
      }
    } catch (e) {
      if (!mounted) return;
      Helpers.showSnackBar(
        context,
        '❌ ${e.toString()}',
        backgroundColor: AppColors.error,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: AppSpacing.lg),
                Text(
                  'Créer un compte',
                  style: AppTextStyles.h1,
                  textAlign: TextAlign.center,
                )
                    .animate()
                    .fadeIn(
                      delay: 100.ms,
                      duration: 600.ms,
                    )
                    .slideY(
                      begin: 0.2,
                      end: 0,
                      delay: 100.ms,
                      duration: 600.ms,
                      curve: Curves.easeOutCubic,
                    ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  'Rejoignez-nous pour commencer',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                )
                    .animate()
                    .fadeIn(
                      delay: 200.ms,
                      duration: 600.ms,
                    ),
                SizedBox(height: AppSpacing.xxl),
                // Role selector
                RoleSelector(
                  selectedRole: _selectedRole,
                  onRoleChanged: (role) {
                    setState(() {
                      _selectedRole = role;
                    });
                  },
                )
                    .animate()
                    .fadeIn(
                      delay: 250.ms,
                      duration: 600.ms,
                    ),
                SizedBox(height: AppSpacing.lg),
                // First name
                TextInput(
                  label: 'Prénom',
                  hint: 'Jean',
                  controller: _firstNameController,
                  validator: (v) => Validators.required(v, fieldName: 'Le prénom'),
                  prefixIcon: const Icon(Icons.person_outline),
                )
                    .animate()
                    .fadeIn(
                      delay: 350.ms,
                      duration: 600.ms,
                    ),
                SizedBox(height: AppSpacing.md),
                // Last name
                TextInput(
                  label: 'Nom',
                  hint: 'Dupont',
                  controller: _lastNameController,
                  validator: (v) => Validators.required(v, fieldName: 'Le nom'),
                  prefixIcon: const Icon(Icons.person_outline),
                )
                    .animate()
                    .fadeIn(
                      delay: 450.ms,
                      duration: 600.ms,
                    ),
                SizedBox(height: AppSpacing.md),
                // Email
                TextInput(
                  label: 'Email',
                  hint: 'votre@email.com',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email,
                  prefixIcon: const Icon(Icons.email_outlined),
                )
                    .animate()
                    .fadeIn(
                      delay: 550.ms,
                      duration: 600.ms,
                    ),
                SizedBox(height: AppSpacing.md),
                // Password
                TextInput(
                  label: 'Mot de passe',
                  hint: '••••••••',
                  controller: _passwordController,
                  obscureText: true,
                  validator: Validators.password,
                  prefixIcon: const Icon(Icons.lock_outline),
                )
                    .animate()
                    .fadeIn(
                      delay: 650.ms,
                      duration: 600.ms,
                    ),
                SizedBox(height: AppSpacing.md),
                // Confirm password
                TextInput(
                  label: 'Confirmer le mot de passe',
                  hint: '••••••••',
                  controller: _confirmPasswordController,
                  obscureText: true,
                  validator: (v) => Validators.confirmPassword(
                    v,
                    _passwordController.text,
                  ),
                  prefixIcon: const Icon(Icons.lock_outline),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _handleSignup(),
                )
                    .animate()
                    .fadeIn(
                      delay: 750.ms,
                      duration: 600.ms,
                    ),
                SizedBox(height: AppSpacing.xl),
                // Signup button
                PrimaryButton(
                  onPressed: _isLoading ? null : _handleSignup,
                  label: 'S\'inscrire',
                  isLoading: _isLoading,
                  size: ButtonSize.large,
                )
                    .animate()
                    .fadeIn(
                      delay: 850.ms,
                      duration: 600.ms,
                    ),
                SizedBox(height: AppSpacing.md),
                // Login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Déjà un compte ? ',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: Text(
                        'Se connecter',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                )
                    .animate()
                    .fadeIn(
                      delay: 950.ms,
                      duration: 600.ms,
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

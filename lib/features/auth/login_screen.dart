import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:is_he_dead/features/auth/auth_provider.dart';
import 'package:is_he_dead/core/theme/vault_styles.dart';
import 'package:is_he_dead/core/utils/toast_utils.dart';
import 'package:is_he_dead/core/utils/error_parser.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref
          .read(authServiceProvider)
          .signInWithEmailAndPassword(
            _emailController.text,
            _passwordController.text,
          );
    } catch (e) {
      if (mounted) {
        ToastUtils.showError(context, ErrorParser.parse(e));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _googleLogin() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authServiceProvider).signInWithGoogle();
    } catch (e) {
      if (mounted) {
        ToastUtils.showError(context, ErrorParser.parse(e));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Gradient Background
          Container(
            decoration: BoxDecoration(gradient: VaultStyles.bgGradient(isDark)),
          ),

          // 3. Content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo / Icon
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: VaultStyles.glassColor(isDark),
                      border: Border.all(
                        color: VaultStyles.glassBorderColor(isDark),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.lock_person_rounded,
                      size: 60,
                      color: VaultStyles.textColor(isDark),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Glassmorphism Card
                  ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: VaultStyles.glassColor(isDark),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: VaultStyles.glassBorderColor(isDark),
                          ),
                          boxShadow: VaultStyles.shadow(isDark),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Welcome Back',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: VaultStyles.textColor(isDark),
                                  letterSpacing: 1.2,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Sign in to your account',
                                style: TextStyle(
                                  color: VaultStyles.subTextColor(isDark),
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 32),

                              // Email Input
                              _GlassTextField(
                                controller: _emailController,
                                icon: Icons.email_outlined,
                                label: 'Email Address',
                                isDark: isDark,
                                validator: (v) =>
                                    v!.isEmpty ? 'Required' : null,
                              ),
                              const SizedBox(height: 20),

                              // Password Input
                              _GlassTextField(
                                controller: _passwordController,
                                icon: Icons.lock_outline,
                                label: 'Password',
                                isPassword: true,
                                isDark: isDark,
                                validator: (v) =>
                                    v!.isEmpty ? 'Required' : null,
                              ),
                              const SizedBox(height: 32),

                              // Login Button
                              ElevatedButton(
                                onPressed: _isLoading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  backgroundColor: isDark
                                      ? Colors.white
                                      : Colors.deepPurple,
                                  foregroundColor: isDark
                                      ? Colors.deepPurple.shade900
                                      : Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                                child: _isLoading
                                    ? SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          color: isDark
                                              ? Colors.deepPurple
                                              : Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        'SIGN IN',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1,
                                        ),
                                      ),
                              ),

                              const SizedBox(height: 24),

                              // Divider
                              Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color: VaultStyles.glassBorderColor(
                                        isDark,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    child: Text(
                                      "OR",
                                      style: TextStyle(
                                        color: VaultStyles.subTextColor(isDark),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: VaultStyles.glassBorderColor(
                                        isDark,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),

                              // Social Login
                              OutlinedButton.icon(
                                onPressed: _isLoading ? null : _googleLogin,
                                icon: Icon(
                                  Icons.g_mobiledata,
                                  size: 28,
                                  color: VaultStyles.textColor(isDark),
                                ),
                                label: Text(
                                  "Sign in with Google",
                                  style: TextStyle(
                                    color: VaultStyles.textColor(isDark),
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: VaultStyles.textColor(
                                    isDark,
                                  ),
                                  side: BorderSide(
                                    color: VaultStyles.glassBorderColor(isDark),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Register Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "First time here? ",
                        style: TextStyle(
                          color: VaultStyles.subTextColor(isDark),
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/register'),
                        child: Text(
                          'Create Account',
                          style: TextStyle(
                            color: VaultStyles.textColor(isDark),
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                            decorationColor: VaultStyles.textColor(isDark),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final IconData icon;
  final String label;
  final bool isPassword;
  final bool isDark;
  final String? Function(String?)? validator;

  const _GlassTextField({
    required this.controller,
    required this.icon,
    required this.label,
    required this.isDark,
    this.isPassword = false,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      style: TextStyle(color: VaultStyles.textColor(isDark)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: VaultStyles.subTextColor(isDark)),
        prefixIcon: Icon(icon, color: VaultStyles.iconColor(isDark)),
        fillColor: VaultStyles.inputFillColor(isDark),
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: VaultStyles.glassBorderColor(isDark)),
        ),
      ),
      validator: validator,
    );
  }
}

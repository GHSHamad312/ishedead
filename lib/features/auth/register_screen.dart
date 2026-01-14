import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:is_he_dead/features/auth/auth_provider.dart';
import 'package:is_he_dead/features/profile/services/profile_service.dart';
import 'package:is_he_dead/features/profile/models/user_profile.dart';
import 'package:is_he_dead/core/theme/vault_styles.dart';
import 'package:is_he_dead/core/common/glass_phone_field.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _fullPhoneNumber = '';
  bool _isLoading = false;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      if (_passwordController.text != _confirmPasswordController.text) {
        throw 'Passwords do not match';
      }

      // 1. Create Auth User
      final cred = await ref
          .read(authServiceProvider)
          .createUserWithEmailAndPassword(
            _emailController.text.trim(),
            _passwordController.text,
          );

      // 2. Create User Profile
      if (cred.user != null) {
        final newProfile = UserProfile(
          uid: cred.user!.uid,
          email: _emailController.text.trim(),
          fullName: _nameController.text.trim(),
          phone: _fullPhoneNumber,
          lastCheckIn: DateTime.now(),
          registrationPaid: false,
          status: 'Active',
        );
        await ref.read(profileServiceProvider).createUserProfile(newProfile);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(''),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: VaultStyles.textColor(isDark)),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: Stack(
        children: [
          // 1. Gradient Background
          Container(
            decoration: BoxDecoration(gradient: VaultStyles.bgGradient(isDark)),
          ),

          // 2. Content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: VaultStyles.glassColor(isDark),
                      border: Border.all(
                        color: VaultStyles.glassBorderColor(isDark),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.person_add_rounded,
                      size: 40,
                      color: VaultStyles.textColor(isDark),
                    ),
                  ),
                  const SizedBox(height: 30),

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
                                'Start Your Legacy',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: VaultStyles.textColor(isDark),
                                  letterSpacing: 1.0,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Join the secure protection network',
                                style: TextStyle(
                                  color: VaultStyles.subTextColor(isDark),
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 32),

                              // Name Input
                              _GlassTextField(
                                controller: _nameController,
                                icon: Icons.person_outline,
                                label: 'Full Name',
                                isDark: isDark,
                                validator: (v) =>
                                    v!.isEmpty ? 'Required' : null,
                              ),
                              const SizedBox(height: 16),

                              // Phone Input
                              GlassPhoneField(
                                label: 'Phone Number',
                                isDark: isDark,
                                onChanged: (phone) {
                                  _fullPhoneNumber = phone.completeNumber;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Email Input
                              _GlassTextField(
                                controller: _emailController,
                                icon: Icons.email_outlined,
                                label: 'Email',
                                isDark: isDark,
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) =>
                                    v!.isEmpty ? 'Required' : null,
                              ),
                              const SizedBox(height: 16),

                              // Password Input
                              _GlassTextField(
                                controller: _passwordController,
                                icon: Icons.lock_outline,
                                label: 'Password',
                                isPassword: true,
                                isDark: isDark,
                                validator: (v) =>
                                    v!.length < 6 ? 'Min 6 chars' : null,
                              ),
                              const SizedBox(height: 16),

                              // Confirm Password
                              _GlassTextField(
                                controller: _confirmPasswordController,
                                icon: Icons.lock_outline,
                                label: 'Confirm Password',
                                isPassword: true,
                                isDark: isDark,
                                validator: (v) =>
                                    v!.isEmpty ? 'Required' : null,
                              ),
                              const SizedBox(height: 32),

                              // Register Button
                              ElevatedButton(
                                onPressed: _isLoading ? null : _register,
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
                                        'CREATE ACCOUNT',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1,
                                        ),
                                      ),
                              ),

                              const SizedBox(height: 24),

                              // Login Link
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Already have an account? ",
                                    style: TextStyle(
                                      color: VaultStyles.subTextColor(isDark),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => context.go('/login'),
                                    child: Text(
                                      'Sign In',
                                      style: TextStyle(
                                        color: VaultStyles.textColor(isDark),
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                                        decorationColor: VaultStyles.textColor(
                                          isDark,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
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

// Sharing the same widget logic, duplicated here to be self-contained within file.
// In a larger refactor, this should move to a shared widgets folder.
// Sharing the same widget logic, duplicated here to be self-contained within file.
// In a larger refactor, this should move to a shared widgets folder.
class _GlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final IconData icon;
  final String label;
  final bool isPassword;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final bool isDark;

  const _GlassTextField({
    required this.controller,
    required this.icon,
    required this.label,
    required this.isDark,
    this.isPassword = false,
    this.validator,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
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

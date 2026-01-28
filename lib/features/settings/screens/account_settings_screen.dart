import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl_phone_field/countries.dart';
import 'package:is_he_dead/core/common/glass_phone_field.dart';
import 'package:is_he_dead/core/theme/vault_styles.dart';
import 'package:is_he_dead/features/auth/auth_provider.dart';
import 'package:is_he_dead/features/profile/services/profile_service.dart';
import 'package:is_he_dead/core/utils/toast_utils.dart';
import 'package:is_he_dead/core/utils/error_parser.dart';

class AccountSettingsScreen extends ConsumerStatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  ConsumerState<AccountSettingsScreen> createState() =>
      _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends ConsumerState<AccountSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  String _fullPhoneNumber = '';

  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userProfile = ref.read(userProfileProvider).value;
    if (userProfile != null) {
      _nameController.text = userProfile.fullName ?? '';
      _emailController.text = userProfile.email;
      _fullPhoneNumber = userProfile.phone ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  String _getCountryCode(String phone) {
    if (phone.isEmpty) return 'US';
    // Remove formatting
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');

    dynamic bestMatch;
    int maxLen = 0;

    // Iterate through countries to find the longest dial code match
    for (final country in countries) {
      final dialCode = country.dialCode;
      // Check if phone starts with dial code (allowing for +)
      if (cleanPhone.startsWith('+$dialCode') ||
          cleanPhone.startsWith(dialCode)) {
        if (dialCode.length > maxLen) {
          maxLen = dialCode.length;
          bestMatch = country;
        }
      }
    }

    if (bestMatch != null) {
      return bestMatch.code;
    }
    return 'US'; // Default fallback
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final user = ref.read(authServiceProvider).currentUser;
      if (user != null) {
        await ref.read(profileServiceProvider).updateUserProfile(user.uid, {
          'full_name': _nameController.text.trim(),
          'phone': _fullPhoneNumber,
        });

        if (mounted) {
          final theme = Theme.of(context);
          final isDark = theme.brightness == Brightness.dark;

          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (c) => Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.black.withOpacity(0.8)
                              : Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                color: Colors.green,
                                size: 40,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              "Succcess!",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Your account details have been updated.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 32),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(c);
                                  setState(() => _isEditing = false);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text(
                                  "Awesome",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.showError(context, ErrorParser.parse(e));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final userProfileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          "Account Settings",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: VaultStyles.textColor(isDark),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: VaultStyles.iconColor(isDark)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(), // Explicit pop
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (_isEditing) {
                _updateProfile();
              } else {
                setState(() => _isEditing = true);
              }
            },
            child: _isLoading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.primaryColor,
                    ),
                  )
                : Text(
                    _isEditing ? "Done" : "Edit",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDark ? Colors.white : theme.primaryColor,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // 1. Background
          Container(
            decoration: BoxDecoration(
              color: isDark ? null : Colors.white,
              gradient: isDark ? VaultStyles.bgGradient(isDark) : null,
            ),
          ),

          // 2. Content
          userProfileAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text("Error: $e")),
            data: (profile) {
              if (profile == null) {
                return const Center(child: Text("Profile not found"));
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 100, 20, 20),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Avatar Section
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: VaultStyles.glassColor(isDark),
                                border: Border.all(
                                  color: VaultStyles.glassBorderColor(isDark),
                                  width: 2,
                                ),
                                boxShadow: VaultStyles.shadow(isDark),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                (profile.fullName?.isNotEmpty == true)
                                    ? profile.fullName![0].toUpperCase()
                                    : 'U',
                                style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: VaultStyles.textColor(isDark),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Glass Container for Personal Info
                      _GlassSection(
                        isDark: isDark,
                        title: "Personal Information",
                        children: [
                          _GlassTextField(
                            controller: _nameController,
                            label: "Full Name",
                            icon: Icons.person_outline_rounded,
                            isDark: isDark,
                            enabled: _isEditing,
                            isPassword: false,
                          ),
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              color: VaultStyles.inputFillColor(isDark),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.transparent),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.phone_outlined,
                                  color: VaultStyles.iconColor(isDark),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: GlassPhoneField(
                                    label: '',
                                    initialValue: _fullPhoneNumber,
                                    initialCountryCode: _getCountryCode(
                                      _fullPhoneNumber,
                                    ),
                                    isDark: isDark,
                                    fillColor: Colors.transparent,
                                    showLabel: false,
                                    enabled: _isEditing,
                                    onChanged: (phone) {
                                      if (_isEditing) {
                                        _fullPhoneNumber = phone.completeNumber;
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Glass Container for Security
                      _GlassSection(
                        isDark: isDark,
                        title: "Security",
                        children: [
                          _GlassTextField(
                            controller: _emailController,
                            label: "Email Address",
                            icon: Icons.email_outlined,
                            isDark: isDark,
                            enabled: false,
                            isPassword: false,
                          ),
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: () async {
                              try {
                                await ref
                                    .read(authServiceProvider)
                                    .sendPasswordResetEmail(profile.email);
                                if (context.mounted) {
                                  ToastUtils.showSuccess(
                                    context,
                                    "Password reset email sent to ${profile.email}",
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ToastUtils.showError(
                                    context,
                                    ErrorParser.parse(e),
                                  );
                                }
                              }
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.redAccent.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(
                                    Icons.lock_reset,
                                    color: Colors.redAccent,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    "Reset Password",
                                    style: TextStyle(
                                      color: Colors.redAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _GlassSection extends StatelessWidget {
  final bool isDark;
  final String title;
  final List<Widget> children;

  const _GlassSection({
    required this.isDark,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: VaultStyles.subTextColor(isDark),
            ),
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: VaultStyles.glassColor(isDark),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: VaultStyles.glassBorderColor(isDark)),
                boxShadow: VaultStyles.shadow(isDark),
              ),
              child: Column(children: children),
            ),
          ),
        ),
      ],
    );
  }
}

class _GlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final IconData icon;
  final String label;
  final bool isPassword;
  final bool isDark;
  final bool enabled;

  const _GlassTextField({
    required this.controller,
    required this.icon,
    required this.label,
    required this.isPassword,
    required this.isDark,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      enabled: enabled,
      style: TextStyle(
        color: enabled
            ? VaultStyles.textColor(isDark)
            : VaultStyles.subTextColor(isDark),
      ),
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
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: VaultStyles.glassBorderColor(isDark)),
        ),
      ),
    );
  }
}

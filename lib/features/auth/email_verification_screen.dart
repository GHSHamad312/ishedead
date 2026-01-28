import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:is_he_dead/features/auth/auth_provider.dart';
import 'package:is_he_dead/core/utils/toast_utils.dart';
import 'package:is_he_dead/core/utils/error_parser.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  Timer? _timer;
  bool _canResend = true;
  int _resendCooldown = 0;

  @override
  void initState() {
    super.initState();
    // Start periodic check
    _timer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _checkEmailVerified(),
    );

    // Initial check
    _checkEmailVerified();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkEmailVerified() async {
    final authService = ref.read(authServiceProvider);
    await authService.reloadUser();

    final user = authService.currentUser;
    if (user != null && user.emailVerified) {
      _timer?.cancel();
      if (mounted) {
        ToastUtils.showSuccess(context, "Email successfully verified!");
        // The router redirect logic should automatically pick this up,
        // but we can also explicitly pop or refresh checks if needed.
        // We trigger a provider refresh via the service call indirectly,
        // but let's ensure global state knows.
        ref.invalidate(authStateProvider); // Force refresh of auth state
      }
    }
  }

  Future<void> _sendVerificationEmail() async {
    if (!_canResend) return;

    try {
      await ref.read(authServiceProvider).sendEmailVerification();

      setState(() {
        _canResend = false;
        _resendCooldown = 60;
      });

      ToastUtils.showSuccess(context, "Verification email sent.");

      // Start cooldown timer
      Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() {
          if (_resendCooldown > 0) {
            _resendCooldown--;
          } else {
            _canResend = true;
            timer.cancel();
          }
        });
      });
    } catch (e) {
      if (mounted) {
        ToastUtils.showError(context, ErrorParser.parse(e));
      }
    }
  }

  Future<void> _signOut() async {
    _timer?.cancel();
    await ref.read(authServiceProvider).signOut();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(authServiceProvider).currentUser;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF1E1E2C), const Color(0xFF000000)]
                : [const Color(0xFFF5F5FA), const Color(0xFFFFFFFF)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.deepPurpleAccent.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mark_email_unread_outlined,
                    size: 64,
                    color: Colors.deepPurpleAccent,
                  ),
                ),
                const SizedBox(height: 32),

                // Title
                Text(
                  "Verify your email",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),

                // Description
                Text(
                  "We've sent a verification link to:\n${user?.email ?? 'your email'}",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Please check your inbox (and spam folder) and click the link to verify your account. The app will automatically update once verified.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: isDark ? Colors.grey[500] : Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 48),

                // Resend Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _canResend ? _sendVerificationEmail : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurpleAccent,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: isDark
                          ? Colors.white10
                          : Colors.grey[300],
                      disabledForegroundColor: isDark
                          ? Colors.white38
                          : Colors.grey[500],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      _canResend
                          ? "Resend Email"
                          : "Resend in ${_resendCooldown}s",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Sign Out Button
                TextButton(
                  onPressed: _signOut,
                  style: TextButton.styleFrom(
                    foregroundColor: isDark ? Colors.white70 : Colors.black54,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.logout, size: 20),
                      SizedBox(width: 8),
                      Text("Sign Out"),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

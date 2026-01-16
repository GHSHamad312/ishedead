import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:is_he_dead/core/services/notification_service.dart';
import 'package:is_he_dead/features/auth/auth_provider.dart';
import 'package:is_he_dead/features/profile/services/profile_service.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Timer? _timer;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    ref.read(notificationServiceProvider).init();
    ref.read(notificationServiceProvider).scheduleDailyCheckInReminder();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Update UI every second for countdown
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.read(authServiceProvider).currentUser;
    final userProfileAsync = ref.watch(userProfileProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Dynamic Colors
    final gradientColors = isDark
        ? [Colors.deepPurple, Colors.black87]
        : [Colors.deepPurple.shade50, Colors.white]; // Light mode gradient

    final textColor = isDark ? Colors.white : Colors.black87;
    final iconColor = isDark ? Colors.white : Colors.deepPurple;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_none, color: iconColor),
            onPressed: () {},
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: gradientColors,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Status Indicator
              // Status Indicator
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shield, color: Colors.green, size: 16),
                    const SizedBox(width: 8),
                    const Text(
                      "SYSTEM ACTIVE",
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Pulse Button
              GestureDetector(
                onTap: _isLoading
                    ? null
                    : () async {
                        if (user != null) {
                          HapticFeedback.heavyImpact();
                          setState(() => _isLoading = true);

                          try {
                            await ref
                                .read(profileServiceProvider)
                                .updateLastCheckIn(user.uid);

                            // Reschedule Notification
                            if (userProfileAsync.value != null) {
                              final freq =
                                  userProfileAsync.value!.checkInFrequency;
                              await ref
                                  .read(notificationServiceProvider)
                                  .scheduleOverdueNotification(
                                    Duration(hours: freq),
                                  );
                              await ref
                                  .read(notificationServiceProvider)
                                  .schedulePreDueNotification(
                                    Duration(hours: freq),
                                  );
                            }

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "I'm Alive confirmed! Timer reset.",
                                  ),
                                  backgroundColor: Colors.green,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Error: $e"),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } finally {
                            if (mounted) setState(() => _isLoading = false);
                          }
                        }
                      },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ScaleTransition(
                      scale: Tween(begin: 1.0, end: 1.2).animate(
                        CurvedAnimation(
                          parent: _controller,
                          curve: Curves.easeInOut,
                        ),
                      ),
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark
                              ? Colors.deepPurpleAccent.withOpacity(0.3)
                              : Colors.purple.withOpacity(0.05),
                        ),
                      ),
                    ),
                    Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [Colors.purpleAccent, Colors.deepPurple]
                              : [
                                  const Color(0xFFCE93D8),
                                  const Color(0xFF7E57C2),
                                ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.purple.withOpacity(0.5)
                                : Colors.deepPurple.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Opacity(
                            opacity: _isLoading ? 0.6 : 1.0,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.fingerprint,
                                  size: 50,
                                  color: Colors.white,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  "I AM ALIVE",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                if (userProfileAsync.value != null) ...[
                                  const SizedBox(height: 4),
                                  Builder(
                                    builder: (context) {
                                      final profile = userProfileAsync.value!;
                                      final deadline = profile.lastCheckIn.add(
                                        Duration(
                                          hours: profile.checkInFrequency,
                                        ),
                                      );
                                      final remaining = deadline.difference(
                                        DateTime.now(),
                                      );

                                      if (remaining.isNegative) {
                                        return const Text(
                                          "OVERDUE",
                                          style: TextStyle(
                                            color: Colors.redAccent,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 12,
                                            letterSpacing: 1,
                                          ),
                                        );
                                      }

                                      final days = remaining.inDays;
                                      final hours = remaining.inHours % 24;
                                      final minutes = remaining.inMinutes % 60;
                                      final seconds = remaining.inSeconds % 60;

                                      String timerText = "";
                                      if (days > 0) timerText += "${days}d ";
                                      timerText +=
                                          "${hours}h ${minutes}m ${seconds}s";

                                      return Text(
                                        timerText,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                          fontFamily:
                                              'Courier', // Monospace for timer
                                          fontWeight: FontWeight.bold,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (_isLoading)
                            const SizedBox(
                              width: 156,
                              height: 156,
                              child: CircularProgressIndicator(
                                strokeWidth: 5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 32.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildQuickAction(
                      context,
                      Icons.medical_services_outlined,
                      "Medical ID",
                      () => context.push('/medical-id'),
                      isDark,
                    ),
                    _buildQuickAction(
                      context,
                      Icons.lock_outline,
                      "Safety Vault",
                      () => context.push('/upload-doc'),
                      isDark,
                    ),
                    _buildQuickAction(
                      context,
                      Icons.account_tree_outlined,
                      "Protocol", // Shortened for cleaner alignment
                      () => context.push('/protocol-status'),
                      isDark,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
    bool isDark,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        Colors.deepPurpleAccent.withOpacity(0.4),
                        Colors.deepPurple.withOpacity(0.1),
                      ]
                    : [Colors.white, Colors.deepPurple.shade50],
              ),
              border: Border.all(
                color: isDark ? Colors.white24 : Colors.white,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black26
                      : Colors.deepPurple.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: isDark ? Colors.white : Colors.deepPurple,
              size: 28,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.deepPurple.shade800,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

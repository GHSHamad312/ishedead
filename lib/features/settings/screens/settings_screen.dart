import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:is_he_dead/core/providers/theme_provider.dart';
import 'package:is_he_dead/features/auth/auth_provider.dart';
import 'package:is_he_dead/features/profile/services/profile_service.dart';
import 'package:is_he_dead/core/services/notification_service.dart';
import '../../../core/services/biometric_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadBiometricStatus();
  }

  Future<void> _loadBiometricStatus() async {
    final enabled = await ref
        .read(biometricServiceProvider)
        .isBiometricEnabled();
    if (mounted) {
      setState(() {
        _biometricEnabled = enabled;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final user = ref.watch(authServiceProvider).currentUser;
    final userProfileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(title: const Text("Settings"), centerTitle: false),
          SliverToBoxAdapter(
            child: userProfileAsync.when(
              data: (profile) {
                final isSafetyMode = profile?.isSafetyModeEnabled ?? false;
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionHeader(title: "Account"),
                      _SettingsGroup(
                        children: [
                          _SettingsTile(
                            icon: Icons.person_outline_rounded,
                            title: user?.email ?? "User Profile",
                            subtitle: "Manage details & contacts",
                            onTap: () => context.go('/profile'),
                            showArrow: true,
                          ),
                          _SettingsTile(
                            icon: Icons.logout_rounded,
                            title: "Sign Out",
                            iconColor: Colors.redAccent,
                            textColor: Colors.redAccent,
                            onTap: () =>
                                ref.read(authServiceProvider).signOut(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _SectionHeader(title: "Monitoring & Safety"),
                      _SettingsGroup(
                        children: [
                          _SettingsSwitchTile(
                            icon: isSafetyMode
                                ? Icons.pause_circle_outline_rounded
                                : Icons.shield_outlined,
                            title: "Safety Mode",
                            subtitle: isSafetyMode
                                ? "Monitoring Paused"
                                : "System Active",
                            activeColor: Colors.amber,
                            iconColor: isSafetyMode
                                ? Colors.amber
                                : Colors.green,
                            value: isSafetyMode,
                            onChanged: (val) async {
                              if (user != null) {
                                await ref
                                    .read(profileServiceProvider)
                                    .toggleSafetyMode(user.uid, val);
                                final notifs = ref.read(
                                  notificationServiceProvider,
                                );
                                if (val) {
                                  await notifs.cancelAllNotifications();
                                } else {
                                  await notifs.scheduleDailyCheckInReminder();
                                }
                              }
                            },
                          ),
                          _SettingsTile(
                            icon: Icons.timer_outlined,
                            title: "Check-in Frequency",
                            subtitle:
                                "Every ${profile?.checkInFrequency ?? 24} Hours",
                            onTap: () => _showCheckInFrequencyDialog(
                              context,
                              profile?.checkInFrequency ?? 24,
                            ),
                            showArrow: true,
                          ),
                          _SettingsTile(
                            icon: Icons.notifications_active_outlined,
                            title: "Test Alert",
                            subtitle: "Simulate emergency protocol",
                            onTap: () => _showTestAlertDialog(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _SectionHeader(title: "App Preferences"),
                      _SettingsGroup(
                        children: [
                          _SettingsSwitchTile(
                            icon: Icons.dark_mode_outlined,
                            title: "Dark Mode",
                            value: themeMode == ThemeMode.dark,
                            activeColor: Colors.white, // User requested white
                            onChanged: (val) {
                              ref
                                  .read(themeProvider.notifier)
                                  .setTheme(
                                    val ? ThemeMode.dark : ThemeMode.light,
                                  );
                            },
                          ),
                          _SettingsSwitchTile(
                            icon: Icons.fingerprint,
                            title: "Biometric Lock",
                            subtitle: "Require FaceID/TouchID",
                            value: _biometricEnabled,
                            onChanged: (val) => _toggleBiometric(val),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      Center(
                        child: Text(
                          "Version 1.0.0",
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 80), // Space for FAB/Nav
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text("Error: $e")),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showTestAlertDialog(BuildContext context) async {
    // Capture the stable parent context
    final parentContext = context;

    showModalBottomSheet(
      context: context,
      useRootNavigator:
          true, // IMPORTANT: Match with Navigator.of(..., rootNavigator: true)
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "Test Alert System",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.notifications_active,
                  color: Colors.amber,
                ),
                title: const Text("Simulate Local Notification"),
                subtitle: const Text(
                  "Triggers a test alert on this device (5s delay)",
                ),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  // Schedule a test notification for 5 seconds from now
                  await ref
                      .read(notificationServiceProvider)
                      .scheduleOverdueNotification(const Duration(seconds: 5));
                  if (parentContext.mounted) {
                    ScaffoldMessenger.of(parentContext).showSnackBar(
                      const SnackBar(
                        content: Text("Test Alert scheduled for 5 seconds."),
                      ),
                    );
                  }
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.email, color: Colors.blue),
                title: const Text("Test Email Alert"),
                subtitle: const Text("Sends a test email to all contacts"),
                onTap: () => _triggerCloudTest(parentContext, 'email'),
              ),
              ListTile(
                leading: const Icon(Icons.sms, color: Colors.green),
                title: const Text("Test SMS Alert"),
                subtitle: const Text("Sends a test SMS to all contacts"),
                onTap: () => _triggerCloudTest(parentContext, 'sms'),
              ),
              ListTile(
                leading: const Icon(Icons.call, color: Colors.red),
                title: const Text("Test Voice Call"),
                subtitle: const Text("Initiates a test call to all contacts"),
                onTap: () => _triggerCloudTest(parentContext, 'call'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _triggerCloudTest(BuildContext context, String type) async {
    // We expect 'context' to be the parent stable context.
    // Close the bottom sheet first.
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop(); // Close sheet
    }

    // Small delay to ensure sheet close animation doesn't conflict with dialog push
    await Future.delayed(const Duration(milliseconds: 300));

    if (!context.mounted) return;

    try {
      // Show loading
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (c) => const Center(child: CircularProgressIndicator()),
        );
      }

      final functions = FirebaseFunctions.instance;
      final result = await functions.httpsCallable('triggerTestAlert').call({
        'type': type,
      });

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();

        final data = result.data as Map<String, dynamic>;
        // Show result
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (c) => AlertDialog(
              title: Text(data['success'] ? "Success" : "Failed"),
              content: Text(data['message'] ?? "Operation completed."),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(c),
                  child: const Text("OK"),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      // Close loading if it's open (we can't easily know for sure, but assuming flow)
      // A cleaner way is to use a local key or just pop.
      if (context.mounted) {
        // Try to pop the loading indicator
        Navigator.of(context, rootNavigator: true).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _toggleBiometric(bool val) async {
    final bioService = ref.read(biometricServiceProvider);
    final available = await bioService.isBiometricAvailable();

    if (!available) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Biometrics not available on this device."),
          ),
        );
      }
      return;
    }

    if (val) {
      final success = await bioService.authenticate();
      if (!success) return;
    }

    await bioService.setBiometricEnabled(val);
    setState(() {
      _biometricEnabled = val;
    });
  }

  void _showCheckInFrequencyDialog(BuildContext context, int currentFreq) {
    int selectedFreq = currentFreq;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Check-in Frequency"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Every $selectedFreq hours",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Slider(
                    value: selectedFreq.toDouble(),
                    min: 12,
                    max: 72,
                    divisions: 5, // 12, 24, 36, 48, 60, 72
                    label: "$selectedFreq h",
                    activeColor: Colors.deepPurple,
                    onChanged: (val) {
                      setDialogState(() {
                        selectedFreq = val.round();
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "How often must you verify you are okay?",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    final user = ref.read(authServiceProvider).currentUser;
                    if (user != null) {
                      await ref
                          .read(profileServiceProvider)
                          .updateCheckInFrequency(user.uid, selectedFreq);

                      // Reschedule with new frequency
                      await ref
                          .read(notificationServiceProvider)
                          .scheduleOverdueNotification(
                            Duration(hours: selectedFreq),
                          );

                      await ref
                          .read(notificationServiceProvider)
                          .schedulePreDueNotification(
                            Duration(hours: selectedFreq),
                          );
                    }
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: Theme.of(context).hintColor,
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          // Lighter border in light mode, subtle in dark
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(
                    0.04,
                  ), // Subtle shadow for lift
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              Padding(
                padding: const EdgeInsets.only(left: 56),
                child: Divider(
                  height: 1,
                  thickness: 0.5,
                  color: isDark ? Colors.white10 : Colors.grey.shade100,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? textColor;
  final bool showArrow;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.iconColor,
    this.textColor,
    this.showArrow = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Determine dynamic colors
    final tileIconColor =
        iconColor ?? (isDark ? Colors.white : theme.primaryColor);
    final tileTextColor = textColor ?? (isDark ? Colors.white : Colors.black87);
    final tileSubtitleColor = isDark
        ? Colors.grey.shade400
        : Colors.grey.shade600;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: tileIconColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: tileIconColor),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: tileTextColor,
          fontSize: 15,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(fontSize: 13, color: tileSubtitleColor),
            )
          : null,
      trailing: showArrow
          ? Icon(
              Icons.chevron_right,
              color: isDark ? Colors.white30 : Colors.grey.shade300,
            )
          : null,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      tileColor: Colors.transparent, // Ensure no forced background
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? activeColor;
  final Color? iconColor;

  const _SettingsSwitchTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final tileIconColor =
        iconColor ?? (isDark ? Colors.white : theme.primaryColor);
    final tileTextColor = isDark ? Colors.white : Colors.black87;
    final tileSubtitleColor = isDark
        ? Colors.grey.shade400
        : Colors.grey.shade600;

    return SwitchListTile.adaptive(
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: tileIconColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: tileIconColor),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: tileTextColor,
          fontSize: 15,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(fontSize: 13, color: tileSubtitleColor),
            )
          : null,
      value: value,
      onChanged: onChanged,
      activeColor: activeColor ?? theme.primaryColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      tileColor: Colors.transparent,
      applyCupertinoTheme:
          true, // Vital for iOS/Mac switch visibility in dark mode
    );
  }
}

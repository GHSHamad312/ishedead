import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:is_he_dead/features/auth/auth_provider.dart';
import 'package:is_he_dead/features/profile/services/profile_service.dart';
import 'package:is_he_dead/features/profile/models/emergency_contact.dart';

class ProtocolStatusScreen extends ConsumerWidget {
  const ProtocolStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider);
    final user = ref.read(authServiceProvider).currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Colors
    final backgroundColor = isDark
        ? const Color(0xFF121212)
        : const Color(0xFFFAFAFA);
    final surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.white54 : Colors.grey[600];

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          "Protocol Overview",
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
        ),
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => context.pop(),
        ),
      ),
      body: userProfileAsync.when(
        data: (profile) {
          if (profile == null) return const Center(child: Text("Loading..."));

          final lastCheckIn = profile.lastCheckIn;
          final freq = profile.checkInFrequency;
          final deadline = lastCheckIn.add(Duration(hours: freq));
          final now = DateTime.now();

          // Tiers based on logic
          final tier1Time = deadline.add(const Duration(hours: 2));
          final tier2Time = deadline.add(const Duration(hours: 12));
          final tier3Time = deadline.add(const Duration(hours: 24));

          final isProtocolExecuted = profile.lastAlertTier >= 3;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Status Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isProtocolExecuted
                          ? [Colors.red.shade900, Colors.red.shade700]
                          : (isDark
                                ? [
                                    Colors.deepPurple.shade900,
                                    Colors.deepPurple.shade700,
                                  ]
                                : [Colors.deepPurple.shade50, Colors.white]),
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isProtocolExecuted
                          ? Colors.redAccent.withOpacity(0.5)
                          : (isDark
                                ? Colors.deepPurpleAccent.withOpacity(0.3)
                                : Colors.deepPurple.withOpacity(0.1)),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isProtocolExecuted
                            ? Colors.red.withOpacity(0.2)
                            : Colors.deepPurple.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        isProtocolExecuted
                            ? "PROTOCOL EXECUTED"
                            : "SYSTEM ACTIVE",
                        style: TextStyle(
                          color: isProtocolExecuted
                              ? Colors.redAccent
                              : (isDark ? Colors.greenAccent : Colors.green),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isProtocolExecuted
                            ? "Emergency Mode"
                            : "All Systems Normal",
                        style: TextStyle(
                          color: textColor,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isProtocolExecuted
                            ? "The dead man's switch protocol has been executed. Information released."
                            : "Monitoring user activity. No anomalies detected.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: hintColor),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
                Text(
                  "CRITICAL TIMELINE",
                  style: TextStyle(
                    color: hintColor,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 24),

                // Timeline
                _buildTimelineItem(
                  context,
                  time: lastCheckIn,
                  title: "Last Confirmation",
                  subtitle: "You tapped 'I Am Alive'",
                  icon: Icons.check_circle,
                  color: Colors.green,
                  isDark: isDark,
                  isPast: true,
                ),
                _buildTimelineLine(isDark, true),
                _buildTimelineItem(
                  context,
                  time: deadline,
                  title: "Deadline",
                  subtitle: "Next check-in required by this time",
                  icon: Icons.timer,
                  color: Colors.orange,
                  isDark: isDark,
                  isPast: now.isAfter(deadline),
                ),
                _buildTimelineLine(isDark, now.isAfter(deadline)),
                _buildTimelineItem(
                  context,
                  time: tier1Time,
                  title: "Alert Level 1",
                  subtitle:
                      "Email warning sent. Medical ID shared with capable contacts.",
                  icon: Icons.mark_email_read,
                  color: Colors.orangeAccent,
                  isDark: isDark,
                  isPast: now.isAfter(tier1Time),
                ),
                _buildTimelineLine(isDark, now.isAfter(tier1Time)),
                _buildTimelineItem(
                  context,
                  time: tier2Time,
                  title: "Alert Level 2",
                  subtitle: "Urgent SMS sent to vital contacts",
                  icon: Icons.sms_failed,
                  color: Colors.deepOrange,
                  isDark: isDark,
                  isPast: now.isAfter(tier2Time),
                ),
                _buildTimelineLine(isDark, now.isAfter(tier2Time)),
                _buildTimelineItem(
                  context,
                  time: tier3Time,
                  title: "PROTOCOL EXECUTED",
                  subtitle:
                      "Vault & Legacy Message released. Automated calls placed.",
                  icon: Icons.phonelink_ring,
                  color: Colors.red,
                  isDark: isDark,
                  isPast: now.isAfter(tier3Time),
                ),

                const SizedBox(height: 40),

                Text(
                  "DATA AUDIT",
                  style: TextStyle(
                    color: hintColor,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),

                // Contact Permissions Audit
                _buildContactAuditList(
                  ref,
                  user?.uid,
                  isDark,
                  surfaceColor,
                  textColor,
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text("Error: $e")),
      ),
    );
  }

  Widget _buildTimelineItem(
    BuildContext context, {
    required DateTime time,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
    required bool isPast,
  }) {
    final fmt = DateFormat('h:mm a, MMM d');
    final opacity = isPast ? 1.0 : 0.5;

    return Opacity(
      opacity: opacity,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  fmt.format(time),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineLine(bool isDark, bool isActive) {
    return Padding(
      padding: const EdgeInsets.only(left: 19.0),
      child: Container(
        width: 2,
        height: 40,
        color: isActive
            ? (isDark ? Colors.white24 : Colors.grey.shade300)
            : (isDark ? Colors.white10 : Colors.grey.shade100),
      ),
    );
  }

  Widget _buildContactAuditList(
    WidgetRef ref,
    String? uid,
    bool isDark,
    Color surfaceColor,
    Color textColor,
  ) {
    if (uid == null) return const SizedBox();

    return StreamBuilder<List<EmergencyContact>>(
      stream: ref.read(profileServiceProvider).getContacts(uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              "No trusted contacts configured.",
              style: TextStyle(color: textColor),
            ),
          );
        }

        final contacts = snapshot.data!;

        return Column(
          children: contacts
              .map(
                (c) =>
                    _buildContactAuditCard(c, isDark, surfaceColor, textColor),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildContactAuditCard(
    EmergencyContact contact,
    bool isDark,
    Color surfaceColor,
    Color textColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isDark ? Colors.grey[800] : Colors.grey[100],
            child: Text(
              contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: textColor,
                  ),
                ),
                Text(
                  contact.relationship,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (contact.accessVault)
                _buildAccessBadge("Vault", Colors.blueAccent),
              if (contact.accessLegacyMessage)
                _buildAccessBadge("Msg", Colors.orangeAccent),
              if (contact.accessMedicalInfo)
                _buildAccessBadge("Med", Colors.pinkAccent),
              if (!contact.accessVault &&
                  !contact.accessLegacyMessage &&
                  !contact.accessMedicalInfo)
                Text(
                  "No Access",
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccessBadge(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

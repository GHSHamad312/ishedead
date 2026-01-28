import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Premium Background Gradient
    final backgroundDecoration = BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? [const Color(0xFF1E1E2C), const Color(0xFF000000)]
            : [const Color(0xFFF5F5FA), const Color(0xFFFFFFFF)],
      ),
    );

    return Scaffold(
      body: Container(
        decoration: backgroundDecoration,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar.large(
              title: const Text("Privacy Policy"),
              centerTitle: false,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              leading: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white10
                        : Colors.black.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_back,
                    color: isDark ? Colors.white : Colors.black87,
                    size: 20,
                  ),
                ),
                onPressed: () => context.pop(),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 10,
                ),
                child: Column(
                  children: [
                    // Intro Card
                    _GlassCard(
                      isDark: isDark,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeaderIcon(
                            Icons.shield_outlined,
                            Colors.deepPurple,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Your Privacy Matters",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "We are committed to transparency. This document explains exactly how your data is handled, stored, and protected within the 'Is He Dead' ecosystem.",
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.5,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Sections
                    _GlassCard(
                      isDark: isDark,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSection(
                            title: "Overview",
                            icon: Icons.info_outline_rounded,
                            content:
                                "This application is designed to ensure your safety and communicate with your trusted contacts in case of an emergency or inactivity. We value your privacy and only collect data necessary for this core functionality.",
                            isDark: isDark,
                          ),
                          _buildDivider(isDark),
                          _buildSection(
                            title: "Data Collection",
                            icon: Icons.data_usage_rounded,
                            content:
                                "We collect and store the following information:\n\n"
                                "• Account: Name, Email, Phone Number.\n"
                                "• Safety: Last check-in time, status.\n"
                                "• Contacts: Names, phone numbers, emails.\n"
                                "• Vault: Encrypted documents you upload.\n"
                                "• Legacy: Encrypted messages.",
                            isDark: isDark,
                          ),
                          _buildDivider(isDark),
                          _buildSection(
                            title: "How We Use Data",
                            icon: Icons.settings_suggest_rounded,
                            content:
                                "Your data is used exclusively for:\n\n"
                                "• Verifying your activity status.\n"
                                "• Sending alerts to contacts if you fail to check in.\n"
                                "• Releasing designated info (Vault/Legacy) ONLY when safety protocol conditions are met.",
                            isDark: isDark,
                          ),
                          _buildDivider(isDark),
                          _buildSection(
                            title: "Data Security",
                            icon: Icons.lock_outline_rounded,
                            content:
                                "• All network traffic is encrypted via SSL/TLS.\n"
                                "• Documents are stored in secure cloud storage.\n"
                                "• Sensitive data access is restricted until protocol trigger.",
                            isDark: isDark,
                          ),
                          _buildDivider(isDark),
                          _buildSection(
                            title: "Account Deletion",
                            icon: Icons.delete_outline_rounded,
                            content:
                                "You have the right to delete your account at any time. This action is permanent and removes your profile, contacts, usage history, and vault data immediately.",
                            isDark: isDark,
                            isLast: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Footer
                    Center(
                      child: Text(
                        "Last Updated: January 2026",
                        style: TextStyle(
                          color: isDark ? Colors.white30 : Colors.black26,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 28),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required String content,
    required bool isDark,
    bool isLast = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.deepPurpleAccent),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.only(left: 30),
          child: Text(
            content,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: isDark ? Colors.grey[400] : Colors.grey[700],
            ),
          ),
        ),
        if (!isLast) const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildDivider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Divider(
        color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
        thickness: 1,
        height: 1,
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final bool isDark;

  const _GlassCard({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF262630) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
        ],
      ),
      child: child,
    );
  }
}

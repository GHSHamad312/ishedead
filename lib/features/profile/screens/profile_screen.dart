import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/profile_service.dart';
import '../models/emergency_contact.dart';
import '../../auth/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final bool isSetupMode;
  const ProfileScreen({super.key, this.isSetupMode = false});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authServiceProvider).currentUser;
    final userProfileAsync = ref.watch(userProfileProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Premium Background Colors
    final backgroundColor = isDark
        ? const Color(0xFF121212)
        : const Color(0xFFFAFAFA);
    final surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: widget.isSetupMode
          ? AppBar(
              title: Text(
                "Trusted Contacts",
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
              backgroundColor: backgroundColor,
              elevation: 0,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                onPressed: () => context.pop(),
              ),
            )
          : null,
      body: userProfileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text("Profile Loading..."));
          }
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 24.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Header (Glass, No Settings Icon)
                  _buildProfileHeader(
                    user?.email,
                    profile.fullName,
                    isDark,
                    surfaceColor,
                    profile.lastAlertTier,
                  ),

                  const SizedBox(height: 32),

                  if (!widget.isSetupMode) ...[
                    // 2. Action Center
                    Text(
                      "Action Center",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.grey[600],
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 3. Vertical Stack Layout
                    _buildVerticalActionLayout(profile, isDark, surfaceColor),

                    const SizedBox(height: 40),
                  ],

                  // 4. Contacts Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "My Inner Circle",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      // 'Add' button moved to list as a card
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildContactsList(user!.uid, isDark, surfaceColor),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildProfileHeader(
    String? email,
    String? name,
    bool isDark,
    Color surfaceColor,
    int lastAlertTier,
  ) {
    final isProtocolExecuted = lastAlertTier >= 3;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isProtocolExecuted
                    ? Colors.redAccent
                    : Colors.greenAccent,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: isProtocolExecuted
                      ? Colors.redAccent.withOpacity(0.2)
                      : Colors.greenAccent.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 44,
              backgroundColor: isDark ? Colors.grey[800] : Colors.grey[100],
              child: Text(
                name != null && name.isNotEmpty
                    ? name[0].toUpperCase()
                    : (email?.substring(0, 1).toUpperCase() ?? "U"),
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Name & Status
          Text(
            name ?? "User",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: isProtocolExecuted
                  ? Colors.red.withOpacity(0.1)
                  : Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isProtocolExecuted ? Colors.red : Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isProtocolExecuted
                      ? "PROTOCOL EXECUTED"
                      : "ACTIVE & PROTECTED",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isProtocolExecuted ? Colors.red : Colors.green,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Pure Vertical Stack to solve spacing issues
  Widget _buildVerticalActionLayout(
    dynamic profile,
    bool isDark,
    Color surfaceColor,
  ) {
    return Column(
      children: [
        _buildActionCard(
          icon: Icons.medical_information,
          title: "Medical ID",
          subtitle: "Emergency Information",
          color: Colors.pink,
          isDark: isDark,
          surfaceColor: surfaceColor,
          isHero: true,
          onTap: () => context.push('/medical-id'),
        ),
        const SizedBox(height: 12),
        _buildActionCard(
          icon: Icons.lock_person,
          title: "Digital Vault",
          subtitle: profile.willUrl != null ? "1 Document Encrypted" : "Empty",
          color: Colors.blueAccent,
          isDark: isDark,
          surfaceColor: surfaceColor,
          onTap: () => context.push('/upload-doc'),
        ),
        const SizedBox(height: 12),
        _buildActionCard(
          icon: Icons.mark_email_unread_outlined,
          title: "Legacy Message",
          subtitle: (profile.legacyMessage?.isNotEmpty ?? false)
              ? "Ready for dispatch"
              : "Not configured",
          color: Colors.orangeAccent,
          isDark: isDark,
          surfaceColor: surfaceColor,
          onTap: () => context.push('/legacy-message'),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isDark,
    required Color surfaceColor,
    required VoidCallback onTap,
    bool isHero = false,
  }) {
    return Material(
      color: surfaceColor,
      borderRadius: BorderRadius.circular(20),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.grey.withOpacity(0.1),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey[400] : Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              // Arrow removed as per user request
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactsList(String uid, bool isDark, Color surfaceColor) {
    return StreamBuilder<List<EmergencyContact>>(
      stream: ref.read(profileServiceProvider).getContacts(uid),
      builder: (context, snapshot) {
        final contacts = snapshot.data ?? [];

        // Empty check removed so ListView renders the "Add" card at index 0

        return SizedBox(
          height: 180, // Taller to accommodate larger portrait cards
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            // +1 for the "Add New" card at the end
            itemCount: contacts.length + 1,
            separatorBuilder: (c, i) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              if (index == contacts.length) {
                return _buildAddContactCard(isDark, surfaceColor);
              }
              final contact = contacts[index];
              return _buildPortraitContactCard(contact, isDark, surfaceColor);
            },
          ),
        );
      },
    );
  }

  Widget _buildAddContactCard(bool isDark, Color surfaceColor) {
    return GestureDetector(
      onTap: () => context.push('/edit-contact'),
      child: Container(
        width: 140,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: surfaceColor.withOpacity(0.5),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? Colors.white24 : Colors.grey.withOpacity(0.4),
            width: 2,
            style: BorderStyle
                .solid, // Or BorderStyle.none if using dashed path paint, but solid is easier here
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? Colors.white10 : Colors.grey.withOpacity(0.1),
              ),
              child: Icon(
                Icons.add,
                size: 32,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const Spacer(),
            Text(
              "Add New",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Trust Contact",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white38 : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // New Vertical Portrait Card Style
  Widget _buildPortraitContactCard(
    EmergencyContact contact,
    bool isDark,
    Color color,
  ) {
    return GestureDetector(
      onTap: () => _showContactDetails(contact),
      child: Container(
        width: 140, // Wider for better presence
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24), // Pill/Stadium shape vibe
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.grey.withOpacity(0.2),
          ),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 36, // Larger avatar
              backgroundColor: isDark
                  ? Colors.grey[800]
                  : Colors.amber.shade50.withOpacity(0.5),
              child: Text(
                contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.deepPurple,
                ),
              ),
            ),
            const Spacer(),
            Text(
              contact.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15, // Larger text
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              contact.relationship,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.grey[400] : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showContactDetails(EmergencyContact contact) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.deepPurple.shade50,
                child: Text(
                  contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontSize: 32,
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                contact.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                contact.relationship,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              _buildInfoTile(Icons.phone, contact.phone, isDark),
              if (contact.email.isNotEmpty)
                _buildInfoTile(Icons.email, contact.email, isDark),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        context.push('/edit-contact', extra: contact);
                      },
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text("Edit"),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _deleteContact(contact),
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.white,
                      ),
                      label: const Text("Remove"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoTile(IconData icon, String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: Colors.deepPurple),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteContact(EmergencyContact contact) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Remove Contact?"),
        content: Text(
          "Are you sure you want to remove ${contact.name} from your circle?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text("Remove", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (mounted) Navigator.pop(context);
      final user = ref.read(authServiceProvider).currentUser;
      if (user != null) {
        await ref
            .read(profileServiceProvider)
            .deleteContact(user.uid, contact.id);
      }
    }
  }
}

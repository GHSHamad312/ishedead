import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:is_he_dead/features/auth/auth_provider.dart';
import 'package:is_he_dead/features/profile/services/profile_service.dart';
import 'package:is_he_dead/features/profile/models/user_profile.dart';
import 'package:is_he_dead/core/theme/vault_styles.dart';
import 'package:is_he_dead/core/common/glass_phone_field.dart';

class CompleteProfileScreen extends ConsumerStatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  ConsumerState<CompleteProfileScreen> createState() =>
      _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends ConsumerState<CompleteProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _fullPhoneNumber = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authServiceProvider).currentUser;
    if (user != null) {
      if (user.displayName != null) {
        _nameController.text = user.displayName!;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _createProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final user = ref.read(authServiceProvider).currentUser;
      if (user != null) {
        final newProfile = UserProfile(
          uid: user.uid,
          email: user.email ?? '',
          fullName: _nameController.text.trim(),
          phone: _fullPhoneNumber,
          lastCheckIn: DateTime.now(),
          status: 'Active',
          isSetupComplete: false,
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

  Future<void> _finishSetup() async {
    setState(() => _isLoading = true);
    try {
      final user = ref.read(authServiceProvider).currentUser;
      if (user != null) {
        await ref.read(profileServiceProvider).completeSetup(user.uid);
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
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(userProfileProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Premium Background Color
    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey[50],
      body: userProfileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Error: $err")),
        data: (profile) {
          if (profile == null) {
            return _buildCreateProfileForm(theme, isDark);
          } else {
            return _buildSetupChecklist(context, profile, theme, isDark);
          }
        },
      ),
    );
  }

  Widget _buildCreateProfileForm(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            height: 220,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple, Colors.purpleAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
            ),
            child: SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.person_add_outlined,
                      size: 60,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Create Your Identity",
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -30),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Text(
                        "Basic Information",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: const Icon(
                            Icons.person,
                            color: Colors.deepPurple,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: isDark
                              ? Colors.grey[900]
                              : Colors.grey[50],
                        ),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      const SizedBox(height: 16),
                      GlassPhoneField(
                        label: 'Phone Number',
                        isDark: isDark,
                        onChanged: (phone) {
                          _fullPhoneNumber = phone.completeNumber;
                        },
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _createProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            elevation: 5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  "Start Setup",
                                  style: TextStyle(
                                    fontSize: 18,
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
        ],
      ),
    );
  }

  Widget _buildSetupChecklist(
    BuildContext context,
    UserProfile profile,
    ThemeData theme,
    bool isDark,
  ) {
    // Progress Calculation
    final contactsAsync = ref.watch(emergencyContactsProvider);
    final contacts = contactsAsync.value ?? [];

    int completedTasks = 0;
    // 1. Medical ID
    if (profile.medicalInfo != null) {
      completedTasks++;
    }
    // 2. Trusted Contacts
    if (contacts.isNotEmpty) completedTasks++;

    // 3. Digital Vault
    if (profile.willUrl != null && profile.willUrl!.isNotEmpty)
      completedTasks++;

    // 4. Legacy Message
    if (profile.legacyMessage != null && profile.legacyMessage!.isNotEmpty)
      completedTasks++;

    // Total steps: 4 (Medical, Contacts, Vault, Legacy)
    double progress = completedTasks / 4.0;
    if (progress == 0) progress = 0.05; // Visual placeholder

    return Scaffold(
      body: Stack(
        children: [
          // 1. Gradient Background
          Container(
            decoration: BoxDecoration(gradient: VaultStyles.bgGradient(isDark)),
          ),

          // 2. Content
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200.0,
                floating: false,
                pinned: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  background: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 60),
                      // Progress Circle
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 80,
                            height: 80,
                            child: CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 8,
                              backgroundColor: Colors.white10,
                              color: Colors.greenAccent,
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                          Text(
                            "${(progress * 100) > 99 ? 100 : (progress * 100).toInt()}%",
                            style: TextStyle(
                              color: VaultStyles.textColor(isDark),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Setup Your Vault",
                        style: TextStyle(
                          color: VaultStyles.textColor(isDark),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "ESSENTIAL ACTIONS",
                        style: TextStyle(
                          color: VaultStyles.subTextColor(isDark),
                          fontSize: 12,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      _buildGlassTaskTile(
                        context: context,
                        isDark: isDark,
                        stepIndex: 1,
                        title: "Medical ID",
                        subtitle: "Life-saving info for first responders",
                        icon: Icons.medical_services_rounded,
                        color: Colors.redAccent,
                        isComplete: profile.medicalInfo != null,
                        onTap: () => context.push('/medical-id'),
                      ),

                      _buildGlassTaskTile(
                        context: context,
                        isDark: isDark,
                        stepIndex: 2,
                        title: "Trusted Contacts",
                        subtitle: "Who we notify if you don't check in",
                        icon: Icons.group_add_rounded,
                        color: Colors.blueAccent,
                        isComplete: contacts.isNotEmpty,
                        onTap: () => context.push('/setup-contacts'),
                      ),

                      _buildGlassTaskTile(
                        context: context,
                        isDark: isDark,
                        stepIndex: 3,
                        title: "Digital Vault",
                        subtitle: "Securely store your Will & Documents",
                        icon: Icons.lock_person_rounded,
                        color: Colors.amberAccent,
                        isComplete:
                            profile.willUrl != null &&
                            profile.willUrl!.isNotEmpty,
                        onTap: () => context.push('/upload-doc'),
                      ),

                      _buildGlassTaskTile(
                        context: context,
                        isDark: isDark,
                        stepIndex: 4,
                        title: "Legacy Message",
                        subtitle: "A final message for your loved ones",
                        icon: Icons.mark_email_unread_rounded,
                        color: Colors.purpleAccent,
                        isComplete:
                            profile.legacyMessage != null &&
                            profile.legacyMessage!.isNotEmpty,
                        onTap: () => context.push('/legacy-message'),
                      ),

                      const SizedBox(height: 40),

                      // Action Button
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _finishSetup,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.greenAccent,
                            foregroundColor: Colors.black87,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'COMPLETE SETUP',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 20),
                      Center(
                        child: TextButton(
                          onPressed: _finishSetup,
                          child: Text(
                            "Skip for now",
                            style: TextStyle(
                              color: VaultStyles.subTextColor(isDark),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGlassTaskTile({
    required BuildContext context,
    required bool isDark,
    required int stepIndex,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isComplete,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: VaultStyles.glassColor(isDark),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isComplete
              ? Colors.green.withOpacity(0.5)
              : VaultStyles.glassBorderColor(isDark),
          width: 1.5,
        ),
        boxShadow: VaultStyles.shadow(isDark),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
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
                          color: VaultStyles.textColor(isDark),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: VaultStyles.subTextColor(isDark),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isComplete)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.greenAccent,
                  )
                else
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: VaultStyles.subTextColor(isDark),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

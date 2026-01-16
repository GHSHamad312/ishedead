import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:is_he_dead/features/medical/models/medical_info.dart';
import 'package:is_he_dead/features/profile/services/profile_service.dart';
import 'package:is_he_dead/features/auth/auth_provider.dart';
import 'package:is_he_dead/features/profile/models/user_profile.dart';
import 'package:go_router/go_router.dart';

class MedicalIdScreen extends ConsumerStatefulWidget {
  final MedicalInfo? initialData;
  const MedicalIdScreen({super.key, this.initialData});

  @override
  ConsumerState<MedicalIdScreen> createState() => _MedicalIdScreenState();
}

class _MedicalIdScreenState extends ConsumerState<MedicalIdScreen> {
  late TextEditingController _bloodTypeController;
  late TextEditingController _notesController;
  late TextEditingController _allergiesController;
  late TextEditingController _medicationsController;
  bool _isLoading = false;
  bool _isInitialized = false;
  bool _isEditing = true; // Default to true, will switch if data exists

  @override
  void initState() {
    super.initState();
    _bloodTypeController = TextEditingController(
      text: widget.initialData?.bloodType,
    );
    _notesController = TextEditingController(text: widget.initialData?.notes);
    _allergiesController = TextEditingController(
      text: widget.initialData?.allergies.join(', '),
    );
    _medicationsController = TextEditingController(
      text: widget.initialData?.medications.join(', '),
    );

    // Legacy support: if widget.initialData passed, use it and switch to view mode
    if (widget.initialData != null) {
      _isEditing = false;
    }
  }

  @override
  void dispose() {
    _bloodTypeController.dispose();
    _notesController.dispose();
    _allergiesController.dispose();
    _medicationsController.dispose();
    super.dispose();
  }

  void _initializeFromProfile(UserProfile? profile) {
    if (_isInitialized || profile == null) return;

    // If we have saved info
    if (profile.medicalInfo != null) {
      final info = profile.medicalInfo!;
      setState(() {
        _bloodTypeController.text = info.bloodType ?? '';
        _notesController.text = info.notes ?? '';
        _allergiesController.text = info.allergies.join(', ');
        _medicationsController.text = info.medications.join(', ');
        _isInitialized = true;
        _isEditing = false; // Switch to View Mode
      });
    } else {
      // No data yet, stay in edit mode but mark initialized
      setState(() {
        _isInitialized = true;
        _isEditing = true;
      });
    }
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    final info = MedicalInfo(
      bloodType: _bloodTypeController.text,
      notes: _notesController.text,
      allergies: _allergiesController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
      medications: _medicationsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
    );

    try {
      await ref.read(profileServiceProvider).updateMedicalInfo(user.uid, info);
      if (mounted) {
        // If we are in setup mode (creation flow), we should go back to the list
        // Otherwise, stay here and show the view card
        final profile = ref.read(userProfileProvider).value;
        if (profile != null && !profile.isSetupComplete) {
          context.pop();
          return;
        }

        setState(
          () => _isEditing = false,
        ); // Successfully saved, switch to View
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Medical ID Updated')));
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

    // Initialize logic
    userProfileAsync.whenData((profile) {
      if (!_isInitialized && profile != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _initializeFromProfile(profile);
        });
      }
    });

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        title: Text(
          'Medical ID',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: SafeArea(
        child: userProfileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) =>
              Center(child: Text('Error loading profile: $err')),
          data: (profile) {
            if (_isEditing) {
              return _buildEditForm(context, isDark);
            } else {
              return _buildViewCard(context, profile?.medicalInfo, isDark);
            }
          },
        ),
      ),
    );
  }

  Widget _buildEditForm(BuildContext context, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            "Update your critical medical information.",
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.grey.shade700,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _buildDropdownCard(
            'Blood Type',
            _bloodTypeController,
            ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'],
            icon: Icons.bloodtype,
            isDark: isDark,
          ),
          const SizedBox(height: 20),
          _buildFormCard(
            'Allergies (comma separated)',
            _allergiesController,
            icon: Icons.warning_amber,
            isDark: isDark,
          ),
          const SizedBox(height: 20),
          _buildFormCard(
            'Medications (comma separated)',
            _medicationsController,
            icon: Icons.medication,
            isDark: isDark,
          ),
          const SizedBox(height: 20),
          _buildFormCard(
            'Medical Notes',
            _notesController,
            maxLines: 4,
            icon: Icons.note,
            isDark: isDark,
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Text(
                      'SAVE MEDICAL ID',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewCard(BuildContext context, MedicalInfo? info, bool isDark) {
    if (info == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("No Medical Information Found"),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => setState(() => _isEditing = true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text("Create Medical ID"),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Main Red Card
          Container(
            width: double.infinity,
            height: 220,
            decoration: BoxDecoration(
              color: const Color(0xFFFF5252), // Vibrant red matching screenshot
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF5252).withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Top Left Icon
                Positioned(
                  top: 24,
                  left: 24,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.medical_services_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                // Top Right Badge
                Positioned(
                  top: 24,
                  right: 24,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "EMERGENCY INFO",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                // Blood Type Text
                Positioned(
                  bottom: 32,
                  left: 24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "BLOOD TYPE",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        (info.bloodType == null || info.bloodType!.isEmpty)
                            ? "?"
                            : info.bloodType!, // Display as user entered or uppercase? Screenshot shows lowercase 'b-'
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _buildDetailSection(
            "Allergies",
            info.allergies,
            Icons.warning_amber_rounded,
            Colors.amber.shade700,
            const Color(
              0xFFFFF8E1,
            ), // Light amber/orange background for card/chips? No, card is white.
            Colors.orange.shade100, // Chip bg
            Colors.orange.shade800, // Chip text
            isDark,
          ),
          const SizedBox(height: 16),
          _buildDetailSection(
            "Medications",
            info.medications,
            Icons.medication_outlined,
            Colors.blue.shade700,
            const Color(0xFFE3F2FD),
            Colors.blue.shade50,
            Colors.blue.shade700,
            isDark,
          ),
          const SizedBox(height: 16),
          _buildNoteSection(info.notes, isDark),
        ],
      ),
    );
  }

  Widget _buildDetailSection(
    String title,
    List<String> items,
    IconData icon,
    Color iconColor,
    Color? unusedBg, // Keeping signature similar but refining usage
    Color chipBg,
    Color chipText,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            Text(
              "None listed",
              style: TextStyle(
                color: isDark ? Colors.white38 : Colors.grey[400],
                fontStyle: FontStyle.italic,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items.map((item) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? iconColor.withOpacity(0.2) : chipBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item,
                    style: TextStyle(
                      color: isDark ? Colors.white : chipText,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildNoteSection(String? notes, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.edit_note_rounded,
                color: isDark ? Colors.white70 : Colors.grey[700],
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                "Notes",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            (notes == null || notes.isEmpty) ? "No notes added." : notes,
            style: TextStyle(
              height: 1.5,
              color: isDark ? Colors.white70 : Colors.black87,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    IconData? icon,
    required bool isDark,
  }) {
    // Neutral styling: Grey border, transparent fill
    final borderColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.grey[500] : Colors.grey[600];

    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(color: textColor, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: hintColor),
        prefixIcon: icon != null
            ? Icon(icon, color: Colors.grey.shade500)
            : null,
        filled: true,
        fillColor: isDark ? Colors.grey[900] : Colors.grey[50],
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  Widget _buildDropdownCard(
    String label,
    TextEditingController controller,
    List<String> options, {
    IconData? icon,
    required bool isDark,
  }) {
    final borderColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.grey[500] : Colors.grey[600];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: DropdownButtonFormField<String>(
        value: options.contains(controller.text) ? controller.text : null,
        items: options.map((String value) {
          return DropdownMenuItem<String>(value: value, child: Text(value));
        }).toList(),
        onChanged: (val) {
          if (val != null) {
            controller.text = val;
          }
        },
        style: TextStyle(color: textColor, fontSize: 16),
        dropdownColor: isDark ? Colors.grey[900] : Colors.white,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: hintColor),
          prefixIcon: icon != null
              ? Icon(icon, color: Colors.grey.shade500)
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}

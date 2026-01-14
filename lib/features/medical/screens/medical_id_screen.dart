import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:is_he_dead/features/medical/models/medical_info.dart';
import 'package:is_he_dead/features/profile/services/profile_service.dart';
import 'package:is_he_dead/features/auth/auth_provider.dart';
import 'package:is_he_dead/features/profile/models/user_profile.dart';

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
      appBar: AppBar(
        title: const Text('Medical ID'),
        actions: [
          // If in view mode, show edit button
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: userProfileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) =>
            Center(child: Text('Error loading profile: $err')),
        data: (profile) {
          if (_isEditing) {
            return _buildEditForm(context, isDark);
          } else {
            // Safe to render view because logic ensures if !isEditing, data exists (mostly)
            // or empty data is handled in view
            return _buildViewCard(context, profile?.medicalInfo, isDark);
          }
        },
      ),
    );
  }

  Widget _buildEditForm(BuildContext context, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            "Update your critical medical information.",
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          _buildFormCard(
            'Blood Type',
            _bloodTypeController,
            icon: Icons.bloodtype,
          ),
          const SizedBox(height: 16),
          _buildFormCard(
            'Allergies (comma separated)',
            _allergiesController,
            icon: Icons.warning_amber,
          ),
          const SizedBox(height: 16),
          _buildFormCard(
            'Medications (comma separated)',
            _medicationsController,
            icon: Icons.medication,
          ),
          const SizedBox(height: 16),
          _buildFormCard(
            'Medical Notes',
            _notesController,
            maxLines: 4,
            icon: Icons.note,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade100,
                elevation: 0,
              ),
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : Text(
                      'Save Medical ID',
                      style: TextStyle(
                        color: Colors.red[900],
                        fontWeight: FontWeight.bold,
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
            TextButton(
              onPressed: () => setState(() => _isEditing = true),
              child: const Text("Create Now"),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Main ID Card
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [Colors.red[900]!, Colors.red[800]!]
                    : [Colors.redAccent, Colors.red[400]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Icon(
                        Icons.medical_services_outlined,
                        color: Colors.white,
                        size: 32,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
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
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    "BLOOD TYPE",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    (info.bloodType == null || info.bloodType!.isEmpty)
                        ? "N/A"
                        : info.bloodType!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          _buildDetailSection(
            "Allergies",
            info.allergies,
            Icons.warning_amber_rounded,
            Colors.orange,
            isDark,
          ),
          const SizedBox(height: 16),
          _buildDetailSection(
            "Medications",
            info.medications,
            Icons.medication_rounded,
            Colors.blue,
            isDark,
          ),
          const SizedBox(height: 16),
          if (info.notes != null && info.notes!.isNotEmpty)
            _buildNoteSection(info.notes!, isDark),
        ],
      ),
    );
  }

  Widget _buildDetailSection(
    String title,
    List<String> items,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Text(
              "None listed",
              style: TextStyle(
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items
                  .map(
                    (item) => Chip(
                      label: Text(item),
                      backgroundColor: color.withOpacity(0.1),
                      labelStyle: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                      side: BorderSide.none,
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildNoteSection(String notes, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.note_alt_outlined, color: Colors.grey[600], size: 20),
              const SizedBox(width: 8),
              const Text(
                "Notes",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(notes, style: const TextStyle(height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildFormCard(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    IconData? icon,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: icon != null
                ? Icon(icon, color: Colors.grey[500])
                : null,
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }
}

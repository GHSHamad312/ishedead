import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../models/emergency_contact.dart';
import '../services/profile_service.dart';
import '../../auth/auth_provider.dart';
import 'package:is_he_dead/core/common/glass_phone_field.dart';

class EditContactScreen extends ConsumerStatefulWidget {
  final EmergencyContact? contact;
  const EditContactScreen({super.key, this.contact});

  @override
  ConsumerState<EditContactScreen> createState() => _EditContactScreenState();
}

class _EditContactScreenState extends ConsumerState<EditContactScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  // Phone handled by GlassPhoneField state
  late TextEditingController _relationshipController;
  late TextEditingController _priorityController;

  String _fullPhoneNumber = '';

  // Access Control States
  bool _accessVault = false;
  bool _accessLegacyMessage = true;
  bool _accessMedicalInfo = false;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.contact?.name ?? '');
    _emailController = TextEditingController(text: widget.contact?.email ?? '');
    _fullPhoneNumber = widget.contact?.phone ?? '';
    _relationshipController = TextEditingController(
      text: widget.contact?.relationship ?? 'Friend',
    );
    _priorityController = TextEditingController(
      text: widget.contact?.priority.toString() ?? '1',
    );

    // Initialize Access Controls
    if (widget.contact != null) {
      _accessVault = widget.contact!.accessVault;
      _accessLegacyMessage = widget.contact!.accessLegacyMessage;
      _accessMedicalInfo = widget.contact!.accessMedicalInfo;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    // _phoneController handled locally
    _relationshipController.dispose();
    _priorityController.dispose();
    super.dispose();
  }

  Future<void> _saveContact() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        final user = ref.read(authServiceProvider).currentUser;
        if (user != null) {
          final contactId = widget.contact?.id ?? const Uuid().v4();
          final newContact = EmergencyContact(
            id: contactId,
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            phone: _fullPhoneNumber,
            relationship: _relationshipController.text.trim(),
            priority: int.tryParse(_priorityController.text) ?? 1,
            accessVault: _accessVault,
            accessLegacyMessage: _accessLegacyMessage,
            accessMedicalInfo: _accessMedicalInfo,
          );

          if (widget.contact == null) {
            await ref
                .read(profileServiceProvider)
                .addContact(user.uid, newContact);
          } else {
            await ref
                .read(profileServiceProvider)
                .updateContact(user.uid, newContact);
          }
          if (mounted) context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF121212) : Colors.grey[50];
    final surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          widget.contact == null ? 'Add Trusted Contact' : 'Edit Contact',
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
        ),
        backgroundColor: surfaceColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: isDark
                          ? Colors.deepPurple.withOpacity(0.2)
                          : Colors.deepPurple.shade50,
                      child: Icon(
                        widget.contact == null
                            ? Icons.person_add_alt_1
                            : Icons.person,
                        size: 40,
                        color: isDark
                            ? Colors.deepPurpleAccent
                            : Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.contact == null
                          ? "Add a new Guardian"
                          : "Update Contact Details",
                      style: TextStyle(fontSize: 16, color: hintColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Form Section
              Container(
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      icon: Icons.person_outline,
                      isDark: isDark,
                      textColor: textColor,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _relationshipController,
                      label: 'Relationship',
                      icon: Icons.favorite_border,
                      hint: 'e.g. Spouse, Brother, Attorney',
                      isDark: isDark,
                      textColor: textColor,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _emailController,
                      label: 'Email Address',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      isDark: isDark,
                      textColor: textColor,
                    ),
                    const SizedBox(height: 20),
                    GlassPhoneField(
                      label: 'Phone Number',
                      initialValue: _fullPhoneNumber,
                      isDark: isDark,
                      fillColor: isDark ? Colors.grey[900] : Colors.grey[50],
                      onChanged: (phone) {
                        _fullPhoneNumber = phone.completeNumber;
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _priorityController,
                      label: 'Priority Order',
                      icon: Icons.format_list_numbered,
                      keyboardType: TextInputType.number,
                      hint: '1 = First to verify',
                      isDark: isDark,
                      textColor: textColor,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Access Control Section
              Padding(
                padding: const EdgeInsets.only(left: 8.0, bottom: 12.0),
                child: Text(
                  "Data Access Permissions",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: hintColor,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(20),
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
                    _buildSwitchTile(
                      title: "Digital Vault",
                      subtitle: "Passwords, documents, and secure notes",
                      value: _accessVault,
                      icon: Icons.lock_outline,
                      isDark: isDark,
                      textColor: textColor,
                      onChanged: (val) => setState(() => _accessVault = val),
                    ),
                    Divider(
                      height: 1,
                      color: isDark ? Colors.grey[800] : Colors.grey[200],
                    ),
                    _buildSwitchTile(
                      title: "Legacy Message",
                      subtitle: "The final message you wrote for them",
                      value: _accessLegacyMessage,
                      icon: Icons.mark_email_read_outlined,
                      isDark: isDark,
                      textColor: textColor,
                      onChanged: (val) =>
                          setState(() => _accessLegacyMessage = val),
                    ),
                    Divider(
                      height: 1,
                      color: isDark ? Colors.grey[800] : Colors.grey[200],
                    ),
                    _buildSwitchTile(
                      title: "Medical Info",
                      subtitle: "Health records and medical directives",
                      value: _accessMedicalInfo,
                      icon: Icons.medical_services_outlined,
                      isDark: isDark,
                      textColor: textColor,
                      onChanged: (val) =>
                          setState(() => _accessMedicalInfo = val),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveContact,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    disabledBackgroundColor: isDark
                        ? Colors.grey[800]
                        : Colors.grey[300],
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          widget.contact == null
                              ? 'Save Contact'
                              : 'Update Contact',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              if (widget.contact != null) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: OutlinedButton(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) {
                          final isDark =
                              Theme.of(context).brightness == Brightness.dark;
                          return AlertDialog(
                            backgroundColor: isDark
                                ? const Color(0xFF1E1E1E)
                                : Colors.white,
                            title: Text(
                              'Delete Contact?',
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            content: Text(
                              'Are you sure you want to remove this person from your safety circle?',
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                child: const Text('Delete'),
                              ),
                            ],
                          );
                        },
                      );

                      if (confirmed == true && widget.contact != null) {
                        setState(() => _isLoading = true);
                        try {
                          final user = ref
                              .read(authServiceProvider)
                              .currentUser;
                          if (user != null) {
                            await ref
                                .read(profileServiceProvider)
                                .deleteContact(user.uid, widget.contact!.id);
                            if (mounted) context.pop();
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                            setState(() => _isLoading = false);
                          }
                        }
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 0,
                      ), // Height controlled by SizedBox
                    ),
                    child: const Text(
                      "Remove Contact",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? hint,
    required bool isDark,
    required Color textColor,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
        hintText: hint,
        hintStyle: TextStyle(
          color: isDark ? Colors.grey[600] : Colors.grey[400],
        ),
        prefixIcon: Icon(
          icon,
          color: isDark ? Colors.deepPurpleAccent : Colors.deepPurple,
        ),
        filled: true,
        fillColor: isDark ? Colors.grey[900] : Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey.shade200,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.deepPurpleAccent : Colors.deepPurple,
            width: 2,
          ),
        ),
      ),
      validator: (v) => v!.isEmpty ? 'Required' : null,
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required IconData icon,
    required ValueChanged<bool> onChanged,
    required bool isDark,
    required Color textColor,
  }) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeColor: isDark ? Colors.deepPurpleAccent : Colors.deepPurple,
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.deepPurple.withOpacity(0.2)
              : Colors.deepPurple.shade50,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isDark ? Colors.deepPurpleAccent : Colors.deepPurple,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: textColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    );
  }
}

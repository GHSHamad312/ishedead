import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/storage_service.dart';
import '../services/profile_service.dart';
import '../../auth/auth_provider.dart';
import 'package:is_he_dead/core/utils/toast_utils.dart';
import 'package:is_he_dead/core/utils/error_parser.dart';

class UploadDocumentScreen extends ConsumerStatefulWidget {
  const UploadDocumentScreen({super.key});

  @override
  ConsumerState<UploadDocumentScreen> createState() =>
      _UploadDocumentScreenState();
}

class _UploadDocumentScreenState extends ConsumerState<UploadDocumentScreen> {
  File? _selectedFile;
  bool _isUploading = false;
  String? _fileName;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png'],
    );

    if (result != null) {
      final file = result.files.single;

      // 100 MB Limit (100 * 1024 * 1024 bytes)
      if (file.size > 100 * 1024 * 1024) {
        if (mounted) {
          ToastUtils.showError(
            context,
            "File is too large. Max limit is 100MB.",
          );
        }
        return;
      }

      setState(() {
        _selectedFile = File(file.path!);
        _fileName = file.name;
      });
    }
  }

  Future<void> _uploadFile() async {
    if (_selectedFile == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final user = ref.read(authServiceProvider).currentUser;
      if (user != null) {
        final url = await ref
            .read(storageServiceProvider)
            .uploadFile(user.uid, _selectedFile!, 'documents');

        await ref.read(profileServiceProvider).updateWillUrl(user.uid, url);

        if (mounted) {
          ToastUtils.showSuccess(context, 'Upload Successful!');
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.showError(context, ErrorParser.parse(e));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(userProfileProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF121212) : Colors.grey[50];
    final surfaceColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final secondaryTextColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Document Vault',
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
      body: userProfileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Profile Error'));
          }

          final hasExistingFile = profile.willUrl != null;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Secure Cloud Storage",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Upload your Last Will, Advance Directive on Travel Plans.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: secondaryTextColor),
                  ),
                  const SizedBox(height: 40),

                  // Existing File Card
                  if (hasExistingFile && _selectedFile == null)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.green.withValues(alpha: 0.5),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.lock_outline_rounded,
                              size: 48,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Document Secured",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Your vital document is encrypted and safely stored in the vault.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: secondaryTextColor,
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Actions
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    // Logic to delete or replace (simply reset file picked)
                                    // Ideally delete functionality requires another method
                                    setState(() {
                                      _selectedFile = null;
                                      // Force pick new file
                                      _pickFile();
                                    });
                                  },
                                  icon: const Icon(Icons.sync),
                                  label: const Text("Replace"),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    side: BorderSide(
                                      color: secondaryTextColor!,
                                    ),
                                    foregroundColor: textColor,
                                  ),
                                ),
                              ),
                              // View button could go here if we want to download logic
                            ],
                          ),
                        ],
                      ),
                    )
                  else
                    // Upload Area
                    GestureDetector(
                      onTap: _pickFile,
                      child: Container(
                        height: 250,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.deepPurple.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark
                                ? Colors.white24
                                : Colors.deepPurple.withValues(alpha: 0.3),
                            width: 2,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: surfaceColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                      alpha: isDark ? 0.3 : 0.05,
                                    ),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Icon(
                                _selectedFile != null
                                    ? Icons.check
                                    : Icons.cloud_upload_rounded,
                                size: 50,
                                color: isDark
                                    ? Colors.white
                                    : Colors.deepPurple,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              _selectedFile != null
                                  ? "File Selected"
                                  : "Tap to browse files",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : Colors.deepPurple,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _fileName ?? "Supports PDF, JPG, PNG (Max 100MB)",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: _fileName != null
                                    ? textColor
                                    : secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 40),

                  // Disclaimer
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.amber.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lock, color: Colors.amber, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Documents are encrypted at rest. Only your designated contacts can access them after verification.",
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.amber[200]
                                  : Colors.amber[900],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Buttons
                  if (_selectedFile != null)
                    SizedBox(
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isUploading ? null : _uploadFile,
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
                        child: _isUploading
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    "Encrypting & Uploading...",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              )
                            : const Text(
                                "Upload Securely",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
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
}

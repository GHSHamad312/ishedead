import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../services/profile_service.dart';
import '../../auth/auth_provider.dart';
import 'package:is_he_dead/core/utils/toast_utils.dart';
import 'package:is_he_dead/core/utils/error_parser.dart';

class LegacyMessageScreen extends ConsumerStatefulWidget {
  const LegacyMessageScreen({super.key});

  @override
  ConsumerState<LegacyMessageScreen> createState() =>
      _LegacyMessageScreenState();
}

class _LegacyMessageScreenState extends ConsumerState<LegacyMessageScreen> {
  final _messageController = TextEditingController();
  bool _isEditing = false;
  bool _isLoading = false;
  bool _isInit = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      final userProfile = ref.watch(userProfileProvider).value;
      if (userProfile != null) {
        final msg = userProfile.legacyMessage ?? '';
        _messageController.text = msg;
        _isEditing = msg.isEmpty;
      }
      _isInit = false;
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final text = _messageController.text.trim();
      await ref
          .read(profileServiceProvider)
          .updateLegacyMessage(user.uid, text);

      if (mounted) {
        final profile = ref.read(userProfileProvider).value;
        if (profile != null && !profile.isSetupComplete) {
          context.pop();
          return;
        }

        setState(() {
          _isLoading = false;
          _isEditing = false; // Switch to view mode
        });
        ToastUtils.showSuccess(context, 'Message saved securely');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ToastUtils.showError(context, ErrorParser.parse(e));
      }
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Message?"),
        content: const Text(
          "This will remove your legacy message. Your contacts won't receive anything if you pass away.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(profileServiceProvider).updateLegacyMessage(user.uid, "");
      if (mounted) {
        _messageController.clear();
        setState(() {
          _isLoading = false;
          _isEditing = true; // Go back to edit mode since it's empty
        });
        ToastUtils.showSuccess(context, 'Message deleted');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Premium Colors
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF9FAFB);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final primaryColor = Colors.deepPurpleAccent;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          _isEditing ? "Edit Message" : "Legacy Message",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        actions: [
          if (!_isEditing && !_isLoading)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _delete,
              tooltip: "Delete Message",
            ),
          if (!_isEditing && !_isLoading) const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(
              left: 24,
              right: 24,
              top: 16,
              bottom: 100,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Card (Only show in Edit mode or if it adds context? Maybe always nice)
                // Let's keep it but make it subtler in View mode or just keep it consistency.
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [
                              Colors.deepPurple.shade900,
                              Colors.deepPurple.shade800,
                            ]
                          : [Colors.deepPurple.shade50, Colors.white],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurple.withValues(alpha: 0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(
                      color: isDark
                          ? Colors.deepPurple.shade700
                          : Colors.deepPurple.shade100,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black26 : Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.security,
                          color: primaryColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "The Final Message",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Sent securely to your contacts if your safety timer expires.",
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? Colors.white70
                                    : Colors.grey[700],
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Label
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(
                    _isEditing ? "DRAFTING MESSAGE..." : "SAVED MESSAGE",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Main Content Area
                if (_isEditing)
                  _buildEditor(context, isDark, cardColor, textColor)
                else
                  _buildViewCard(context, isDark, cardColor, textColor),
              ],
            ),
          ),

          // Floating Action Button
          Positioned(
            left: 24,
            right: 24,
            bottom: 32,
            child: SafeArea(
              child: _isEditing
                  ? ElevatedButton(
                      onPressed: _isLoading ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        elevation: 8,
                        shadowColor: primaryColor.withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.mark_email_read_outlined, size: 22),
                                SizedBox(width: 8),
                                Text(
                                  "Save Secure Message",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                    )
                  : ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _messageController.text =
                              _messageController.text; // Ensure consistent
                          _isEditing = true;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cardColor,
                        foregroundColor: textColor,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: isDark
                                ? Colors.white24
                                : Colors.grey.shade300,
                          ),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.edit_outlined, size: 22),
                          SizedBox(width: 8),
                          Text(
                            "Edit Message",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditor(
    BuildContext context,
    bool isDark,
    Color cardColor,
    Color textColor,
  ) {
    return Container(
      constraints: const BoxConstraints(minHeight: 300),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: TextField(
        controller: _messageController,
        maxLines: null,
        minLines: 10,
        textCapitalization: TextCapitalization.sentences,
        style: TextStyle(
          fontSize: 16,
          height: 1.6,
          color: textColor,
          fontFamily: 'Roboto',
        ),
        decoration: InputDecoration(
          hintText:
              "My dearest friends and family,\n\nIf you are reading this...",
          hintStyle: TextStyle(
            color: isDark ? Colors.grey[700] : Colors.grey[300],
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(24),
        ),
      ),
    );
  }

  Widget _buildViewCard(
    BuildContext context,
    bool isDark,
    Color cardColor,
    Color textColor,
  ) {
    final message = _messageController.text;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 300),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        // Subtle paper texture effect logic could go here, or just a border
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black12,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.format_quote_rounded,
            color: Colors.deepPurpleAccent.withValues(alpha: 0.5),
            size: 40,
          ),
          const SizedBox(height: 16),
          Text(
            message.isEmpty ? "No message set." : message,
            style: TextStyle(
              fontSize: 18,
              height: 1.8,
              color: textColor.withValues(alpha: 0.9),
              fontStyle: FontStyle.italic,
              fontFamily: 'Georgia', // Serif font for "Letter" feel
            ),
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.bottomRight,
            child: Icon(
              Icons.format_quote_rounded,
              color: Colors.deepPurpleAccent.withValues(alpha: 0.2),
              size: 40,
            ),
          ),
        ],
      ),
    );
  }
}

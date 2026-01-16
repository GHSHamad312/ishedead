import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:is_he_dead/core/theme/vault_styles.dart';

class GlassPhoneField extends StatelessWidget {
  final String label;
  final ValueChanged<PhoneNumber> onChanged;
  final String? initialCountryCode;
  final String? initialValue;
  final bool isDark;
  final Color? fillColor;
  final TextEditingController? controller;
  final bool showLabel;
  final bool enabled;

  const GlassPhoneField({
    super.key,
    required this.label,
    required this.onChanged,
    required this.isDark,
    this.initialCountryCode = 'US',
    this.initialValue,
    this.fillColor,
    this.controller,
    this.showLabel = true,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel) ...[
          Text(
            label,
            style: TextStyle(
              color: VaultStyles.subTextColor(isDark),
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Theme(
          data: Theme.of(context).copyWith(
            canvasColor: isDark
                ? const Color(0xFF1E1E2C)
                : Colors.white, // For dropdown menu bg
          ),
          child: IntlPhoneField(
            controller: controller,
            enabled: enabled,
            initialCountryCode: initialCountryCode,
            initialValue: initialValue,
            style: TextStyle(
              color: VaultStyles.textColor(isDark),
              fontSize: 16,
            ),
            dropdownTextStyle: TextStyle(
              color: VaultStyles.textColor(isDark),
              fontSize: 16,
            ),
            dropdownIcon: Icon(
              Icons.arrow_drop_down,
              color: VaultStyles.iconColor(isDark),
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: fillColor ?? VaultStyles.inputFillColor(isDark),
              hintText: 'Phone Number',
              hintStyle: TextStyle(
                color: VaultStyles.subTextColor(isDark).withOpacity(0.5),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.deepPurpleAccent.withOpacity(0.5),
                  width: 1.5,
                ),
              ),
            ),
            languageCode: "en",
            onChanged: onChanged,
            onCountryChanged: (country) {
              // Optional: usage callback if needed
            },
          ),
        ),
      ],
    );
  }
}

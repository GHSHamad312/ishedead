import 'package:flutter/material.dart';

class VaultStyles {
  // Dark Mode (Existing)
  static const darkGradient = LinearGradient(
    colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Light Mode (Premium White/Silver/Pale Purple)
  static const lightGradient = LinearGradient(
    colors: [Color(0xFFE0EAFC), Color(0xFFCFDEF3), Color(0xFFE8DBFC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient bgGradient(bool isDark) =>
      isDark ? darkGradient : lightGradient;

  static Color glassColor(bool isDark) => isDark
      ? Colors.white.withValues(alpha: 0.1)
      : Colors.white.withValues(alpha: 0.6);

  static Color glassBorderColor(bool isDark) => isDark
      ? Colors.white24.withValues(alpha: 0.2)
      : Colors.white.withValues(alpha: 0.4);

  static Color textColor(bool isDark) => isDark ? Colors.white : Colors.black87;

  static Color subTextColor(bool isDark) =>
      isDark ? Colors.white70 : Colors.black54;

  static List<BoxShadow> shadow(bool isDark) => isDark
      ? [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ]
      : [
          BoxShadow(
            color: Colors.deepPurple.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ];

  static Color inputFillColor(bool isDark) => isDark
      ? Colors.black.withValues(alpha: 0.2)
      : Colors.white.withValues(alpha: 0.5);

  static Color iconColor(bool isDark) =>
      isDark ? Colors.white70 : Colors.deepPurple.shade300;
}

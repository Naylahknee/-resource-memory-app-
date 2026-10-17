import 'package:flutter/material.dart';

/// Dark color palette for the screens that still use the global dark theme.
/// Values come from the NanyNany design system (see nany_tokens.dart).
abstract final class AppColors {
  AppColors._();

  // custom colors
  static Color kLightGrey = Color.fromARGB(15, 66, 66, 66);

  static Color kBlack = Color.fromARGB(196, 0, 0, 0);
  static Color kOrange = Colors.orange;

  static Color kPureBlack = Colors.black;
  static Color kGreyCard = Color(0xFF1E1E1E);
  static Color kBorderColor = const Color(0xFF2A2A2A);
  static Color kTabGreyColor = const Color.fromARGB(255, 108, 106, 105);

  static Color kWhite = Colors.white;
  static Color kgrey = Colors.grey;
  static Color kPrimaryGrey = Color.fromARGB(255, 232, 232, 232);

  static const Color background = Color(0xFF17161A); // NanyDark.bg

  static const Color surface = Color(0xFF222127); // NanyDark.surface

  static const Color surfaceVariant = Color(0xFF2C2A30);

  // ─── Accent ───────────────────────────────────────────────────────────────

  static const Color accent = Color(0xFF5FC2B9); // NanyDark.brand (teal)

  static const Color accentMuted = Color(0xFF1C3533);

  static const Color noteCard = Color(0xFFE8ECC8);

  // ─── Text ─────────────────────────────────────────────────────────────────

  static const Color textPrimary = Color(0xFFF2EEE7);

  static const Color textSecondary = Color(0xFFA8A198);

  static const Color textMuted = Color(0xFF8F887F); // 4.6:1 on surface

  static const Color textOnLight = Color(0xFF24211D);

  // ─── PIES brand accents ───────────────────────────────────────────────────

  static const Color piesBlue = Color(0xFF1E64FF);
  static const Color piesViolet = Color(0xFF7828E1);
  static const Color piesPink = Color(0xFFF01E8C);
  static const Color piesRed = Color(0xFFFF2840);

  // ─── Semantic ─────────────────────────────────────────────────────────────

  static const Color error = Color(0xFFCF6679);
  static const Color success = Color(0xFF81C784);
  static const Color warning = Color(0xFFFFB74D);
}

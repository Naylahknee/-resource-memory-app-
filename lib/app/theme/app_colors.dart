import 'package:flutter/material.dart';

/// Color palette for NanyNany — warm light theme with PIES brand accents.
abstract final class AppColors {
  AppColors._();

  // ─── PIES brand colors ────────────────────────────────────────────────────
  /// Physical — primary actions, links, focus
  static const Color piesBlue = Color(0xFF1E64FF);

  /// Intellectual — calm moments, secondary highlights
  static const Color piesViolet = Color(0xFF7828E1);

  /// Emotional — warmth, "I'm stuck", encouraging highlights
  static const Color piesPink = Color(0xFFF01E8C);

  /// Spiritual — alerts, destructive actions
  static const Color piesRed = Color(0xFFFF2840);

  // ─── Light surfaces ─────────────────────────────────────────────────────
  /// Warm cream page background — soft on ADHD eyes, not stark white
  static const Color background = Color(0xFFFAF5EC);

  /// Card / sheet surface
  static const Color surface = Color(0xFFFFFFFF);

  /// Muted surface for chips, input fills, subtle sections
  static const Color surfaceVariant = Color(0xFFF3EDE1);

  // ─── Accent ─────────────────────────────────────────────────────────────

  /// Primary accent — PIES electric blue
  static const Color accent = piesBlue;

  /// Soft tint of the accent for selected states / backgrounds
  static const Color accentMuted = Color(0xFFE4EBFF);

  static const Color noteCard = Color(0xFFFFFDF8);

  // ─── Text ───────────────────────────────────────────────────────────────

  /// Warm near-black for primary text — high contrast on cream
  static const Color textPrimary = Color(0xFF221A12);

  static const Color textSecondary = Color(0xFF6F6558);

  static const Color textMuted = Color(0xFFA79C8D);

  static const Color textOnLight = Color(0xFF221A12);

  /// Text/icons drawn on top of the accent color
  static const Color textOnAccent = Colors.white;

  // ─── Semantic ───────────────────────────────────────────────────────────

  static const Color error = piesRed;

  static const Color success = Color(0xFF2E9E5B);

  static const Color warning = Color(0xFFE8930C);

  // ─── Legacy names (kept so existing screens keep compiling) ──────────────

  static Color kLightGrey = const Color(0xFFF3EDE1);

  /// Now the warm dark ink (was semi-transparent black for dark theme)
  static Color kBlack = const Color(0xFF221A12);

  static Color kOrange = Colors.orange;

  static Color kPureBlack = Colors.black;

  /// Now white (was dark card for dark theme)
  static Color kGreyCard = Colors.white;

  /// Warm hairline border for light theme
  static Color kBorderColor = const Color(0xFFE7DCC8);

  static Color kTabGreyColor = const Color(0xFFA79C8D);

  static Color kWhite = Colors.white;

  static Color kgrey = Colors.grey;

  /// Now warm grey text (was light grey for dark theme)
  static Color kPrimaryGrey = const Color(0xFF6F6558);
}

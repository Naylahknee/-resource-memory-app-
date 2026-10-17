import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A centralized typography system using Google Fonts — Atkinson Hyperlegible.
///
/// NanyNany design system: Atkinson Hyperlegible was designed for legibility
/// (letters like I, l and 1 are easy to tell apart). It ships in 400 and 700
/// only, so every style uses one of those two weights. Nothing renders below
/// 12px; body text stays at 14px or more.

abstract final class AppTypography {
  AppTypography._();

  // ─── Base ────────────────────────────────────────────────────────────────

  static TextStyle _font({
    required double fontSize,
    required FontWeight fontWeight,
    double? height,
    double? letterSpacing,
  }) => GoogleFonts.atkinsonHyperlegible(
    fontSize: fontSize,
    fontWeight: fontWeight,
    height: height ?? 1.4,
    letterSpacing: letterSpacing,
  );

  // ─── Display ─────────────────────────────────────────────────────────────

  static final TextStyle displayLg = _font(
    fontSize: 40,
    fontWeight: FontWeight.w700,
    height: 1.15,
    letterSpacing: -0.5,
  );

  /// 32px · Bold — Section titles
  static final TextStyle displayMd = _font(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.3,
  );

  // ─── Headings ─────────────────────────────────────────────────────────────

  /// 28px · Bold
  static final TextStyle h1 = _font(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
  );

  /// 24px · Bold
  static final TextStyle h2 = _font(
    fontSize: 24,
    fontWeight: FontWeight.w700,
  );

  static final TextStyle h3 = _font(
    fontSize: 20,
    fontWeight: FontWeight.w700,
  );

  static final TextStyle h4 = _font(
    fontSize: 18,
    fontWeight: FontWeight.w700,
  );

  // ─── Body ─────────────────────────────────────────────────────────────────

  static final TextStyle bodyLg = _font(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.6,
  );

  /// 14px · Regular — Secondary body text
  static final TextStyle bodyMd = _font(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.6,
  );

  static final TextStyle bodySm = _font(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  // ─── Labels / UI ──────────────────────────────────────────────────────────

  /// 14px · Bold — Buttons, tabs, nav
  static final TextStyle labelLg = _font(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.1,
  );

  /// 13px · Bold — Chips, badges, tags
  static final TextStyle labelMd = _font(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
  );

  static final TextStyle labelSm = _font(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.4,
  );

  // ─── Caption ──────────────────────────────────────────────────────────────

  static final TextStyle caption = _font(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.4,
    letterSpacing: 0.2,
  );

  // ─── Theme Helper ─────────────────────────────────────────────────────────

  static TextTheme get textTheme => TextTheme(
    displayLarge: displayLg,
    displayMedium: displayMd,
    headlineLarge: h1,
    headlineMedium: h2,
    headlineSmall: h3,
    titleLarge: h4,
    bodyLarge: bodyLg,
    bodyMedium: bodyMd,
    bodySmall: bodySm,
    labelLarge: labelLg,
    labelMedium: labelMd,
    labelSmall: labelSm,
  );
}

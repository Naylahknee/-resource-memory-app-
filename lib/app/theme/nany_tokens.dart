import 'package:flutter/material.dart';

/// NanyNany design system tokens.
///
/// Source of truth: the "NanyNany" design system in Claude Design.
/// Every text pair passes 4.5:1 contrast in its theme; the high contrast
/// theme passes 10:1.
///
/// Rule: [startHere] (marigold) is reserved for the single Start here task.
/// Never use it for anything else.

/// Light theme (default).
abstract final class NanyLight {
  NanyLight._();

  static const bg = Color(0xFFF7F3EC);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSunken = Color(0xFFEFE9DF);
  static const surfaceInverse = Color(0xFF24211D);
  static const ink = Color(0xFF24211D);
  static const inkMuted = Color(0xFF655E55);
  static const inkOnInverse = Color(0xFFF7F3EC);
  static const line = Color(0xFFE3DCD0);
  static const lineStrong = Color(0xFF8A8276);
  static const brand = Color(0xFF1F6F6B);
  static const brandStrong = Color(0xFF175753);
  static const onBrand = Color(0xFFFFFFFF);
  static const startHere = Color(0xFFF2B33D);
  static const onStartHere = Color(0xFF24211D);
  static const stateSavedBg = Color(0xFFECE6DB);
  static const stateSavedFg = Color(0xFF544D44);
  static const statePossibleBg = Color(0xFFEEE7F7);
  static const statePossibleFg = Color(0xFF5B3F8C);
  static const stateConfirmedBg = Color(0xFFDDEFEC);
  static const stateConfirmedFg = Color(0xFF1F5F5B);
  static const stateNowBg = Color(0xFFFBE3D6);
  static const stateNowFg = Color(0xFF9C3C17);
  static const stateDoneBg = Color(0xFFE3ECDC);
  static const stateDoneFg = Color(0xFF3D5E2E);
}

/// Dark theme.
abstract final class NanyDark {
  NanyDark._();

  static const bg = Color(0xFF17161A);
  static const surface = Color(0xFF222127);
  static const surfaceSunken = Color(0xFF1D1C21);
  static const surfaceInverse = Color(0xFFF2EEE7);
  static const ink = Color(0xFFF2EEE7);
  static const inkMuted = Color(0xFFA8A198);
  static const inkOnInverse = Color(0xFF17161A);
  static const line = Color(0xFF34323A);
  static const lineStrong = Color(0xFF7C7682);
  static const brand = Color(0xFF5FC2B9);
  static const brandStrong = Color(0xFF7FD3CB);
  static const onBrand = Color(0xFF0F2422);
  static const startHere = Color(0xFFF2B33D);
  static const onStartHere = Color(0xFF24211D);
  static const stateSavedBg = Color(0xFF2C2A30);
  static const stateSavedFg = Color(0xFFC9C2B8);
  static const statePossibleBg = Color(0xFF2E2740);
  static const statePossibleFg = Color(0xFFCDB8F2);
  static const stateConfirmedBg = Color(0xFF1C3533);
  static const stateConfirmedFg = Color(0xFF8FD6CE);
  static const stateNowBg = Color(0xFF3D2419);
  static const stateNowFg = Color(0xFFF5A57E);
  static const stateDoneBg = Color(0xFF24301F);
  static const stateDoneFg = Color(0xFFA9CF95);
}

/// High contrast theme (Settings > Appearance).
/// State tags have white fills here, so draw them with a 1.5px border in
/// their text color.
abstract final class NanyContrast {
  NanyContrast._();

  static const bg = Color(0xFFFFFFFF);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSunken = Color(0xFFF0F0F0);
  static const surfaceInverse = Color(0xFF000000);
  static const ink = Color(0xFF000000);
  static const inkMuted = Color(0xFF2E2E2E);
  static const inkOnInverse = Color(0xFFFFFFFF);
  static const line = Color(0xFF000000);
  static const lineStrong = Color(0xFF000000);
  static const brand = Color(0xFF004541);
  static const brandStrong = Color(0xFF002E2B);
  static const onBrand = Color(0xFFFFFFFF);
  static const startHere = Color(0xFFF2B33D);
  static const onStartHere = Color(0xFF000000);
  static const stateSavedBg = Color(0xFFFFFFFF);
  static const stateSavedFg = Color(0xFF000000);
  static const statePossibleBg = Color(0xFFFFFFFF);
  static const statePossibleFg = Color(0xFF3B1F6B);
  static const stateConfirmedBg = Color(0xFFFFFFFF);
  static const stateConfirmedFg = Color(0xFF004541);
  static const stateNowBg = Color(0xFFFFFFFF);
  static const stateNowFg = Color(0xFF7A2500);
  static const stateDoneBg = Color(0xFFFFFFFF);
  static const stateDoneFg = Color(0xFF244015);
}

/// Spacing, radius and size tokens.
abstract final class NanySpace {
  NanySpace._();

  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16; // Card padding, screen gutter.
  static const double s6 = 24; // Between cards and sections.
  static const double s8 = 32;
  static const double s12 = 48;

  static const double radiusSm = 8;
  static const double radiusMd = 14; // Buttons.
  static const double radiusLg = 20; // Memory Cards and sheets.
  static const double radiusPill = 999; // State tags.

  static const double tapMin = 48; // Minimum tap target.
}

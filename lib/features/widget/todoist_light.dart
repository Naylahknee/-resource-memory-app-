import 'package:flutter/material.dart';
import 'package:resource_memory/app/theme/app_typography.dart';
import 'package:resource_memory/app/theme/nany_tokens.dart';

/// Light palette for redesigned screens, now carrying the NanyNany design
/// system values (see lib/app/theme/nany_tokens.dart).
/// Local only; the global AppTheme stays dark. Each redesigned screen
/// opts in by wrapping its Scaffold in [TodoistLightScope] and using
/// these colors instead of AppColors.
///
/// The class keeps its old name so no screen has to change in this step.
abstract final class TodoistLight {
  TodoistLight._();

  static const canvas = NanyLight.bg; // Warm paper background.
  static const surface = NanyLight.surface; // Cards and sheets.
  static const surfaceGray = NanyLight.surfaceSunken;
  static const hairline = NanyLight.line;
  static const ink = NanyLight.ink;
  static const secondary = NanyLight.inkMuted; // 6:1 on surface.
  static const muted = Color(0xFF6F685E); // Hints and metadata, 5:1 on bg.
  static const verb = NanyLight.brand; // NanyNany teal: primary actions only.
  static const verbTint = NanyLight.stateConfirmedBg; // Light teal tint.
  static const verbMuted = NanyLight.stateConfirmedBg; // Alias for verbTint.
  static const warm = NanyLight.stateNowFg; // Rust: urgency, stuck, timers.
  static const warmTint = NanyLight.stateNowBg; // Light rust tint.
  static const surfaceVariant = NanyLight.surfaceSunken; // Alias.
}

/// Gives a screen light-theme text and component defaults so
/// AppTypography styles (which carry no color of their own) render
/// dark ink on the warm white canvas.
class TodoistLightScope extends StatelessWidget {
  final Widget child;
  const TodoistLightScope({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    return Theme(
      data: base.copyWith(
        scaffoldBackgroundColor: TodoistLight.canvas,
        textTheme: base.textTheme.apply(
          bodyColor: TodoistLight.ink,
          displayColor: TodoistLight.ink,
        ),
        primaryTextTheme: base.primaryTextTheme.apply(
          bodyColor: TodoistLight.ink,
          displayColor: TodoistLight.ink,
        ),
        appBarTheme: base.appBarTheme.copyWith(
          backgroundColor: TodoistLight.canvas,
          foregroundColor: TodoistLight.ink,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: TodoistLight.ink),
          titleTextStyle: AppTypography.h3.copyWith(color: TodoistLight.ink),
        ),
        iconTheme: base.iconTheme.copyWith(color: TodoistLight.secondary),
        dividerTheme: base.dividerTheme.copyWith(color: TodoistLight.hairline),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: TodoistLight.verb,
            foregroundColor: Colors.white,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: TodoistLight.ink,
            side: const BorderSide(color: TodoistLight.hairline),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: TodoistLight.verb),
        ),
        chipTheme: base.chipTheme.copyWith(
          backgroundColor: TodoistLight.surfaceGray,
          labelStyle:
              AppTypography.labelMd.copyWith(color: TodoistLight.secondary),
          side: const BorderSide(color: TodoistLight.hairline),
        ),
        inputDecorationTheme: base.inputDecorationTheme.copyWith(
          fillColor: TodoistLight.surface,
          hintStyle: AppTypography.bodyMd.copyWith(color: TodoistLight.muted),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: TodoistLight.hairline, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: TodoistLight.verb, width: 1.2),
          ),
        ),
        switchTheme: base.switchTheme.copyWith(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return TodoistLight.verb;
            }
            return null;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return TodoistLight.verbTint;
            }
            return null;
          }),
        ),
        snackBarTheme: base.snackBarTheme.copyWith(
          backgroundColor: TodoistLight.ink,
          contentTextStyle:
              AppTypography.bodyMd.copyWith(color: Colors.white),
        ),
        dialogTheme: base.dialogTheme.copyWith(
          backgroundColor: TodoistLight.surface,
          titleTextStyle:
              AppTypography.h4.copyWith(color: TodoistLight.ink),
          contentTextStyle: AppTypography.bodyMd
              .copyWith(color: TodoistLight.secondary),
        ),
        popupMenuTheme: base.popupMenuTheme.copyWith(
          color: TodoistLight.surface,
          textStyle:
              AppTypography.bodyMd.copyWith(color: TodoistLight.ink),
        ),
        floatingActionButtonTheme: base.floatingActionButtonTheme.copyWith(
          backgroundColor: TodoistLight.verb,
          foregroundColor: Colors.white,
        ),
      ),
      child: child,
    );
  }
}

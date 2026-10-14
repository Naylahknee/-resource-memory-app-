import 'package:flutter/material.dart';
import 'package:resource_memory/app/theme/app_typography.dart';

/// Todoist-style light palette for redesigned screens.
/// Shared warm-white theme for the existing NanyNany screens.
abstract final class TodoistLight {
  TodoistLight._();

  static const canvas = Color(0xFFFDFCFA);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceGray = Color(0xFFFAFAFA);
  static const hairline = Color(0xFFEEEEEE);
  static const ink = Color(0xFF202020);
  static const secondary = Color(0xFF62615C);
  static const muted = Color(0xFF77746F);
  static const verb = Color(0xFFC83E32); // Todoist red: primary actions only.
  static const verbTint = Color(0xFFFBE5E2); // Light red tint for active states.
  static const verbMuted = Color(0xFFFBE5E2); // Alias for verbTint.
  static const warm = Color(0xFFEB8909); // P2 orange: secondary warmth.
  static const warmTint = Color(0xFFFEF3E2); // Light orange tint.
  static const surfaceVariant = Color(0xFFFAFAFA); // Alias for surfaceGray.
}

/// Gives a screen light-theme text and component defaults so
/// AppTypography styles (which carry no color of their own) render
/// dark ink on the warm white canvas.
class TodoistLightScope extends StatelessWidget {
  final Widget child;
  const TodoistLightScope({super.key, required this.child});

  static ThemeData themeFor(ThemeData base) => base.copyWith(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: TodoistLight.verb, brightness: Brightness.light, surface: TodoistLight.surface),
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
            minimumSize: const Size(48, 48),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(48, 48),
            foregroundColor: TodoistLight.ink,
            side: const BorderSide(color: TodoistLight.hairline),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: TodoistLight.verb, minimumSize: const Size(48, 48)),
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
      );

  @override
  Widget build(BuildContext context) => Theme(data: themeFor(Theme.of(context)), child: child);
}

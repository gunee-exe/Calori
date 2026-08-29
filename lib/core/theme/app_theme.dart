/// Assembles [ThemeData] from the tokens in `tokens.dart`.
///
/// Most of this app's surfaces are built from explicit tokens rather than from
/// Material components, so the theme's job is narrow: set the ground colour,
/// the type family, and the interaction feel, and keep Material's defaults from
/// contradicting the prototype.
library;

import 'package:flutter/material.dart';

import 'tokens.dart';

abstract final class AppTheme {
  static ThemeData build() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.surface,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.primary,
      secondary: AppColors.primary,
      onSecondary: AppColors.surface,
      // There is no error colour in this design. Material demands one, so it
      // gets the neutral over-target grey rather than a red that could leak
      // into a TextField or a SnackBar and break the no-red rule.
      error: AppColors.neutralOver,
      onError: AppColors.textPrimary,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      outline: AppColors.border,
      outlineVariant: AppColors.border,
      shadow: AppColors.textPrimary,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: AppType.family,
      scaffoldBackgroundColor: AppColors.bg,
      canvasColor: AppColors.bg,
      dividerColor: AppColors.border,
      splashFactory: InkRipple.splashFactory,
    );

    return base.copyWith(
      textTheme: _textTheme(base.textTheme),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppType.sectionHeader,
        foregroundColor: AppColors.textPrimary,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalBarrierColor: AppColors.scrim,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
        ),
      ),
      // Text selection and cursor follow the primary, not Material's default.
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.primary,
        selectionColor: AppColors.primaryContainer,
        selectionHandleColor: AppColors.primary,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        focusedBorder: InputBorder.none,
        enabledBorder: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        hintStyle: TextStyle(color: AppColors.textTertiary),
      ),
      // Every interactive surface in the prototype is at least 44px, and
      // Material's default 48px tap padding would fight the measured layout.
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.standard,
    );
  }

  static TextTheme _textTheme(TextTheme base) {
    return base.copyWith(
      displayLarge: AppType.goalTarget,
      displayMedium: AppType.ringPercent,
      headlineLarge: AppType.screenTitle,
      headlineMedium: AppType.dayKcal,
      headlineSmall: AppType.statNumber,
      titleLarge: AppType.sectionHeader,
      titleMedium: AppType.mealKcal,
      bodyLarge: AppType.bodyStrong,
      bodyMedium: AppType.body,
      bodySmall: AppType.secondary,
      labelLarge: AppType.body,
      labelMedium: AppType.sectionLabel,
      labelSmall: AppType.sourceBadge,
    );
  }
}

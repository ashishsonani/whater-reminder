import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// The single ThemeData entry point. Most styling lives in widget files and
/// in [AppTypography] / [AppColors] / [AppShadows], but this gives sensible
/// material defaults (page background, splash colors, icon defaults, etc).
class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.paper,
      canvasColor: AppColors.paper,
      colorScheme: const ColorScheme.light(
        primary: AppColors.teal,
        onPrimary: Colors.white,
        secondary: AppColors.accent,
        onSecondary: Colors.white,
        surface: AppColors.card,
        onSurface: AppColors.ink,
        error: AppColors.accent,
        onError: Colors.white,
      ),
      textTheme: GoogleFonts.interTightTextTheme(base.textTheme).apply(
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
      ),
      iconTheme: const IconThemeData(color: AppColors.ink, size: 20),
      splashFactory: InkRipple.splashFactory,
      highlightColor: AppColors.tealSoft.withOpacity(0.4),
      splashColor: AppColors.tealSoft.withOpacity(0.6),
    );
  }
}

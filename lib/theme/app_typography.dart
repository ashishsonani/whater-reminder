import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Typography system.
/// Display / serif → Fraunces (with optical sizing & italics).
/// Body / sans     → Inter Tight.
class AppTypography {
  AppTypography._();

  // ---- Helpers ----------------------------------------------------------
  static TextStyle _serif({
    double size = 16,
    FontWeight weight = FontWeight.w500,
    Color color = AppColors.ink,
    double letterSpacing = 0,
    double? height,
    FontStyle style = FontStyle.normal,
  }) =>
      GoogleFonts.fraunces(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
        fontStyle: style,
      );

  static TextStyle _sans({
    double size = 14,
    FontWeight weight = FontWeight.w500,
    Color color = AppColors.ink,
    double letterSpacing = 0,
    double? height,
  }) =>
      GoogleFonts.interTight(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );

  // ---- Display (Fraunces) ----------------------------------------------
  static TextStyle get greetingTitle => _serif(
        size: 26,
        weight: FontWeight.w500,
        letterSpacing: -0.5,
        height: 1.0,
      );

  static TextStyle get greetingTitleItalic => _serif(
        size: 26,
        weight: FontWeight.w400,
        letterSpacing: -0.5,
        height: 1.0,
        color: AppColors.teal,
        style: FontStyle.italic,
      );

  static TextStyle get amountCurrent => _serif(
        size: 52,
        weight: FontWeight.w500,
        letterSpacing: -2.0,
        height: 1.0,
      );

  static TextStyle get sectionTitle => _serif(
        size: 18,
        weight: FontWeight.w500,
        letterSpacing: -0.2,
      );

  static TextStyle get sectionTitleItalic => _serif(
        size: 18,
        weight: FontWeight.w400,
        letterSpacing: -0.2,
        color: AppColors.teal,
        style: FontStyle.italic,
      );

  static TextStyle get statValue => _serif(
        size: 20,
        weight: FontWeight.w600,
        letterSpacing: -0.4,
      );

  static TextStyle get historyAmount => _serif(
        size: 17,
        weight: FontWeight.w600,
        letterSpacing: -0.2,
      );

  static TextStyle get streakNum => _serif(
        size: 16,
        weight: FontWeight.w600,
      );

  // ---- Eyebrows / labels (uppercase, tracked) --------------------------
  static TextStyle get eyebrow => _serif(
        size: 11,
        weight: FontWeight.w500,
        letterSpacing: 2.0,
        color: AppColors.inkMute,
      );

  static TextStyle get heroLabel => _serif(
        size: 11,
        weight: FontWeight.w600,
        letterSpacing: 2.2,
        color: AppColors.teal,
      );

  static TextStyle get percentBadge => _serif(
        size: 11,
        weight: FontWeight.w600,
        letterSpacing: 1.65,
        color: AppColors.teal,
      );

  // ---- Body (Inter Tight) ----------------------------------------------
  static TextStyle get amountUnit => _sans(
        size: 18,
        weight: FontWeight.w500,
        color: AppColors.inkMute,
      );

  static TextStyle get amountGoal => _sans(
        size: 12,
        weight: FontWeight.w500,
        color: AppColors.inkMute,
      );

  static TextStyle get amountGoalStrong => _sans(
        size: 12,
        weight: FontWeight.w600,
        color: AppColors.ink,
      );

  static TextStyle get streakLabel => _sans(
        size: 10,
        weight: FontWeight.w600,
        letterSpacing: 1.0,
        color: AppColors.inkMute,
      );

  static TextStyle get actionLabel => _sans(
        size: 10,
        weight: FontWeight.w600,
        letterSpacing: 1.2,
        color: AppColors.ink,
      );

  static TextStyle get actionSub => _sans(
        size: 10,
        weight: FontWeight.w500,
        color: AppColors.inkMute,
      );

  static TextStyle get drinkBtnLabel => _sans(
        size: 10,
        weight: FontWeight.w700,
        letterSpacing: 1.5,
        color: Colors.white,
      );

  static TextStyle get drinkBtnMl => _sans(
        size: 9,
        weight: FontWeight.w500,
        color: Colors.white70,
      );

  static TextStyle get statLabel => _sans(
        size: 10,
        weight: FontWeight.w600,
        letterSpacing: 1.2,
        color: AppColors.inkMute,
      );

  static TextStyle get statSmall => _sans(
        size: 11,
        weight: FontWeight.w500,
        color: AppColors.inkMute,
      );

  static TextStyle get statTrend => _sans(
        size: 10,
        weight: FontWeight.w600,
        color: AppColors.good,
      );

  static TextStyle get greetingDate => _sans(
        size: 12,
        weight: FontWeight.w500,
        color: AppColors.inkMute,
      );

  static TextStyle get historyType => _sans(
        size: 11,
        weight: FontWeight.w500,
        color: AppColors.inkMute,
      );

  static TextStyle get historyUnit => _sans(
        size: 11,
        weight: FontWeight.w500,
        color: AppColors.inkMute,
      );

  static TextStyle get historyTime => _sans(
        size: 11,
        weight: FontWeight.w600,
        color: AppColors.inkMute,
      );

  static TextStyle get viewAll => _sans(
        size: 11,
        weight: FontWeight.w600,
        letterSpacing: 1.1,
        color: AppColors.tealBright,
      );

  static TextStyle get heroTime => _sans(
        size: 11,
        weight: FontWeight.w500,
        color: AppColors.inkMute,
      );

  static TextStyle get navLabel => _sans(
        size: 10,
        weight: FontWeight.w600,
        letterSpacing: 0.5,
      );
}

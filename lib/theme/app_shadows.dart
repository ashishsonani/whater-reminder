import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Elevation, radius and spacing tokens.
class AppShadows {
  AppShadows._();

  // Light, "barely there" elevation — used on list rows and stats strip.
  static const List<BoxShadow> level1 = [
    BoxShadow(
      color: Color(0x0A0E1F26), // rgba(14,31,38,.04)
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
    BoxShadow(
      color: Color(0x0A0E1F26),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  // Card elevation for the hero block.
  static const List<BoxShadow> level2 = [
    BoxShadow(
      color: Color(0x0F0E1F26), // ~6% alpha
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x0D0E1F26),
      blurRadius: 32,
      offset: Offset(0, 12),
    ),
  ];

  // Bold elevation for the central drink button.
  static List<BoxShadow> drinkButton = [
    BoxShadow(
      color: AppColors.teal.withOpacity(0.35),
      blurRadius: 48,
      offset: const Offset(0, 20),
    ),
  ];

  // Phone-frame shadow (web demo only).
  static const List<BoxShadow> phoneFrame = [
    BoxShadow(color: Color(0x66000000), blurRadius: 80, offset: Offset(0, 30)),
  ];
}

class AppRadii {
  AppRadii._();
  static const double sm = 12;
  static const double md = 18;
  static const double lg = 24;
  static const double xl = 32;
  static const double pill = 100;
  static const double phone = 44;
}

class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 28;
}

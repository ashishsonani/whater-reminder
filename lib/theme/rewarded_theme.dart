import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:water_intake/theme/app_colors.dart';

class ThemeReward extends ValueNotifier<DateTime?> {
  ThemeReward() : super(null);

  static final instance = ThemeReward();
  static const _expiryKey = 'oceanDuskThemeUnlockedUntil';
  static const duration = Duration(hours: 24);
  Timer? _expiryTimer;

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt(_expiryKey);
    _setExpiry(
      saved == null ? null : DateTime.fromMillisecondsSinceEpoch(saved),
    );
  }

  Future<void> grant() async {
    final expiry = DateTime.now().add(duration);
    _setExpiry(expiry);
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setInt(_expiryKey, expiry.millisecondsSinceEpoch)) {
      throw StateError('Could not save the theme unlock');
    }
  }

  void _setExpiry(DateTime? expiry) {
    _expiryTimer?.cancel();
    final remaining = expiry?.difference(DateTime.now());
    if (remaining == null || remaining <= Duration.zero) {
      value = null;
      return;
    }
    value = expiry;
    _expiryTimer = Timer(remaining, () => value = null);
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    super.dispose();
  }
}

class RewardedThemeScope extends InheritedNotifier<ThemeReward> {
  RewardedThemeScope({super.key, required super.child})
    : super(notifier: ThemeReward.instance);
}

class HydrationPalette {
  const HydrationPalette(this.bright, this.accent, this.deep, this.soft);

  final Color bright;
  final Color accent;
  final Color deep;
  final Color soft;

  static const standard = HydrationPalette(
    AppColors.tealBright,
    AppColors.teal,
    AppColors.tealDeep,
    AppColors.tealSoft,
  );
  static const oceanDusk = HydrationPalette(
    Color(0xFF7163CE),
    Color(0xFF5542AC),
    Color(0xFF312477),
    Color(0xFFE5DEFF),
  );

  static HydrationPalette of(BuildContext context) {
    final expiry = context
        .dependOnInheritedWidgetOfExactType<RewardedThemeScope>()
        ?.notifier
        ?.value;
    return expiry != null && expiry.isAfter(DateTime.now())
        ? oceanDusk
        : standard;
  }
}

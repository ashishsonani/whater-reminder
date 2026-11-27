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

class MilestoneTheme extends ChangeNotifier {
  static final instance = MilestoneTheme();
  static const requiredStreak = 7;
  static const _earnedKey = 'forestSpringThemeEarned';
  static const _selectedKey = 'forestSpringThemeSelected';
  bool _unlocked = false;
  bool _selected = false;
  bool _savingUnlock = false;

  bool get unlocked => _unlocked;
  bool get selected => _unlocked && _selected;

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    _unlocked = prefs.getBool(_earnedKey) ?? false;
    _selected = prefs.getBool(_selectedKey) ?? false;
    notifyListeners();
  }

  Future<void> recordStreak(int longest) async {
    if (_unlocked || _savingUnlock || longest < requiredStreak) return;
    _savingUnlock = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (await prefs.setBool(_earnedKey, true)) {
        _unlocked = true;
        notifyListeners();
      }
    } finally {
      _savingUnlock = false;
    }
  }

  Future<void> select(bool selected) async {
    if (!_unlocked) return;
    final prefs = await SharedPreferences.getInstance();
    if (await prefs.setBool(_selectedKey, selected)) {
      _selected = selected;
      notifyListeners();
    }
  }
}

class RewardedThemeScope extends InheritedNotifier<Listenable> {
  RewardedThemeScope({super.key, required super.child})
    : super(notifier: _themeChanges);

  static final _themeChanges = Listenable.merge([
    ThemeReward.instance,
    MilestoneTheme.instance,
  ]);
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

  static const forestSpring = HydrationPalette(
    Color(0xFF398151),
    Color(0xFF28643D),
    Color(0xFF184629),
    Color(0xFFDDF2E2),
  );

  static HydrationPalette of(BuildContext context) {
    context.dependOnInheritedWidgetOfExactType<RewardedThemeScope>();
    final expiry = ThemeReward.instance.value;
    if (expiry != null && expiry.isAfter(DateTime.now())) return oceanDusk;
    return MilestoneTheme.instance.selected ? forestSpring : standard;
  }
}

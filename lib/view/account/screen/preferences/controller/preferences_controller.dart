import 'package:water_intake/services/water_log_store.dart';
import 'dart:developer';

import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:water_intake/services/firebase_service.dart';

import 'package:water_intake/theme/app_colors.dart';
import '../../../../../utils/app_strings.dart';
import '../../../../../utils/local_storage.dart';
import '../../../../home/controller/home_controller.dart';

class PreferencesController extends GetxController {
  var weightUnit = 'kg'.obs;
  var intakeUnit = 'ml'.obs;
  var soundEnabled = true.obs;
  var vibrationEnabled = true.obs;
  var intakeGoal = 2950.obs;
  var timeFormat = '12-hour'.obs;
  var wakeUpTime = '8:00 AM'.obs;
  var bedTime = '10:00 PM'.obs;

  var gender = 'Male'.obs;
  var weightValue = 70.obs;
  var activityLevel = 'Moderately active'.obs;
  var climate = 'Temperate'.obs;
  var age = 25.obs;

  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadWithLegacyProfile();
  }

  Future<void> _loadWithLegacyProfile() async {
    await loadPreferences();
    final uid = await LocalStorage.getUserId();
    if (uid == null || isClosed) return;
    try {
      await FirebaseService().importLegacyProfile(uid);
      if (!isClosed) await loadPreferences();
    } catch (e) {
      log('Could not import legacy hydration profile: $e');
    }
  }

  Future<void> loadPreferences() async {
    final fallbackWeightUnit = await LocalStorage.getWeightUnit();
    final fallbackIntakeUnit = await LocalStorage.getIntakeUnit();
    final fallbackTimeFormat = await LocalStorage.getTimeFormat();
    final fallbackClimate = await LocalStorage.getClimate();
    final sound = await LocalStorage.isSoundEnabled();
    final vibration = await LocalStorage.isVibrationEnabled();
    final days = await WaterLogStore.instance.read();
    if (isClosed) return;

    final profile = LocalStorage.readHydrationProfile();
    final today = WaterLogStore.dateKey(DateTime.now());
    final dates = days.keys.where((date) => date.compareTo(today) <= 0 && days[date]!.goal > 0).toList()..sort();
    final latestGoal = dates.isEmpty ? null : days[dates.last];
    final isKg = profile['isKg'] as bool?;
    weightUnit.value = isKg == null ? fallbackWeightUnit : (isKg ? 'kg' : 'lb');
    intakeUnit.value = latestGoal == null ? fallbackIntakeUnit : (latestGoal.isMl ? 'ml' : 'oz');
    intakeGoal.value = latestGoal?.goal ?? 2950;
    soundEnabled.value = sound;
    vibrationEnabled.value = vibration;
    timeFormat.value = profile['timeFormat'] as String? ?? fallbackTimeFormat;
    climate.value = profile['climate'] as String? ?? fallbackClimate;
    wakeUpTime.value = profile['wakeUpTime'] as String? ?? '8:00 AM';
    bedTime.value = profile['bedTime'] as String? ?? '10:00 PM';
    gender.value = profile['gender'] as String? ?? 'Male';
    weightValue.value = (profile['weight'] as num?)?.toInt() ?? 70;
    activityLevel.value = profile['activityLevel'] as String? ?? 'Moderately active';
    age.value = (profile['age'] as num?)?.toInt() ?? 25;
  }

  Future<void> toggleWeightUnit(String unit) async {
    if (weightUnit.value == unit) return;

    // Convert existing weight value
    if (unit == 'kg') {
      weightValue.value = (weightValue.value / 2.20462).round();
    } else {
      weightValue.value = (weightValue.value * 2.20462).round();
    }

    weightUnit.value = unit;
    await LocalStorage.updateHydrationProfile({'isKg': unit == 'kg', 'weight': weightValue.value});

    if (Get.isRegistered<HomeController>()) {
      Get.find<HomeController>().isKg.value = (unit == 'kg');
    }
  }

  Future<void> toggleIntakeUnit(String unit) async {
    if (intakeUnit.value == unit) return;

    // Convert existing goal value
    if (unit == 'ml') {
      intakeGoal.value = (intakeGoal.value * 29.5735).round();
    } else {
      intakeGoal.value = (intakeGoal.value / 29.5735).round();
    }

    intakeUnit.value = unit;
    await LocalStorage.setIntakeUnit(unit);
    if (Get.isRegistered<HomeController>()) {
      final home = Get.find<HomeController>();
      await home.updateUnit(unit == 'ml');
    } else {
      await WaterLogStore.instance.setGoal(intakeGoal.value, unit == 'ml');
    }
  }

  Future<void> toggleSound(bool value) async {
    soundEnabled.value = value;
    await LocalStorage.setSoundEnabled(value);
  }

  Future<void> toggleVibration(bool value) async {
    vibrationEnabled.value = value;
    await LocalStorage.setVibrationEnabled(value);
  }

  Future<void> updateIntakeGoal(int goal) async {
    intakeGoal.value = goal;
    if (Get.isRegistered<HomeController>()) {
      await Get.find<HomeController>().updateGoal(goal);
    } else {
      await WaterLogStore.instance.setGoal(goal, await LocalStorage.getIntakeUnit() == 'ml');
    }
  }

  int getRecommendedGoal() {
    double weightKg = weightUnit.value == 'kg' ? weightValue.value.toDouble() : weightValue.value / 2.20462;
    String gen = gender.value.toLowerCase();
    String clim = climate.value.toLowerCase();
    String act = activityLevel.value.toLowerCase();

    // 1. Calculate Base (35ml per kg)
    double goal = weightKg * 35;

    // 2. Adjust for Gender/Life Stage
    if (gen == 'female') {
      goal *= 0.9;
    } else if (gen == 'pregnant') {
      goal = (weightKg * 35 * 0.9) + 350; // Base Female + Pregnancy Addition
    } else if (gen == 'breastfeeding') {
      goal = (weightKg * 35 * 0.9) + 700; // Base Female + Nursing Addition
    }

    // 3. Apply Climate Multiplier
    if (clim == 'hot') {
      goal *= 1.20; // +20%
    } else if (clim == 'temperate') {
      goal *= 1.0;
    } else if (clim == 'cold') {
      goal *= 1.0; // Stay at baseline
    }

    // 4. Apply Activity Multiplier
    if (act.contains('light')) {
      goal *= 1.10;
    } else if (act.contains('moderate')) {
      goal *= 1.20;
    } else if (act.contains('very active') || act.contains('very_active')) {
      goal *= 1.40;
    } else {
      // sedentary or default
      goal *= 1.0;
    }

    // Return as an integer rounded to the nearest 50ml for better UX
    int goalMl = (goal / 50).round() * 50;

    if (intakeUnit.value != 'ml') {
      // Return in oz
      return (goalMl / 29.5735).round();
    }

    return goalMl;
  }

  void calculateRecommendedGoal() {
    int goalMl = getRecommendedGoal();
    updateIntakeGoal(goalMl);
  }

  Future<void> updateTimeFormat(String format) async {
    timeFormat.value = format;
    await LocalStorage.updateHydrationProfile({'timeFormat': format});
  }

  String getFormattedTime(String timeStr) {
    if (timeStr.isEmpty) return '';

    try {
      DateTime time;
      if (timeStr.contains('AM') || timeStr.contains('PM') || timeStr.contains('ÖÖ') || timeStr.contains('ÖS')) {
        // Handle 12H stored formats (including localized ones)
        String cleanStr = timeStr.replaceAll('ÖÖ', 'AM').replaceAll('ÖS', 'PM');
        time = DateFormat("hh:mm a").parse(cleanStr);
      } else {
        // Handle 24H stored formats
        time = DateFormat("HH:mm").parse(timeStr);
      }

      if (timeFormat.value == '12-hour') {
        String formatted = DateFormat("hh:mm").format(time);
        String amPm = DateFormat("a").format(time) == 'AM' ? AppString.amText.tr : AppString.pmText.tr;
        return "$formatted $amPm";
      } else {
        return DateFormat("HH:mm").format(time);
      }
    } catch (e) {
      log("Error formatting time: $e");
      return timeStr;
    }
  }

  Future<void> updateWakeUpTime(String time) async {
    wakeUpTime.value = time;
    await LocalStorage.updateHydrationProfile({'wakeUpTime': time});
  }

  Future<void> updateBedTime(String time) async {
    bedTime.value = time;
    await LocalStorage.updateHydrationProfile({'bedTime': time});
  }

  Future<void> updateGender(String val) async {
    gender.value = val;
    await LocalStorage.updateHydrationProfile({'gender': val});
    calculateRecommendedGoal();
  }

  Future<void> updateWeightValue(int val) async {
    weightValue.value = val;
    await LocalStorage.updateHydrationProfile({'weight': val});
    calculateRecommendedGoal();
  }

  Future<void> updateActivityLevel(String val) async {
    activityLevel.value = val;
    await LocalStorage.updateHydrationProfile({'activityLevel': val});
    calculateRecommendedGoal();
  }

  Future<void> updateClimate(String val) async {
    climate.value = val;
    await LocalStorage.updateHydrationProfile({'climate': val});
    calculateRecommendedGoal();
  }

  Future<void> resetAllTracking() async {
    isLoading.value = true;
    try {
      await LocalStorage.updateHydrationProfile({
        'gender': 'Male',
        'weight': 70,
        'isKg': true,
        'age': 30,
        'wakeUpTime': '7:00 AM',
        'bedTime': '10:00 PM',
        'activityLevel': 'Moderate Active',
        'climate': 'Temperate',
        'timeFormat': '12-hour',
        'awards': <String>[],
        'celebratedAwards': <String>[],
        'legacyImported': true,
      });
      await WaterLogStore.instance.clear();
      await WaterLogStore.instance.setGoal(2950, true);

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('water_custom_cups');
      await prefs.remove('customCups');
      await prefs.remove('customTypes');
      await prefs.remove('lastLogDate');
      await prefs.remove('selectedCupIndex');
      await LocalStorage.setIntakeUnit('ml');
      await loadPreferences();

      if (Get.isRegistered<HomeController>()) {
        final home = Get.find<HomeController>();
        home.skipFeedback = true;
        await home.refreshAllData();
      }

      Get.snackbar(
        AppString.success.tr,
        AppString.resetData.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
        colorText: AppColors.primary,
      );
    } catch (error) {
      log('Could not reset tracking: $error');
      Get.snackbar(AppString.error.tr, AppString.error.tr);
    } finally {
      isLoading.value = false;
    }
  }

  void skip() {
    Get.back();
  }
}

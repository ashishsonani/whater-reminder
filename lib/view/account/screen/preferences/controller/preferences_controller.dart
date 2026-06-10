import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:water_intake/models/user_model.dart';
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
  var isPremium = false.obs;

  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadPreferences();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    isLoading.value = true;
    try {
      String? uid = await FirebaseService().getUserId();
      if (uid == null) return;

      var doc = await FirebaseService().firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final user = UserModel.fromMap(doc.data()!, doc.id);

        weightUnit.value = user.isKg ? 'kg' : 'lb';
        intakeUnit.value = user.isMl ? 'ml' : 'oz';
        intakeGoal.value = user.waterGoal;
        wakeUpTime.value = user.wakeUpTime;
        bedTime.value = user.bedTime;
        gender.value = user.gender;
        weightValue.value = user.weight;
        activityLevel.value = user.activityLevel;
        climate.value = user.climate;
        age.value = user.age;
        timeFormat.value = user.timeFormat;
        isPremium.value = user.isPremium;
      }
    } catch (e) {
      log("Error fetching user data: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _updateFirestore(Map<String, dynamic> data) async {
    isLoading.value = true;
    try {
      String? uid = await FirebaseService().getUserId();
      if (uid == null) return;

      await FirebaseService().firestore.collection('users').doc(uid).update({...data, 'updatedAt': FieldValue.serverTimestamp()});
    } catch (e) {
      log("Error updating user data in Firestore: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadPreferences() async {
    weightUnit.value = await LocalStorage.getWeightUnit();
    intakeUnit.value = await LocalStorage.getIntakeUnit();
    soundEnabled.value = await LocalStorage.isSoundEnabled();
    vibrationEnabled.value = await LocalStorage.isVibrationEnabled();
    timeFormat.value = await LocalStorage.getTimeFormat();
    climate.value = await LocalStorage.getClimate();
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
    await LocalStorage.setWeightUnit(unit);
    await _updateFirestore({'isKg': unit == 'kg', 'weight': weightValue.value});

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
    await _updateFirestore({'isMl': unit == 'ml', 'waterGoal': intakeGoal.value});

    if (Get.isRegistered<HomeController>()) {
      final home = Get.find<HomeController>();
      await home.updateUnit(unit == 'ml');
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
    String? uid = await FirebaseService().getUserId();
    if (uid == null) return;

    // 1. Update Global Goal in User Profile
    await _updateFirestore({'waterGoal': goal});

    // 2. Update Today's Summary
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await FirebaseService().firestore.collection('users').doc(uid).collection('water_records').doc(today).set({
      'targetIntakeValue': goal,
    }, SetOptions(merge: true));

    // 3. Notify HomeController if it's open
    if (Get.isRegistered<HomeController>()) {
      Get.find<HomeController>().targetIntake.value = goal;
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
    await LocalStorage.setTimeFormat(format);
    await _updateFirestore({'timeFormat': format});
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
    await _updateFirestore({'wakeUpTime': time});
  }

  Future<void> updateBedTime(String time) async {
    bedTime.value = time;
    await _updateFirestore({'bedTime': time});
  }

  Future<void> updateGender(String val) async {
    gender.value = val;
    await _updateFirestore({'gender': val});
    calculateRecommendedGoal();
  }

  Future<void> updateWeightValue(int val) async {
    weightValue.value = val;
    await _updateFirestore({'weight': val});
    calculateRecommendedGoal();
  }

  Future<void> updateActivityLevel(String val) async {
    activityLevel.value = val;
    await _updateFirestore({'activityLevel': val});
    calculateRecommendedGoal();
  }

  Future<void> updateClimate(String val) async {
    climate.value = val;
    await LocalStorage.setClimate(val);
    await _updateFirestore({'climate': val});
    calculateRecommendedGoal();
  }

  Future<void> resetAllTracking() async {
    isLoading.value = true;
    // try {
    String? uid = await FirebaseService().getUserId();
    if (uid == null) return;

    // 1. Reset User Profile to defaults in Firestore
    Map<String, dynamic> defaultData = {
      'gender': 'Male',
      'weight': 70,
      'isKg': true,
      'age': 30,
      'wakeUpTime': '7:00 AM',
      'bedTime': '10:00 PM',
      'activityLevel': 'Moderate Active',
      'climate': 'Temperate',
      "timeFormat": '12-hour',
      'waterGoal': 2950,
      'isMl': true,
      'currentStreak': 0,
      'longestStreak': 0,
      'awards': [],
      'celebratedAwards': [],
      'lastStreakDate': '',
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await FirebaseService().firestore.collection('users').doc(uid).update(defaultData);

    // 2. Clear all water records in Firestore
    var waterRecordsRef = FirebaseService().firestore.collection('users').doc(uid).collection('water_records');
    var snapshots = await waterRecordsRef.get();

    for (var doc in snapshots.docs) {
      // Delete the daily_records subcollection docs first
      var dailyRecords = await doc.reference.collection('daily_records').get();
      for (var dailyDoc in dailyRecords.docs) {
        await dailyDoc.reference.delete();
      }
      // Delete the summary doc
      await doc.reference.delete();
    }

    // 3. Reset Local Storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('water_custom_cups'); // Used in HomeController
    await prefs.remove('customCups'); // Used in LocalStorage
    await prefs.remove('customTypes');
    await prefs.remove('lastLogDate');
    await prefs.remove('selectedCupIndex');

    await LocalStorage.setWeightUnit('kg');
    await LocalStorage.setIntakeUnit('ml');
    await LocalStorage.setTimeFormat('12-hour');
    await LocalStorage.setClimate('Temperate');

    // 4. Reload local controller state
    await loadPreferences();
    await fetchUserData();

    // 5. Notify HomeController to refresh its data if it's open
    if (Get.isRegistered<HomeController>()) {
      final homeController = Get.find<HomeController>();
      homeController.skipFeedback = true;
      await homeController.refreshAllData();
    }

    Get.snackbar(
      AppString.success.tr,
      AppString.resetData.tr,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.primary.withOpacity(0.1),
      colorText: AppColors.primary,
    );
    // } catch (e) {
    //   log("Error resetting all tracking: $e");
    //   Get.snackbar(AppString.error.tr, AppString.error.tr, snackPosition: SnackPosition.BOTTOM);
    // } finally {
    isLoading.value = false;
    // }
  }

  void skip() {
    Get.back();
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:water_intake/models/reminder_model.dart';
import 'package:water_intake/route/route.dart';
import 'package:water_intake/services/firebase_service.dart';
import 'package:water_intake/utils/local_storage.dart';

class WalkthroughController extends GetxController {
  var selectedGender = ''.obs;
  var currentStep = 1.obs;
  final int totalSteps = 7;

  // Step 2: Weight
  var weight = 70.obs;
  var isKg = true.obs;

  late FixedExtentScrollController weightScrollController;

  // Step 3: Age
  var age = 30.obs;
  late FixedExtentScrollController ageScrollController;

  // Step 4: Wake up time
  var is12HourFormat = true.obs;
  var wakeUpHour = 7.obs;
  var wakeUpMinute = 0.obs;
  var isAm = true.obs;

  late FixedExtentScrollController hourScrollController;
  late FixedExtentScrollController minuteScrollController;
  late FixedExtentScrollController amPmScrollController;

  // Step 5: Bed time
  var bedTimeHour = 10.obs; // 10 or 22
  var bedTimeMinute = 0.obs;
  var isBedTimeAm = false.obs; // PM

  late FixedExtentScrollController bedHourScrollController;
  late FixedExtentScrollController bedMinuteScrollController;
  late FixedExtentScrollController bedAmPmScrollController;

  // Step 6: Activity Level
  var selectedActivity = 'moderate'.obs;

  // Step 7: Climate
  var selectedClimate = 'temperate'.obs;

  // Loading State
  var isCreatingPlan = false.obs;
  var progressValue = 0.obs;

  // Goal Screen State
  var isPlanCreated = false.obs;
  var waterGoal = 2950.obs;
  var tempWaterGoal = 2950.obs;
  var isMl = true.obs;
  var isNotificationEnabled = true.obs;

  @override
  void onInit() {
    super.onInit();
    weightScrollController = FixedExtentScrollController(initialItem: weight.value - 1);
    ageScrollController = FixedExtentScrollController(initialItem: age.value - 1);
    hourScrollController = FixedExtentScrollController(initialItem: wakeUpHour.value - (is12HourFormat.value ? 1 : 0));
    minuteScrollController = FixedExtentScrollController(initialItem: wakeUpMinute.value);
    amPmScrollController = FixedExtentScrollController(initialItem: isAm.value ? 0 : 1);

    bedHourScrollController = FixedExtentScrollController(initialItem: bedTimeHour.value - (is12HourFormat.value ? 1 : 0));
    bedMinuteScrollController = FixedExtentScrollController(initialItem: bedTimeMinute.value);
    bedAmPmScrollController = FixedExtentScrollController(initialItem: isBedTimeAm.value ? 0 : 1);
  }

  @override
  void onClose() {
    weightScrollController.dispose();
    ageScrollController.dispose();
    hourScrollController.dispose();
    minuteScrollController.dispose();
    amPmScrollController.dispose();
    bedHourScrollController.dispose();
    bedMinuteScrollController.dispose();
    bedAmPmScrollController.dispose();
    super.onClose();
  }

  void selectGender(String gender) {
    selectedGender.value = gender;
  }

  void nextStep() {
    if (currentStep.value < totalSteps) {
      currentStep.value++;
      _syncScrollControllers();
    } else {
      startCreatingPlan();
    }
  }

  void startCreatingPlan() async {
    isCreatingPlan.value = true;

    waterGoal.value = getRecommendedGoal();

    tempWaterGoal.value = waterGoal.value;

    // Store data in Firebase while loader is displayed
    saveUserDataToFirebase(shouldNavigate: false);

    for (int i = 1; i <= 100; i++) {
      await Future.delayed(const Duration(milliseconds: 20));
      progressValue.value = i;
    }
    isCreatingPlan.value = false;
    isPlanCreated.value = true;
    Get.offNamed(AppRoutes.goal);
  }

  void toggleGoalUnit(bool isMlUnit) {
    if (isMl.value == isMlUnit) return;
    isMl.value = isMlUnit;
    if (isMlUnit) {
      // oz to ml (1 oz = 29.5735 ml)
      int newGoal = (waterGoal.value * 29.5735).round();
      waterGoal.value = newGoal;
    } else {
      // ml to oz
      int newGoal = (waterGoal.value / 29.5735).round();
      waterGoal.value = newGoal;
    }
  }

  void previousStep() {
    if (currentStep.value > 1) {
      currentStep.value--;
      _syncScrollControllers();
    } else {
      Get.back();
    }
  }

  void _syncScrollControllers() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (currentStep.value == 2) {
        if (weightScrollController.hasClients) {
          weightScrollController.jumpToItem(weight.value - 1);
        }
      } else if (currentStep.value == 3) {
        if (ageScrollController.hasClients) {
          ageScrollController.jumpToItem(age.value - 1);
        }
      } else if (currentStep.value == 4) {
        if (hourScrollController.hasClients) hourScrollController.jumpToItem(wakeUpHour.value - (is12HourFormat.value ? 1 : 0));
        if (minuteScrollController.hasClients) minuteScrollController.jumpToItem(wakeUpMinute.value);
        if (amPmScrollController.hasClients) amPmScrollController.jumpToItem(isAm.value ? 0 : 1);
      } else if (currentStep.value == 5) {
        if (bedHourScrollController.hasClients) bedHourScrollController.jumpToItem(bedTimeHour.value - (is12HourFormat.value ? 1 : 0));
        if (bedMinuteScrollController.hasClients) bedMinuteScrollController.jumpToItem(bedTimeMinute.value);
        if (bedAmPmScrollController.hasClients) bedAmPmScrollController.jumpToItem(isBedTimeAm.value ? 0 : 1);
      }
    });
  }

  void toggleWeightUnit(bool kg) {
    if (isKg.value == kg) return;

    isKg.value = kg;
    if (kg) {
      // lb to kg
      int newWeight = (weight.value / 2.20462).round();
      weight.value = newWeight.clamp(1, 500);
    } else {
      // kg to lb
      int newWeight = (weight.value * 2.20462).round();
      weight.value = newWeight.clamp(1, 500);
    }

    if (weightScrollController.hasClients) {
      weightScrollController.jumpToItem(weight.value - 1);
    }
  }

  void setWeight(int val) {
    weight.value = val;
  }

  void setAge(int val) {
    age.value = val;
  }

  void toggleTimeFormat(bool is12H) {
    if (is12HourFormat.value == is12H) return;
    is12HourFormat.value = is12H;

    int newHour = wakeUpHour.value;
    int newBedHour = bedTimeHour.value;

    if (is12H) {
      // 24H -> 12H (Wake Up)
      if (newHour == 0) {
        newHour = 12;
        isAm.value = true;
      } else if (newHour == 12) {
        isAm.value = false;
      } else if (newHour > 12) {
        newHour -= 12;
        isAm.value = false;
      } else {
        isAm.value = true;
      }
      wakeUpHour.value = newHour;
      if (hourScrollController.hasClients) hourScrollController.jumpToItem(newHour - 1);
      if (amPmScrollController.hasClients) amPmScrollController.jumpToItem(isAm.value ? 0 : 1);

      // 24H -> 12H (Bed Time)
      if (newBedHour == 0) {
        newBedHour = 12;
        isBedTimeAm.value = true;
      } else if (newBedHour == 12) {
        isBedTimeAm.value = false;
      } else if (newBedHour > 12) {
        newBedHour -= 12;
        isBedTimeAm.value = false;
      } else {
        isBedTimeAm.value = true;
      }
      bedTimeHour.value = newBedHour;
      if (bedHourScrollController.hasClients) bedHourScrollController.jumpToItem(newBedHour - 1);
      if (bedAmPmScrollController.hasClients) bedAmPmScrollController.jumpToItem(isBedTimeAm.value ? 0 : 1);
    } else {
      // 12H -> 24H (Wake Up)
      if (isAm.value && newHour == 12) {
        newHour = 0;
      } else if (!isAm.value && newHour != 12) {
        newHour += 12;
      }
      wakeUpHour.value = newHour;
      if (hourScrollController.hasClients) hourScrollController.jumpToItem(newHour);

      // 12H -> 24H (Bed Time)
      if (isBedTimeAm.value && newBedHour == 12) {
        newBedHour = 0;
      } else if (!isBedTimeAm.value && newBedHour != 12) {
        newBedHour += 12;
      }
      bedTimeHour.value = newBedHour;
      if (bedHourScrollController.hasClients) bedHourScrollController.jumpToItem(newBedHour);
    }
  }

  void setWakeUpHour(int val) {
    wakeUpHour.value = val;
  }

  void setWakeUpMinute(int val) {
    wakeUpMinute.value = val;
  }

  void setAmPm(bool am) {
    isAm.value = am;
  }

  void setBedTimeHour(int val) {
    bedTimeHour.value = val;
  }

  void setBedTimeMinute(int val) {
    bedTimeMinute.value = val;
  }

  void setBedAmPm(bool am) {
    isBedTimeAm.value = am;
  }

  void selectActivity(String activity) {
    selectedActivity.value = activity;
  }

  int getRecommendedGoal() {
    double weightKg = isKg.value ? weight.value.toDouble() : weight.value / 2.20462;
    String gender = selectedGender.value.toLowerCase();
    String climate = selectedClimate.value.toLowerCase();
    String activity = selectedActivity.value.toLowerCase();

    // 1. Calculate Base (35ml per kg)
    double goal = weightKg * 35;

    // 2. Adjust for Gender/Life Stage
    if (gender == 'female') {
      goal *= 0.9;
    } else if (gender == 'pregnant') {
      goal = (weightKg * 35) + 350; // Base Female + Pregnancy Addition
    } else if (gender == 'breastfeeding') {
      goal = (weightKg * 35) + 700; // Base Female + Nursing Addition
    }

    // 3. Apply Climate Multiplier
    if (climate == 'hot') {
      goal *= 1.20; // +20%
    } else if (climate == 'temperate') {
      goal *= 1.0;
    } else if (climate == 'cold') {
      goal *= 1.0; // Stay at baseline
    }

    // 4. Apply Activity Multiplier
    switch (activity) {
      case 'light':
        goal *= 1.10;
        break;
      case 'moderate':
        goal *= 1.20;
        break;
      case 'very_active':
        goal *= 1.40;
        break;
      case 'sedentary':
      default:
        goal *= 1.0;
    }

    // Return as an integer rounded to the nearest 50ml for better UX
    int goalMl = (goal / 50).round() * 50;

    if (!isMl.value) {
      // Return in oz
      return (goalMl / 29.5735).round();
    }
    return goalMl;
  }

  void selectClimate(String climate) {
    selectedClimate.value = climate;
  }

  var isSaving = false.obs;

  Future<void> saveUserDataToFirebase({bool shouldNavigate = true}) async {
    isSaving.value = true;
    try {
      // 1. Get UID from Service (Check if already logged in or stored in LocalStorage)
      String? uid = await FirebaseService().getUserId();

      if (uid == null) {
        print("No UID found, starting anonymous sign-in...");
        UserCredential userCredential = await FirebaseService().auth.signInAnonymously();
        uid = userCredential.user!.uid;
        print("Successfully signed in. UID: $uid");
      } else {
        print("Using existing UID: $uid");
      }

      // 2. Store ID in Preference
      await LocalStorage.setUserId(uid);

      // 3. Prepare Data
      String? fcmToken = await FirebaseMessaging.instance.getToken();
      Map<String, dynamic> userData = {
        'uid': uid,
        'gender': selectedGender.value,
        'weight': weight.value,
        'isKg': isKg.value,
        'age': age.value,
        'wakeUpTime': '${wakeUpHour.value}:${wakeUpMinute.value.toString().padLeft(2, '0')} ${isAm.value ? 'AM' : 'PM'}',
        'bedTime': '${bedTimeHour.value}:${bedTimeMinute.value.toString().padLeft(2, '0')} ${isBedTimeAm.value ? 'AM' : 'PM'}',
        'activityLevel': selectedActivity.value,
        'climate': selectedClimate.value,
        'waterGoal': waterGoal.value,
        'isMl': isMl.value,
        'isNotificationEnabled': isNotificationEnabled.value,
        'fcmToken': fcmToken ?? '',
        'timezoneOffset': DateTime.now().timeZoneOffset.inMinutes,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // 4. Store in Firestore
      print("Saving data to Firestore...");
      await FirebaseService().firestore.collection('users').doc(uid).set(userData, SetOptions(merge: true));
      print("Data successfully saved to Firestore!");

      // 4.5 Save default reminder to ensure it exists if app is killed
      var remindersRef = FirebaseService().firestore.collection('users').doc(uid).collection('reminders');
      var existingDefaults = await remindersRef.where('isCustom', isEqualTo: false).limit(1).get();

      if (existingDefaults.docs.isEmpty) {
        var docRef = remindersRef.doc();
        ReminderModel defaultReminder = ReminderModel(
          id: docRef.id,
          uid: uid,
          timeRange: '8 AM – 10 PM',
          interval: 'Every 2 hours',
          isActive: true,
          isCustom: false,
        );
        await docRef.set(defaultReminder.toMap());
        print("Default reminder successfully saved to Firestore!");
      }

      // 5. Save only essential info to Local Storage
      await LocalStorage.setSetupComplete(true);
      await LocalStorage.setIntakeUnit(isMl.value ? 'ml' : 'oz');

      // 6. Navigate
      if (shouldNavigate) {
        Get.offAllNamed(AppRoutes.addReminder);
      }
    } catch (e) {
      debugPrint("Error saving user data: $e");
      Get.snackbar("Error", "Failed to save your data. Please try again.");
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> updateWaterGoalInFirebase() async {
    try {
      String? uid = await FirebaseService().getUserId();
      if (uid != null) {
        await FirebaseService().firestore.collection('users').doc(uid).update({
          'waterGoal': waterGoal.value,
          'isMl': isMl.value,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        await LocalStorage.setIntakeUnit(isMl.value ? 'ml' : 'oz');
        print("Water goal updated in Firebase and LocalStorage for UID: $uid");
      }
    } catch (e) {
      debugPrint("Error updating water goal: $e");
    }
  }
}

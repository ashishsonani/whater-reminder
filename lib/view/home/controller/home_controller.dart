import 'dart:convert';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:water_intake/gen/assets.gen.dart';
import 'package:water_intake/models/chart_datum.dart';
import 'package:water_intake/models/history_data.dart';
import 'package:water_intake/models/stats_data.dart';
import 'package:water_intake/models/user_model.dart';
import 'package:water_intake/models/water_record.dart';
import 'package:water_intake/services/firebase_service.dart';
import 'package:water_intake/utils/app_strings.dart';
import 'package:water_intake/utils/local_storage.dart';
import 'package:water_intake/view/dashboard/controller/dashboard_controller.dart';
import 'package:water_intake/view/home/widget/water_widgets.dart';

import '../screen/history/water_intake_history_view.dart';
import '../screen/home_screen.dart';
import '../../../services/ad_service.dart';

class HomeController extends GetxController with GetSingleTickerProviderStateMixin {
  var selectedCupIndex = 3.obs;
  var selectedCupCustomIndex = -1.obs;
  bool skipFeedback = false;
  bool _feedbackPromptShownThisSession = false;
  var favoriteDrinks = <String>[].obs;
  var recentDrinks = <String>[].obs;
  var customDrinkType = "".obs;
  var selectedDrinkAsset = Assets.images.png.plainWater.obs;

  var selectedCup = 175.obs;
  var selectedCupAsset = Assets.images.png.cupFill4.obs;
  var customCupAssetList = <AssetGenImage>[].obs;
  var customCupFillAssetList = <AssetGenImage>[].obs;
  var customCupIndices = <int>[].obs;
  var availableCups = <int>[100, 125, 150, 175, 200, 300, 1000].obs;
  var availableCupTypes = <String>[
    AppString.smallCup.tr,
    AppString.cup.tr,
    AppString.bigCup.tr,
    AppString.glass.tr,
    AppString.coffeeCup.tr,
    AppString.mug.tr,
    AppString.bottle.tr,
  ].obs;
  var dialogSelectedCupIndex = (-1).obs;
  // Map to store custom cup names and their selected fill asset icons
  final Map<String, AssetGenImage> _customIconMap = {};

  Future<void> saveCustomCups() async {
    await LocalStorage.saveCustomCups(availableCups, availableCupTypes);
  }

  void toggleFavoriteDrink(String displayName) {
    if (favoriteDrinks.contains(displayName)) {
      favoriteDrinks.remove(displayName);
    } else {
      favoriteDrinks.add(displayName);
    }
    LocalStorage.saveFavoriteDrinks(favoriteDrinks.toList());
  }

  void addRecentDrink(String filename) {
    if (!recentDrinks.contains(filename)) {
      recentDrinks.insert(0, filename);
      if (recentDrinks.length > 10) {
        recentDrinks.removeLast();
      }
    } else {
      recentDrinks.remove(filename);
      recentDrinks.insert(0, filename);
    }
    // LocalStorage.saveRecentDrinks(recentDrinks.toList()); // Optional
  }

  Future<void> loadCustomCups() async {
    final data = await LocalStorage.loadCustomCups();
    final amounts = data['amounts'];
    final types = data['types'];

    if (amounts != null && types != null && amounts.length == types.length) {
      for (int i = 0; i < amounts.length; i++) {
        int amount = int.tryParse(amounts[i]) ?? 0;
        String type = types[i];
        String indexStr = type.split('#').last;
        int iconIndex = int.tryParse(indexStr) ?? 0;

        if (iconIndex >= 0 && iconIndex < cupDesignAssets.length) {
          availableCups.add(amount);
          availableCupTypes.add(type);
          customCupAssetList.add(cupDesignAssets[iconIndex]);
          customCupFillAssetList.add(selectedCupList[iconIndex]);
          customCupIndices.add(iconIndex);
          _customIconMap[type] = selectedCupList[iconIndex];
        }
      }
    }
  }

  var drinkAmounts = <String, int>{}.obs;

  void setDrinkAmount(String filename, int amountMl) {
    drinkAmounts[filename.toLowerCase()] = amountMl;
    LocalStorage.saveDrinkAmounts(drinkAmounts);
  }

  var customDrinks = <CustomDrink>[].obs;

  void addCustomDrink(String name, double coefficient) {
    customDrinks.add(CustomDrink(name: name, coefficient: coefficient));
    final strings = customDrinks.map((e) => jsonEncode(e.toJson())).toList();
    LocalStorage.saveCustomDrinks(strings);
    update();
  }

  int getDrinkAmount(String filename) {
    final key = filename.toLowerCase();
    if (drinkAmounts.containsKey(key)) {
      return drinkAmounts[key]!;
    }
    if (key.contains("coff") || key.contains("cappa")) {
      return 150;
    } else if (key.contains("tea")) {
      return 200;
    } else {
      return 250;
    }
  }

  Map<String, List> get allType => {
    AppString.categoryWater.tr: [
      Assets.images.png.plainWater.image(scale: 5.5),
      Assets.images.png.mineralWater.image(scale: 5.5),
      Assets.images.png.sportDrink.image(scale: 5.5),
      Assets.images.png.enrgyDrink.image(scale: 5.5),
      Assets.images.png.zeroSportDrink.image(scale: 5.5),
      Assets.images.png.riceDrink.image(scale: 5.5),
      Assets.images.png.barleyDrink.image(scale: 5.5),
      Assets.images.png.sparklingWater.image(scale: 5.5),
    ],
    AppString.categoryTea.tr: [
      Assets.images.png.tea.image(scale: 5.5),
      Assets.images.png.milkTea.image(scale: 5.5),
      Assets.images.png.blackTea.image(scale: 5.5),
      Assets.images.png.greenTea.image(scale: 5.5),
    ],
    AppString.categoryCoffee.tr: [Assets.images.png.cappacuinoCoffie.image(scale: 5.5), Assets.images.png.mochaCoffee.image(scale: 5.5)],
    AppString.categoryMilk.tr: [Assets.images.png.lowFatMilk.image(scale: 5.5)],
    AppString.categoryJuice.tr: [
      Assets.images.png.orangeJuice.image(scale: 5.5),
      Assets.images.png.lemonJuice.image(scale: 5.5),
      Assets.images.png.pineappleJuice.image(scale: 5.5),
      Assets.images.png.watermelonJuice.image(scale: 5.5),
      Assets.images.png.peachJuice.image(scale: 5.5),
      Assets.images.png.strawberryJuice.image(scale: 5.5),
      Assets.images.png.coconutJuice.image(scale: 5.5),
      Assets.images.png.appleJuice.image(scale: 5.5),
      Assets.images.png.carrotJuice.image(scale: 5.5),
    ],
    AppString.myDrink.tr: [Assets.images.png.cupFill1.image(scale: 5.5)],
    AppString.categoryMore.tr: [Assets.images.png.more.image(scale: 3.3)],
  };

  void updateSelectedCup(int amount, int index) {
    selectedCup.value = amount;
    selectedCupIndex.value = index;
    update();
  }

  final List<AssetGenImage> cupDesignAssets = [
    Assets.images.png.cup1,
    Assets.images.png.cup2,
    Assets.images.png.cup3,
    Assets.images.png.cup4,
    Assets.images.png.cup5,
    Assets.images.png.cup6,
    Assets.images.png.cup7,
    Assets.images.png.cup8,
    Assets.images.png.cup9,
  ];
  final List<AssetGenImage> selectedCupList = [
    Assets.images.png.cupFill1,
    Assets.images.png.cupFill2,
    Assets.images.png.cupFill3,
    Assets.images.png.cupFill4,
    Assets.images.png.cupFill5,
    Assets.images.png.cupFill6,
    Assets.images.png.fillCup7,
    Assets.images.png.cupFill8,
    Assets.images.png.lastCup,
  ];
  void addCustomCup(String name, int amount, AssetGenImage asset, AssetGenImage fillAsset, {required int Selectedcup}) {
    final typeWithName = '$name#$Selectedcup';
    _customIconMap[typeWithName] = fillAsset;

    availableCups.add(amount);
    availableCupTypes.add(typeWithName);
    customCupAssetList.add(asset);
    customCupFillAssetList.add(fillAsset);
    customCupIndices.add(Selectedcup);
    saveCustomCups();
    update();
  }

  void updateCustomCup(int index, String name, int amount, AssetGenImage asset, AssetGenImage fillAsset, {required int Selectedcup}) {
    if (index > 6 && index < availableCups.length) {
      final typeWithName = '$name#$Selectedcup';
      _customIconMap[typeWithName] = fillAsset;
      availableCups[index] = amount;
      availableCupTypes[index] = typeWithName;
      int customListIndex = index - 7;
      if (customListIndex >= 0 && customListIndex < customCupAssetList.length) {
        customCupAssetList[customListIndex] = asset;
        customCupFillAssetList[customListIndex] = fillAsset;
        customCupIndices[customListIndex] = Selectedcup;
      }
      // If updating the currently selected cup, update global variables
      if (selectedCupIndex.value == index) {
        selectedCup.value = amount;
        selectedCupAsset.value = fillAsset;
      }
      saveCustomCups();
    }
  }

  void removeCustomCupAtIndex(int index, {required int cupIndex}) {
    if (selectedCupIndex.value == index) {
      // Cannot delete the currently active selected cup
      return;
    }
    // if (index > 6 && index < availableCups.length) {
    if (index > 6 && index < availableCups.length) {
      if (!customCupIndices.contains(cupIndex)) {
        // Double check in controller as well
        return;
      }
      int customListIndex = index - 7;
      if (customListIndex >= 0 && customListIndex < customCupAssetList.length) {
        customCupAssetList.removeAt(customListIndex);
        customCupFillAssetList.removeAt(customListIndex);
        customCupIndices.remove(cupIndex);
      }
      availableCups.removeAt(index);
      availableCupTypes.removeAt(index);

      // If the deleted cup was before the selected cup, we need to shift the selected index
      if (selectedCupIndex.value > index) {
        selectedCupIndex.value--;
      }
      saveCustomCups();
      update();
    }
  }

  bool isProcessingAnimation = false;
  var animationAmount = 0.obs;
  var animationTrigger = 0.obs;

  void triggerAnimation(int amount) {
    animationAmount.value = amount;
    animationTrigger.value++;
  }

  var isHomeLoading = false.obs;
  var isHistoryLoading = false.obs;
  late AudioPlayer _audioPlayer;

  var currentIntake = 0.obs;
  var targetIntake = 0.obs;
  var isMl = true.obs;
  var isKg = true.obs;
  var waterRecords = <WaterRecord>[].obs;
  var currentStreak = 0.obs;
  var longestStreak = 0.obs;
  String lastStreakDate = '';

  // Calendar & History
  var focusedDay = DateTime.now().obs;
  var selectedDay = DateTime.now().obs;
  var calendarFormat = Rx<CalendarFormat>(CalendarFormat.week);
  var allHistoryLogs = <WaterRecord>[].obs;
  var filteredHistoryLogs = <WaterRecord>[].obs;

  // Awards
  var isAwardsExpanded = false.obs;
  var unlockedAwards = <String>{}.obs;

  void checkAndUnlockAwards({bool showSheet = true}) {
    log(
      "Checking awards... longestStreak: ${longestStreak.value}, historyLogs: ${allHistoryLogs.length}, waterRecords: ${waterRecords.length}",
    );
    // 1. First Cup: User logs water for the first time
    if (allHistoryLogs.isNotEmpty || waterRecords.isNotEmpty) {
      unlockAward("first_cup", showSheet: showSheet);
    } else {
      lockAward("first_cup");
    }

    // 2. First Day: User completes their daily goal for the first time
    if (longestStreak.value >= 1) {
      unlockAward("first_day", showSheet: showSheet);
    } else {
      lockAward("first_day");
    }

    // 3. One Week: Streak == 7
    if (longestStreak.value >= 7) {
      unlockAward("one_week", showSheet: showSheet);
    } else {
      lockAward("one_week");
    }

    // 4. 30 Days: Streak == 30
    if (longestStreak.value >= 30) {
      unlockAward("thirty_days", showSheet: showSheet);
    } else {
      lockAward("thirty_days");
    }

    // 5. 100 Days: Streak == 100
    if (longestStreak.value >= 100) {
      unlockAward("hundred_days", showSheet: showSheet);
    } else {
      lockAward("hundred_days");
    }

    // 6. 365 Days: Streak == 365
    if (longestStreak.value >= 365) {
      unlockAward("three_sixty_five_days", showSheet: showSheet);
    } else {
      lockAward("three_sixty_five_days");
    }
  }

  void lockAward(String awardId) async {
    if (!unlockedAwards.contains(awardId)) return;

    unlockedAwards.remove(awardId);
    _celebratedAwards.remove(awardId);
    update();

    // Persist to Firestore
    try {
      String? uid = await FirebaseService().getUserId();
      if (uid != null) {
        await FirebaseService().firestore.collection('users').doc(uid).update({
          'awards': unlockedAwards.toList(),
          'celebratedAwards': _celebratedAwards.toList(),
        });
      }
    } catch (e) {
      log("Error relocking award: $e");
    }
  }

  final Set<String> _celebratedAwards = {};

  Future<void> unlockAward(String awardId, {bool showSheet = true}) async {
    bool isNew = !unlockedAwards.contains(awardId);
    log("Unlocking award $awardId... isNew: $isNew, showSheet: $showSheet, celebrated: ${_celebratedAwards.contains(awardId)}");

    if (isNew) {
      unlockedAwards.add(awardId);
      update();

      // Persist to Firestore
      try {
        String? uid = await FirebaseService().getUserId();
        if (uid != null) {
          await FirebaseService().firestore.collection('users').doc(uid).update({'awards': unlockedAwards.toList()});
        }
      } catch (e) {
        log("Error persisting award: $e");
      }
    }

    if (showSheet && (isNew || !_celebratedAwards.contains(awardId))) {
      _celebratedAwards.add(awardId);
      log("Showing sheet for award $awardId");

      // Persist celebrated status to Firestore
      try {
        String? uid = await FirebaseService().getUserId();
        if (uid != null) {
          await FirebaseService().firestore.collection('users').doc(uid).update({'celebratedAwards': _celebratedAwards.toList()});
        }
      } catch (e) {
        log("Error persisting celebrated award: $e");
      }

      showAwardSheet(awardId);
    }
  }

  void showAwardSheet(String id) {
    log("Displaying bottom sheet for award ID: $id");
    // Map ID to data
    String title = "";
    String desc = "";
    AssetGenImage? icon;

    switch (id) {
      case "first_cup":
        title = AppString.firstCup.tr;
        desc = AppString.firstCupDesc.tr;
        icon = Assets.images.png.firstAward;
        break;
      case "first_day":
        title = AppString.firstDay.tr;
        desc = AppString.firstDayDesc.tr;
        icon = Assets.images.png.secondAward;
        break;
      case "one_week":
        title = AppString.oneWeek.tr;
        desc = AppString.oneWeekDesc.tr;
        icon = Assets.images.png.thirdAwardPpng;
        break;
      case "thirty_days":
        title = AppString.thirtyDays.tr;
        desc = AppString.thirtyDaysDesc.tr;
        icon = Assets.images.png.fourAward;
        break;
      case "hundred_days":
        title = AppString.hundredDays.tr;
        desc = AppString.hundredDaysDesc.tr;
        icon = Assets.images.png.fiveAward;
        break;
      case "three_sixty_five_days":
        title = AppString.threeSixtyFiveDays.tr;
        desc = AppString.threeSixtyFiveDaysDesc.tr;
        icon = Assets.images.png.sixAward;
        break;
    }

    if (icon != null) {
      Get.bottomSheet(
        AwardBottomSheet(title: title, description: desc, icon: icon),
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
      );
    }
  }

  // To track daily goal met status for calendar
  var historyData = Rxn<HistoryData>();

  // Statistics
  var isStatsLoading = false.obs;
  var statsFocusedDay = DateTime.now().obs;
  var statisticsTabPeriod = 0.obs; // 0: Weekly, 1: Monthly, 2: Yearly
  var statsData = Rxn<StatsDataWrapper>();
  var drinkChartType = 0.obs; // 0: Bar, 1: Line
  var hydrateChartType = 0.obs; // 0: Bar, 1: Line
  var selectedDrinkChartIndex = (-1).obs;
  var selectedHydrateChartIndex = (-1).obs;
  var monthlyAverage = 0.0.obs;

  late TabController tabController;

  Future<void> refreshAllData() async {
    log("Refreshing HomeController data...");
    allHistoryLogs.clear();
    await _initPreferences();
    fetchStats();
    await fetchFullHistory();
    // We don't re-initialize TabController or AudioPlayer here to avoid ticker/memory leaks
  }

  @override
  void onInit() {
    super.onInit();
    _initPreferences();
    _audioPlayer = AudioPlayer();
    _initAudio();
    tabController = TabController(length: 2, vsync: this);

    // Initialize background sync for history and stats
    allRecordsStream.listen((data) {
      log("Global history stream updated: ${data.length} records");
    });

    // Removed todayRecordsStream listener to prevent Firestore cache from causing progress bar to bounce/crash to 0 during rapid additions or deletions.

    fetchStats();
  }

  void showDailyTip() {
    // Show tip if it's the first time in this session
    final dashboardController = Get.find<DashboardController>();
    if (dashboardController.isTipVisible.value) {
      Get.bottomSheet(
        DailyTipBottomSheet(
          title: AppString.drinkBeforeDinner.tr,
          description: AppString.drinkBeforeDinnerDesc.tr,
          onContinue: () {
            dashboardController.hideTip();
            Get.back();
          },
        ),
        isScrollControlled: true,
        isDismissible: false,
        enableDrag: false,
      );
    }
  }

  Future<void> _initPreferences() async {
    await _loadData();
    await loadCustomCups();

    // Final sync of selected cup after all data (including custom cups) is loaded
    if (selectedCupIndex.value < availableCups.length) {
      selectedCup.value = availableCups[selectedCupIndex.value];
      if (selectedCupIndex.value < selectedCupList.length) {
        selectedCupAsset.value = selectedCupList[selectedCupIndex.value];
      } else if (selectedCupIndex.value - 7 < customCupFillAssetList.length) {
        selectedCupAsset.value = customCupFillAssetList[selectedCupIndex.value - 7];
      }
    }
  }

  void onDaySelected(DateTime selected, DateTime focused) {
    selectedDay.value = selected;
    focusedDay.value = focused;
    _filterHistoryByDate(selected);
  }

  void _filterHistoryByDate(DateTime date) {
    String dateStr = DateFormat('yyyy-MM-dd').format(date);
    filteredHistoryLogs.assignAll(
      allHistoryLogs.where((record) {
        return DateFormat('yyyy-MM-dd').format(record.createdAt.toLocal()) == dateStr;
      }).toList(),
    );
  }

  Future<void> fetchFullHistory() async {
    isHistoryLoading.value = true;
    Map<String, DailyGoalStatus> dailyStatus = {};

    try {
      String? uid = await FirebaseService().getUserId();
      if (uid != null) {
        // 1. Get all daily summaries to calculate goal status for the calendar
        var dateSnapshots = await FirebaseService().firestore.collection('users').doc(uid).collection('water_records').get();

        for (var dateDoc in dateSnapshots.docs) {
          String dateKey = dateDoc.id;
          var dailyData = dateDoc.data();
          int current = dailyData['currentIntakeValue']?.toInt() ?? 0;
          int target = dailyData['targetIntakeValue']?.toInt() ?? targetIntake.value;
          if (target == 0) target = 0;
          dailyStatus[dateKey] = DailyGoalStatus(goalMet: current >= target);
        }

        // 2. Use collectionGroup to get ALL records at once (MUCH faster)
        var recordsSnapshot = await FirebaseService().firestore.collectionGroup('daily_records').where('userId', isEqualTo: uid).get();

        List<WaterRecord> allList = recordsSnapshot.docs.map((doc) => _convertRecordIfNeeded(WaterRecord.fromJson(doc.data()))).toList();

        allList.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        allHistoryLogs.assignAll(allList);
        historyData.value = HistoryData(data: dailyStatus);
        _filterHistoryByDate(selectedDay.value);
      }
    } catch (e) {
      log("Error fetching full history from Firestore: $e");
    }

    isHistoryLoading.value = false;
  }

  bool get canAddCustomCup => (availableCups.length - 7) < 2;

  void updateStatsMonth(int offset) {
    statsFocusedDay.value = DateTime(statsFocusedDay.value.year, statsFocusedDay.value.month + offset, 1);
    fetchStats();
  }

  void updateStatsYear(int offset) {
    statsFocusedDay.value = DateTime(statsFocusedDay.value.year + offset, statsFocusedDay.value.month, 1);
    fetchStats();
  }

  Future<void> fetchStats() async {
    isStatsLoading.value = true;
    String? uid = await FirebaseService().getUserId();
    if (uid == null) {
      isStatsLoading.value = false;
      return;
    }

    try {
      // Fetch all daily summaries to get intake/goal for each day
      var summariesSnapshot = await FirebaseService().firestore.collection('users').doc(uid).collection('water_records').get();

      List<ChartDatum> realData = [];
      for (var doc in summariesSnapshot.docs) {
        var data = doc.data();
        int current = data['currentIntakeValue']?.toInt() ?? 0;
        int target = data['targetIntakeValue']?.toInt() ?? targetIntake.value;
        if (target == 0) target = 0; // Fallback

        realData.add(
          ChartDatum(
            date: doc.id, // YYYY-MM-DD
            completionPct: target > 0 ? (current / target * 100) : 0,
            totalMl: current,
          ),
        );
      }

      statsData.value = StatsDataWrapper(
        data: StatsData(
          goal: targetIntake.value,
          currentStreak: currentStreak.value,
          longestStreak: longestStreak.value,
          chartData: realData,
        ),
      );
    } catch (e) {
      log("Error fetching stats: $e");
    }

    isStatsLoading.value = false;
    update();
  }

  Future<void> _initAudio() async {
    try {
      await _audioPlayer.setAsset('assets/audio/water.ogg');
    } catch (e) {
      debugPrint("Error loading water sound: $e");
    }
  }

  void playWaterSound() async {
    try {
      if (_audioPlayer.playing) {
        await _audioPlayer.stop();
      }
      await _audioPlayer.seek(Duration.zero);
      _audioPlayer.play();
    } catch (e) {
      debugPrint("Error playing water sound: $e");
    }
  }

  @override
  void onClose() {
    _audioPlayer.dispose();
    tabController.dispose();
    super.onClose();
  }

  Future<void> _loadData() async {
    isHomeLoading.value = true;
    String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    String? uid = await FirebaseService().getUserId();

    if (uid != null) {
      try {
        // 1. Get User Profile (including Streaks) from Firestore
        var userDoc = await FirebaseService().firestore.collection('users').doc(uid).get();
        if (userDoc.exists && userDoc.data() != null) {
          UserModel user = UserModel.fromMap(userDoc.data()!, userDoc.id);
          targetIntake.value = user.waterGoal > 0 ? user.waterGoal : 0;
          isMl.value = user.isMl;
          isKg.value = user.isKg;

          // If target is not set, look for the most recent target in history
          if (targetIntake.value == 0) {
            var historySnapshot = await FirebaseService().firestore
                .collection('users')
                .doc(uid)
                .collection('water_records')
                .orderBy(FieldPath.documentId, descending: true)
                .limit(5)
                .get();

            for (var doc in historySnapshot.docs) {
              if (doc.id != todayStr) {
                int lastTarget = doc.data()['targetIntakeValue']?.toInt() ?? 0;
                if (lastTarget > 0) {
                  targetIntake.value = lastTarget;
                  // Sync back to user profile for future use
                  await FirebaseService().firestore.collection('users').doc(uid).update({'waterGoal': lastTarget});
                  break;
                }
              }
            }
          }

          currentStreak.value = user.currentStreak;
          longestStreak.value = user.longestStreak;
          lastStreakDate = user.lastStreakDate;
          unlockedAwards.assignAll(user.awards);
          _celebratedAwards.addAll(user.celebratedAwards);

          await _checkAndResetStreak(uid);
        }

        // 2. Get Today's Daily Summary from Firestore
        var dailyDoc = await FirebaseService().firestore.collection('users').doc(uid).collection('water_records').doc(todayStr).get();
        if (dailyDoc.exists && dailyDoc.data() != null) {
          var data = dailyDoc.data()!;
          bool docIsMl = data['isMl'] ?? true;
          int docCurrent = data['currentIntakeValue']?.toInt() ?? 0;
          int docTarget = data['targetIntakeValue']?.toInt() ?? 0;

          if (docIsMl != isMl.value) {
            if (isMl.value) {
              currentIntake.value = (docCurrent * 29.5735).round();
              if (docTarget > 0) targetIntake.value = (docTarget * 29.5735).round();
            } else {
              currentIntake.value = (docCurrent / 29.5735).round();
              if (docTarget > 0) targetIntake.value = (docTarget / 29.5735).round();
            }
          } else {
            currentIntake.value = docCurrent;
            if (docTarget > 0) {
              targetIntake.value = docTarget;
            }
          }
        } else {
          currentIntake.value = 0;
          // Create today's summary doc with the recovered or global target
          await FirebaseService().firestore.collection('users').doc(uid).collection('water_records').doc(todayStr).set({
            'currentIntakeValue': 0,
            'targetIntakeValue': targetIntake.value,
          }, SetOptions(merge: true));
        }

        // 3. Load today's individual records for the list
        var snapshot = await FirebaseService().firestore
            .collection('users')
            .doc(uid)
            .collection('water_records')
            .doc(todayStr)
            .collection('daily_records')
            .get();

        List<WaterRecord> firestoreRecords = snapshot.docs.map((doc) => _convertRecordIfNeeded(WaterRecord.fromJson(doc.data()))).toList();
        waterRecords.assignAll(firestoreRecords);
        waterRecords.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        // Ensure currentIntake is in perfect sync with the loaded individual records
        int computedSum = firestoreRecords.fold(0, (sum, record) => sum + record.amount);
        if (currentIntake.value != computedSum) {
          currentIntake.value = computedSum;
          await FirebaseService().firestore.collection('users').doc(uid).collection('water_records').doc(todayStr).set({
            'currentIntakeValue': computedSum,
          }, SetOptions(merge: true));
        }
      } catch (e) {
        log("Error loading data from Firestore: $e");
      }
    }

    // Load selected cup index
    selectedCupIndex.value = await LocalStorage.getSelectedCupIndex();

    // Initialize default cups based on unit preference
    if (isMl.value) {
      availableCups.assignAll([100, 125, 150, 175, 200, 300, 1000]);
    } else {
      // Standard oz equivalents for common cup sizes
      availableCups.assignAll([3, 4, 5, 6, 7, 10, 34]);
    }

    availableCupTypes.assignAll([
      AppString.smallCup,
      AppString.cup,
      AppString.bigCup,
      AppString.glass,
      AppString.coffeeCup,
      AppString.mug,
      AppString.bottle,
    ]);

    if (selectedCupIndex.value < availableCups.length) {
      selectedCup.value = availableCups[selectedCupIndex.value];
    }
    customCupAssetList.clear();
    customCupFillAssetList.clear();
    customCupIndices.clear();
    if (!skipFeedback) {
      int openCount = await LocalStorage.getAppOpenCount();
      openCount++;
      await LocalStorage.setAppOpenCount(openCount);
      giveFeedback();
      String tStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      await LocalStorage.setLastOpenDate(tStr);
    }
    // Handle App Open Count for Feedback (Cumulative Sessions)

    // Removed automatic trigger from here as per 5th session rule
    skipFeedback = false; // Reset for next time

    isHomeLoading.value = false;
    await fetchStats();
    checkAndUnlockAwards(showSheet: false);
    update();
  }

  void showFeedbackPrompt({bool isRating = false}) {
    Get.dialog(const StarRatingDialog(), barrierColor: Colors.black.withOpacity(0.5), barrierDismissible: false);
  }

  giveFeedback() async {
    bool feedbackGiven = await LocalStorage.isFeedbackGiven();
    if (feedbackGiven) return;

    if (_feedbackPromptShownThisSession) return;

    int openCount = await LocalStorage.getAppOpenCount();
    int stage = await LocalStorage.getFeedbackStage();
    int lastPromptTimestamp = await LocalStorage.getLastFeedbackPromptTimestamp();
    DateTime now = DateTime.now();

    bool shouldShow = false;
    int nextStage = stage;

    // Stage 0: Initial (3rd open)
    if (stage == 0 && openCount >= 3) {
      shouldShow = true;
      nextStage = 1;
    }
    // Stage 1: 1st Follow-up (5 days after Stage 0 prompt)
    else if (stage == 1 && lastPromptTimestamp > 0) {
      DateTime lastPrompt = DateTime.fromMillisecondsSinceEpoch(lastPromptTimestamp);
      if (now.difference(lastPrompt).inDays >= 5) {
        shouldShow = true;
        nextStage = 2;
      }
    }
    // Stage 2: 2nd Follow-up (15 days after Stage 1 prompt)
    else if (stage == 2 && lastPromptTimestamp > 0) {
      DateTime lastPrompt = DateTime.fromMillisecondsSinceEpoch(lastPromptTimestamp);
      if (now.difference(lastPrompt).inDays >= 15) {
        shouldShow = true;
        nextStage = 3;
      }
    }
    // Stage 3: Final Follow-up (1 month after Stage 2 prompt)
    else if (stage == 3 && lastPromptTimestamp > 0) {
      DateTime lastPrompt = DateTime.fromMillisecondsSinceEpoch(lastPromptTimestamp);
      if (now.difference(lastPrompt).inDays >= 30) {
        shouldShow = true;
        nextStage = 4;
      }
    }

    if (shouldShow) {
      _feedbackPromptShownThisSession = true;
      showFeedbackPrompt(isRating: false);
      await LocalStorage.setFeedbackStage(nextStage);
      await LocalStorage.setLastFeedbackPromptTimestamp(now.millisecondsSinceEpoch);
    }
  }

  Future<void> markFeedbackGiven() async {
    await LocalStorage.setFeedbackGiven(true);
    await LocalStorage.setLastFeedbackTimestamp(DateTime.now().millisecondsSinceEpoch);
    final packageInfo = await PackageInfo.fromPlatform();
    await LocalStorage.setLastFeedbackVersion(packageInfo.version);
  }

  Future<bool> _checkFeedbackEligibility() async {
    bool feedbackGiven = await LocalStorage.isFeedbackGiven();
    if (feedbackGiven) {
      // Check if version has changed (Major Update Rule)
      final packageInfo = await PackageInfo.fromPlatform();
      String? lastVersion = await LocalStorage.getLastFeedbackVersion();
      if (lastVersion != null && lastVersion != packageInfo.version) {
        return true; // New version, allow prompt
      }

      // 60-Day Rule
      int lastTimestamp = await LocalStorage.getLastFeedbackTimestamp();
      int now = DateTime.now().millisecondsSinceEpoch;
      if (now - lastTimestamp < 5184000000) {
        // 60 days
        return false;
      }
    }
    return true;
  }

  Future<void> addWater(int amount, String type, {String? drinkType}) async {
    if (isProcessingAnimation) return;
    isProcessingAnimation = true;
    Future.delayed(const Duration(milliseconds: 1000), () {
      isProcessingAnimation = false;
    });

    triggerAnimation(amount);

    playWaterSound();
    AdService.showInterstitialAdIfReached();

    final now = DateTime.now();
    final recordId = now.millisecondsSinceEpoch.toString();

    // 1. Optimistically update local state immediately for smooth UI
    currentIntake.value += amount;

    String? uid = await FirebaseService().getUserId(); // Need this early but it's fast

    final record = WaterRecord(
      id: recordId,
      amount: amount,
      type: type,
      createdAt: now,
      currentIntakeAtTime: currentIntake.value,
      targetIntakeAtTime: targetIntake.value,
      userId: uid ?? '',
      isMl: isMl.value,
      drinkType: drinkType,
    );

    waterRecords.insert(0, record);
    allHistoryLogs.insert(0, record);

    // Update streak logic: Only increment if goal reached for the first time today
    String todayStr = DateFormat('yyyy-MM-dd').format(now);

    // Check if streak needs to be reset first (if they missed yesterday)
    await _checkAndResetStreak(uid);

    bool goalMetJustNow = false;
    if (currentIntake.value >= targetIntake.value && lastStreakDate != todayStr) {
      currentStreak.value++;
      if (currentStreak.value > longestStreak.value) {
        longestStreak.value = currentStreak.value;
      }
      lastStreakDate = todayStr;
      goalMetJustNow = true;
    }

    // Sync to Firestore
    try {
      if (uid != null) {
        String today = DateFormat('yyyy-MM-dd').format(now);
        final summaryRef = FirebaseService().firestore.collection('users').doc(uid).collection('water_records').doc(today);

        // 2. Add individual record to Firestore
        await summaryRef.collection('daily_records').doc(recordId).set(record.toJson());

        // 2. Update Daily Summary in Firestore LAST (this triggers the history stream)
        await summaryRef.set({
          'currentIntakeValue': currentIntake.value,
          'targetIntakeValue': targetIntake.value,
          'currentStreak': currentStreak.value,
          'longestStreak': longestStreak.value,
          'isMl': isMl.value,
        }, SetOptions(merge: true));

        // 3. Update User profile (always sync waterGoal, and update streaks if goal met)
        Map<String, dynamic> userUpdates = {'waterGoal': targetIntake.value};
        if (goalMetJustNow) {
          userUpdates.addAll({
            'currentStreak': currentStreak.value,
            'longestStreak': longestStreak.value,
            'lastStreakDate': lastStreakDate,
          });
        }
        await FirebaseService().firestore.collection('users').doc(uid).update(userUpdates);

        // 4. Refresh stats to show updated streak/charts
        fetchStats();

        // 5. Check for new awards (unlocked in background, shown in History)
        checkAndUnlockAwards(showSheet: false);
      }
    } catch (e) {
      log("Error saving record to Firestore: $e");
    }

    // await fetchFullHistory();
  }

  Future<void> _checkAndResetStreak(String? uid) async {
    if (uid == null || lastStreakDate.isEmpty) return;

    try {
      DateTime lastDate = DateTime.parse(lastStreakDate);
      DateTime today = DateTime.now();
      DateTime yesterday = today.subtract(const Duration(days: 1));

      String lastStr = DateFormat('yyyy-MM-dd').format(lastDate);
      String yesterdayStr = DateFormat('yyyy-MM-dd').format(yesterday);
      String tStr = DateFormat('yyyy-MM-dd').format(today);

      // If last streak was NOT today AND NOT yesterday, it means we missed a day
      if (lastStr != tStr && lastStr != yesterdayStr) {
        currentStreak.value = 0;
        lastStreakDate = '';
        await FirebaseService().firestore.collection('users').doc(uid).update({'currentStreak': 0, 'lastStreakDate': ''});
      }
    } catch (e) {
      log("Error checking streak reset: $e");
    }
  }

  Future<void> _syncCurrentIntakeToFirestore(int sum) async {
    try {
      String? uid = await FirebaseService().getUserId();
      if (uid != null) {
        String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
        await FirebaseService().firestore.collection('users').doc(uid).collection('water_records').doc(todayStr).set({
          'currentIntakeValue': sum,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      log("Error syncing current intake to Firestore: $e");
    }
  }

  Stream<UserModel?>? _userStream;
  Stream<UserModel?> get userStream {
    _userStream ??= _createUserStream().asBroadcastStream();
    return _userStream!;
  }

  Stream<UserModel?> _createUserStream() async* {
    String? uid = await FirebaseService().getUserId();
    if (uid == null) {
      yield null;
      return;
    }
    yield* FirebaseService().firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromMap(doc.data()!, doc.id) : null);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>>? _allSummariesStream;
  Stream<QuerySnapshot<Map<String, dynamic>>> get allSummariesStream {
    _allSummariesStream ??= _createAllSummariesStream().asBroadcastStream();
    return _allSummariesStream!;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _createAllSummariesStream() async* {
    String? uid = await FirebaseService().getUserId();
    if (uid == null) return;
    yield* FirebaseService().firestore.collection('users').doc(uid).collection('water_records').snapshots();
  }

  Stream<List<WaterRecord>>? _allRecordsStream;
  Stream<List<WaterRecord>> get allRecordsStream {
    _allRecordsStream ??= _createAllRecordsStream().asBroadcastStream();
    return _allRecordsStream!;
  }

  Stream<List<WaterRecord>> _createAllRecordsStream() async* {
    String? uid = await FirebaseService().getUserId();
    if (uid == null) {
      yield [];
      return;
    }

    // Listen to changes in the summaries collection
    // When any day's summary changes (new drink, deletion), we refresh the full history
    yield* FirebaseService().firestore.collection('users').doc(uid).collection('water_records').snapshots().asyncMap((snapshot) async {
      // This is reactive and doesn't require a collectionGroup index
      List<WaterRecord> all = [];
      for (var doc in snapshot.docs) {
        var recordsSnap = await doc.reference.collection('daily_records').get();
        for (var rDoc in recordsSnap.docs) {
          all.add(_convertRecordIfNeeded(WaterRecord.fromJson(rDoc.data())));
        }
      }
      all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      allHistoryLogs.assignAll(all);

      // Update historyData for calendar dots reactively
      Map<String, DailyGoalStatus> dailyStatus = {};
      for (var doc in snapshot.docs) {
        var data = doc.data();
        int current = data['currentIntakeValue']?.toInt() ?? 0;
        int target = data['targetIntakeValue']?.toInt() ?? 0;
        dailyStatus[doc.id] = DailyGoalStatus(goalMet: current >= target);
      }
      historyData.value = HistoryData(data: dailyStatus);

      // Update Statistics Data Reactively
      List<ChartDatum> realData = [];
      for (var doc in snapshot.docs) {
        var data = doc.data();
        int current = data['currentIntakeValue']?.toInt() ?? 0;
        int target = data['targetIntakeValue']?.toInt() ?? 0;
        realData.add(ChartDatum(date: doc.id, completionPct: target > 0 ? (current / target * 100) : 0, totalMl: current));
      }

      statsData.value = StatsDataWrapper(
        data: StatsData(
          goal: targetIntake.value,
          currentStreak: currentStreak.value,
          longestStreak: longestStreak.value,
          chartData: realData,
        ),
      );

      return all;
    });
  }

  Stream<List<WaterRecord>>? _recordsStream;
  Stream<List<WaterRecord>> get todayRecordsStream {
    _recordsStream ??= _createRecordsStream().asBroadcastStream();
    return _recordsStream!;
  }

  Stream<List<WaterRecord>> _createRecordsStream() async* {
    String? uid = await FirebaseService().getUserId();
    if (uid == null) {
      yield [];
      return;
    }
    String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    yield* FirebaseService().firestore
        .collection('users')
        .doc(uid)
        .collection('water_records')
        .doc(todayStr)
        .collection('daily_records')
        .snapshots()
        .map((snapshot) {
          final records = snapshot.docs.map((doc) => _convertRecordIfNeeded(WaterRecord.fromJson(doc.data()))).toList();
          records.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return records;
        });
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>>? _summaryStream;
  Stream<DocumentSnapshot<Map<String, dynamic>>> get todaySummaryStream {
    _summaryStream ??= _createSummaryStream().asBroadcastStream();
    return _summaryStream!;
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> _createSummaryStream() async* {
    String? uid = await FirebaseService().getUserId();
    if (uid == null) return;
    String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    yield* FirebaseService().firestore.collection('users').doc(uid).collection('water_records').doc(todayStr).snapshots();
  }

  Future<void> deleteRecord(WaterRecord record) async {
    if (isProcessingAnimation) return;
    isProcessingAnimation = true;
    Future.delayed(const Duration(milliseconds: 1000), () {
      isProcessingAnimation = false;
    });

    String dateStr = DateFormat('yyyy-MM-dd').format(record.createdAt);
    String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    try {
      String? uid = await FirebaseService().getUserId();
      if (uid != null) {
        int newIntake = 0;

        // Optimistically update local lists and calculate new intake immediately
        if (dateStr == todayStr) {
          waterRecords.removeWhere((r) => r.id == record.id);
          newIntake = waterRecords.fold(0, (sum, r) => sum + r.amount);
          currentIntake.value = newIntake;
        } else {
          allHistoryLogs.removeWhere((r) => r.id == record.id);
          newIntake = allHistoryLogs
              .where((r) => DateFormat('yyyy-MM-dd').format(r.createdAt.toLocal()) == dateStr)
              .fold(0, (sum, r) => sum + r.amount);
        }

        // 1. Delete individual record FIRST
        await FirebaseService().firestore
            .collection('users')
            .doc(uid)
            .collection('water_records')
            .doc(dateStr)
            .collection('daily_records')
            .doc(record.id)
            .delete();

        // Get current summary to retrieve targetIntake
        final summaryDoc = await FirebaseService().firestore.collection('users').doc(uid).collection('water_records').doc(dateStr).get();

        if (summaryDoc.exists) {
          final data = summaryDoc.data()!;
          int target = data['targetIntakeValue']?.toInt() ?? targetIntake.value;

          // 3. Check if streak should be reversed (only if it's today and we drop below goal)
          Map<String, dynamic> userUpdates = {'waterGoal': targetIntake.value};

          bool goalWasMet = false;
          if (dateStr == todayStr) {
            goalWasMet = lastStreakDate == todayStr;
          }

          if (dateStr == todayStr && goalWasMet && newIntake < target) {
            if (currentStreak.value > 0) {
              // If the streak we are losing was the record breaker, reverse it too
              if (currentStreak.value == longestStreak.value) {
                longestStreak.value--;
                if (longestStreak.value < 0) longestStreak.value = 0;
              }
              currentStreak.value--;
              lastStreakDate = currentStreak.value == 0
                  ? ''
                  : DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 1)));

              userUpdates.addAll({
                'currentStreak': currentStreak.value,
                'longestStreak': longestStreak.value,
                'lastStreakDate': lastStreakDate,
              });
            }
          }

          // Update user profile (always sync waterGoal)
          await FirebaseService().firestore.collection('users').doc(uid).update(userUpdates);

          // 4. Update Daily Summary LAST (this triggers the snapshots)
          if (dateStr == todayStr) {
            currentIntake.value = newIntake;
          }

          await summaryDoc.reference.set({
            'currentIntakeValue': newIntake,
            'targetIntakeValue': targetIntake.value,
            'currentStreak': currentStreak.value,
            'longestStreak': longestStreak.value,
          }, SetOptions(merge: true));

          // 5. Refresh stats to show updated streak/charts
          fetchStats();
          checkAndUnlockAwards(showSheet: false);
        }
      }
    } catch (e) {
      log("Error deleting record: $e");
    }
  }

  Future<void> _saveData() async {
    // Keep UI preferences in LocalStorage for better experience
    await LocalStorage.setSelectedCupIndex(selectedCupIndex.value);
  }

  Future<void> updateGoal(int newGoal) async {
    targetIntake.value = newGoal;

    try {
      String? uid = await FirebaseService().getUserId();
      if (uid != null) {
        String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

        // Update today's summary
        await FirebaseService().firestore.collection('users').doc(uid).collection('water_records').doc(today).set({
          'targetIntakeValue': newGoal,
        }, SetOptions(merge: true));

        // Also update user's global goal
        await FirebaseService().firestore.collection('users').doc(uid).update({'waterGoal': newGoal});
      }
    } catch (e) {
      log("Error updating goal in Firestore: $e");
    }

    await _saveData();
  }

  AssetGenImage getIconForType(String? type) {
    if (type == null) return Assets.images.png.cupFill1;

    // Handle custom cups with encoded icon index (e.g., "My Cup#7")
    if (type.contains('#')) {
      try {
        final parts = type.split('#');
        final iconIndex = int.parse(parts.last);
        if (iconIndex >= 0 && iconIndex < selectedCupList.length) {
          return selectedCupList[iconIndex];
        }
      } catch (e) {
        // Fallback to recognized names if parsing fails
      }
    }

    // Check if it's a legacy custom cup name mapping
    if (_customIconMap.containsKey(type)) {
      return _customIconMap[type]!;
    }

    switch (type.split('#').first) {
      case 'Small Cup':
      case 'Küçük Bardak':
      case AppString.smallCup:
        return Assets.images.png.cupFill1;
      case 'Cup':
      case 'Bardak':
      case AppString.cup:
        return Assets.images.png.cupFill2;
      case 'Big Cup':
      case 'Büyük Bardak':
      case AppString.bigCup:
        return Assets.images.png.cupFill3;
      case 'Glass':
      case 'Su Bardağı':
      case AppString.glass:
        return Assets.images.png.cupFill4;
      case 'Coffee Cup':
      case 'Kahve Fincanı':
      case AppString.coffeeCup:
        return Assets.images.png.cupFill5;
      case 'Mug':
      case 'Kupa':
      case AppString.mug:
        return Assets.images.png.cupFill6;
      case 'Bottle':
      case 'Şişe':
      case AppString.bottle:
        return Assets.images.png.cupFill8;
      case 'Jug':
      case 'Sürahi':
      case AppString.jug:
        return Assets.images.png.cupFill8;
      default:
        return Assets.images.png.cupFill1;
    }
  }

  AssetGenImage getCupAsset(int index) {
    if (index < 7) return cupDesignAssets[index];
    int customIdx = index - 7;
    if (customIdx < customCupAssetList.length) return customCupAssetList[customIdx];
    return Assets.images.png.a175mlGlass;
  }

  AssetGenImage getFillCupAsset(int index) {
    if (index < 7) return selectedCupList[index];
    int customIdx = index - 7;
    if (customIdx < customCupFillAssetList.length) return customCupFillAssetList[customIdx];
    return Assets.images.png.cupFill4;
  }

  Future<void> updateUnit(bool isMlUnit) async {
    if (isMl.value == isMlUnit) return;

    isMl.value = isMlUnit;

    // Convert Goal and Current Intake
    if (isMlUnit) {
      targetIntake.value = (targetIntake.value * 29.5735).round();
      currentIntake.value = (currentIntake.value * 29.5735).round();
    } else {
      targetIntake.value = (targetIntake.value / 29.5735).round();
      currentIntake.value = (currentIntake.value / 29.5735).round();
    }

    // Sync converted values for today to Firestore
    try {
      String? uid = await FirebaseService().getUserId();
      if (uid != null) {
        String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
        await FirebaseService().firestore.collection('users').doc(uid).collection('water_records').doc(today).set({
          'currentIntakeValue': currentIntake.value,
          'targetIntakeValue': targetIntake.value,
          'isMl': isMl.value,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      log("Error syncing converted units to Firestore: $e");
    }

    // Convert Default Cups
    if (isMlUnit) {
      availableCups.assignAll([100, 125, 150, 175, 200, 300, 1000]);
    } else {
      availableCups.assignAll([3, 4, 5, 6, 7, 10, 34]);
    }

    // Convert Custom Cups
    for (int i = 7; i < availableCups.length; i++) {
      if (isMlUnit) {
        availableCups[i] = (availableCups[i] * 29.5735).round();
      } else {
        availableCups[i] = (availableCups[i] / 29.5735).round();
      }
    }

    // Update selected cup value
    if (selectedCupIndex.value < availableCups.length) {
      selectedCup.value = availableCups[selectedCupIndex.value];
    }

    saveCustomCups();
    update();
  }

  WaterRecord _convertRecordIfNeeded(WaterRecord record) {
    if (record.isMl == isMl.value) return record;

    int newAmount;
    int? newCurrent;
    int? newTarget;

    if (isMl.value) {
      // oz -> ml
      newAmount = (record.amount * 29.5735).round();
      newCurrent = record.currentIntakeAtTime != null ? (record.currentIntakeAtTime! * 29.5735).round() : null;
      newTarget = record.targetIntakeAtTime != null ? (record.targetIntakeAtTime! * 29.5735).round() : null;
    } else {
      // ml -> oz
      newAmount = (record.amount / 29.5735).round();
      newCurrent = record.currentIntakeAtTime != null ? (record.currentIntakeAtTime! / 29.5735).round() : null;
      newTarget = record.targetIntakeAtTime != null ? (record.targetIntakeAtTime! / 29.5735).round() : null;
    }

    return WaterRecord(
      id: record.id,
      amount: newAmount,
      type: record.type,
      createdAt: record.createdAt,
      currentIntakeAtTime: newCurrent,
      targetIntakeAtTime: newTarget,
      userId: record.userId,
      isMl: isMl.value,
      drinkType: record.drinkType,
    );
  }

  StatsPeriod get period => StatsPeriod.values[statisticsTabPeriod.value];

  void setPeriod(StatsPeriod newPeriod) {
    statisticsTabPeriod.value = newPeriod.index;
    fetchStats();
  }
}

enum StatsPeriod { weekly, monthly, yearly }

enum ChartMode { bar, line }

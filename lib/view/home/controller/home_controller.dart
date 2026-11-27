import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
import 'package:water_intake/models/weekly_hydration_recap.dart';
import 'package:water_intake/theme/rewarded_theme.dart';
import 'package:water_intake/services/firebase_service.dart';
import 'package:water_intake/services/water_log_store.dart';
import 'package:water_intake/services/water_log_migration.dart';
import 'package:water_intake/services/widget_service.dart';
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
      Assets.images.png.plainWater.image(scale: 5.5 / 1.sp),
      Assets.images.png.mineralWater.image(scale: 5.5 / 1.sp),
      Assets.images.png.sportDrink.image(scale: 5.5 / 1.sp),
      Assets.images.png.enrgyDrink.image(scale: 5.5 / 1.sp),
      Assets.images.png.zeroSportDrink.image(scale: 5.5 / 1.sp),
      Assets.images.png.riceDrink.image(scale: 5.5 / 1.sp),
      Assets.images.png.barleyDrink.image(scale: 5.5 / 1.sp),
      Assets.images.png.sparklingWater.image(scale: 5.5 / 1.sp),
    ],
    AppString.categoryTea.tr: [
      Assets.images.png.tea.image(scale: 5.5 / 1.sp),
      Assets.images.png.milkTea.image(scale: 5.5 / 1.sp),
      Assets.images.png.blackTea.image(scale: 5.5 / 1.sp),
      Assets.images.png.greenTea.image(scale: 5.5 / 1.sp),
    ],
    AppString.categoryCoffee.tr: [Assets.images.png.cappacuinoCoffie.image(scale: 5.5 / 1.sp), Assets.images.png.mochaCoffee.image(scale: 5.5 / 1.sp)],
    AppString.categoryMilk.tr: [Assets.images.png.lowFatMilk.image(scale: 5.5 / 1.sp)],
    AppString.categoryJuice.tr: [
      Assets.images.png.orangeJuice.image(scale: 5.5 / 1.sp),
      Assets.images.png.lemonJuice.image(scale: 5.5 / 1.sp),
      Assets.images.png.pineappleJuice.image(scale: 5.5 / 1.sp),
      Assets.images.png.watermelonJuice.image(scale: 5.5 / 1.sp),
      Assets.images.png.peachJuice.image(scale: 5.5 / 1.sp),
      Assets.images.png.strawberryJuice.image(scale: 5.5 / 1.sp),
      Assets.images.png.coconutJuice.image(scale: 5.5 / 1.sp),
      Assets.images.png.appleJuice.image(scale: 5.5 / 1.sp),
      Assets.images.png.carrotJuice.image(scale: 5.5 / 1.sp),
    ],
    AppString.myDrink.tr: [Assets.images.png.cupFill1.image(scale: 5.5 / 1.sp)],
    AppString.categoryMore.tr: [Assets.images.png.more.image(scale: 3.3 / 1.sp)],
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
  bool _deferMilestoneUnlock = false;
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
  final weeklyRecap = WeeklyHydrationRecap.empty.obs;
  final _waterLog = WaterLogStore.instance;
  StreamSubscription<void>? _waterLogSubscription;

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
  var isStatsLoading = true.obs;
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
    await _initPreferences();
    // We don't re-initialize TabController or AudioPlayer here to avoid ticker/memory leaks
  }

  @override
  void onInit() {
    super.onInit();
    _initPreferences();
    _audioPlayer = AudioPlayer();
    _initAudio();
    tabController = TabController(length: 2, vsync: this);

    _waterLogSubscription = _waterLog.changes.listen((_) => fetchFullHistory());
    unawaited(WidgetService.sync());
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
    try {
      final days = await _waterLog.read();
      final today = WaterLogStore.dateKey(DateTime.now());
      final day = days[today];
      final records = day?.records ?? [];
      waterRecords.assignAll(records.map(_convertRecordIfNeeded).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
      currentIntake.value = day?.total(isMl.value) ?? 0;
      allHistoryLogs.assignAll(days.values.expand((day) => day.records).map(_convertRecordIfNeeded).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
      historyData.value = HistoryData(data: days.map((date, day) => MapEntry(date, DailyGoalStatus(goalMet: day.goalMet))));
      _filterHistoryByDate(selectedDay.value);
      _updateStats(days);
    } catch (error) {
      log('Error reading device water logs: $error');
    } finally {
      isStatsLoading.value = false;
      isHistoryLoading.value = false;
    }
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

  Future<void> fetchStats() => fetchFullHistory();

  void _updateStats(Map<String, WaterLogDay> days) {
    final completedDates = days.keys.where((date) => days[date]!.goalMet).toList()..sort();
    DateTime? previous;
    int streak = 0;
    int longest = 0;
    for (final date in completedDates) {
      final day = DateTime.parse(date);
      final yesterday = DateTime(day.year, day.month, day.day - 1);
      streak = previous == yesterday ? streak + 1 : 1;
      if (streak > longest) longest = streak;
      previous = day;
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    currentStreak.value = previous == today || previous == yesterday ? streak : 0;
    longestStreak.value = longest;
    weeklyRecap.value = WeeklyHydrationRecap.fromDays(days, today);
    if (!_deferMilestoneUnlock) _recordMilestoneTheme();

    statsData.value = StatsDataWrapper(data: StatsData(
      goal: targetIntake.value,
      currentStreak: currentStreak.value,
      longestStreak: longestStreak.value,
      chartData: days.entries.map((entry) {
        final day = entry.value;
        return ChartDatum(
          date: entry.key,
          completionPct: day.goal > 0 ? day.total(day.isMl) / day.goal * 100 : 0,
          totalMl: day.total(isMl.value),
        );
      }).toList(),
    ));
  }

  void _recordMilestoneTheme() {
    unawaited(MilestoneTheme.instance.recordStreak(longestStreak.value).catchError((Object error) {
      log('Error saving milestone theme: $error');
    }));
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
        await _audioPlayer.pause();
      }
      await _audioPlayer.seek(Duration.zero);
      _audioPlayer.play();
    } catch (e) {
      debugPrint("Error playing water sound: $e");
    }
  }

  @override
  void onClose() {
    _waterLogSubscription?.cancel();
    _audioPlayer.dispose();
    tabController.dispose();
    super.onClose();
  }

  Future<void> _loadData() async {
    isHomeLoading.value = true;
    final uid = await FirebaseService().getUserId();
    final today = WaterLogStore.dateKey(DateTime.now());
    final days = await _waterLog.read();
    final dates = days.keys.where((date) => date.compareTo(today) <= 0 && days[date]!.goal > 0).toList()..sort();
    final savedDay = dates.isEmpty ? null : days[dates.last];
    if (savedDay != null) {
      targetIntake.value = savedDay.goal;
      isMl.value = savedDay.isMl;
    }
    await fetchFullHistory();

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
    if (uid != null) unawaited(_loadProfileAndImport(uid));
    await fetchStats();
    checkAndUnlockAwards(showSheet: false);
    update();
  }

  Future<void> _loadProfileAndImport(String uid) async {
    try {
      final userDoc = await FirebaseService().firestore.collection('users').doc(uid).get();
      if (isClosed) return;
      final data = userDoc.data();
      if (data != null) {
        final user = UserModel.fromMap(data, userDoc.id);
        isKg.value = user.isKg;
        unlockedAwards.assignAll(user.awards);
        _celebratedAwards.addAll(user.celebratedAwards);
        if (targetIntake.value == 0 && user.waterGoal > 0) {
          await _waterLog.seedGoal(user.waterGoal, user.isMl);
          await _refreshStoredGoal();
        }
      }
    } catch (error) {
      log('Error loading profile: $error');
    }

    try {
      await importLegacyWaterLogs(uid);
      await _refreshStoredGoal();
    } catch (error) {
      log('Error importing legacy logs: $error');
    }
  }

  Future<void> _refreshStoredGoal() async {
    final days = await _waterLog.read();
    if (isClosed) return;
    final today = WaterLogStore.dateKey(DateTime.now());
    final dates = days.keys.where((date) => date.compareTo(today) <= 0 && days[date]!.goal > 0).toList()..sort();
    if (dates.isNotEmpty) {
      final day = days[dates.last]!;
      if (isMl.value != day.isMl) _applyDisplayUnit(day.isMl);
      targetIntake.value = day.goal;
    }
    await fetchFullHistory();
  }

  void showFeedbackPrompt({bool isRating = false}) {
    Get.dialog(const StarRatingDialog(), barrierColor: Colors.black.withValues(alpha: 0.5), barrierDismissible: false);
  }

  Future<void> giveFeedback() async {
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


  Future<void> addWater(int amount, String type, {String? drinkType, String? confirmation}) async {
    if (amount <= 0 || isProcessingAnimation) return;
    isProcessingAnimation = true;
    Future.delayed(const Duration(milliseconds: 1000), () {
      isProcessingAnimation = false;
    });

    final now = DateTime.now();
    final date = WaterLogStore.dateKey(now);
    final id = now.microsecondsSinceEpoch.toString();
    _deferMilestoneUnlock = true;
    try {
      final wasComplete = (await _waterLog.read())[date]?.goalMet ?? false;
      await _waterLog.add(now, amount, type, goal: targetIntake.value, isMl: isMl.value, drinkType: drinkType, recordId: id);
      await fetchFullHistory();
      triggerAnimation(amount);
      final completedGoal = !wasComplete && targetIntake.value > 0 && currentIntake.value >= targetIntake.value;
      unawaited(AdService.onWaterLogged(completedGoal: completedGoal));
      if (completedGoal) {
        final choice = await showGoalCompletionDialog(confirmation: confirmation);
        if (isClosed) return;
        if (choice == false) {
          await undoWaterLog(now, id);
          return;
        }
        if (choice == true) unawaited(AdService.showInterstitialAtBreak());
      } else {
        playWaterSound();
        final context = Get.context;
        final messenger = context != null && context.mounted ? ScaffoldMessenger.maybeOf(context) : null;
        messenger?.hideCurrentSnackBar();
        messenger?.showSnackBar(SnackBar(
          content: Text(confirmation ?? AppString.waterLogged.tr),
          action: SnackBarAction(label: AppString.undoWaterLog.tr, onPressed: () => undoWaterLog(now, id)),
        ));
      }
      checkAndUnlockAwards(showSheet: false);
    } catch (error) {
      log('Error saving water log: $error');
    } finally {
      _deferMilestoneUnlock = false;
      if (!isClosed) _recordMilestoneTheme();
    }
  }

  Future<void> undoWaterLog(DateTime date, String id) async {
    try {
      await _waterLog.deleteById(date, id);
      await fetchFullHistory();
      checkAndUnlockAwards(showSheet: false);
    } catch (error) {
      log('Error undoing water log: $error');
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

  Future<void> deleteRecord(WaterRecord record) async {
    if (isProcessingAnimation) return;
    isProcessingAnimation = true;
    try {
      await _waterLog.delete(record);
      await fetchFullHistory();
      checkAndUnlockAwards(showSheet: false);
    } catch (error) {
      log('Error deleting water log: $error');
    } finally {
      isProcessingAnimation = false;
    }
  }

  Future<void> updateGoal(int newGoal) async {
    await _waterLog.setGoal(newGoal, isMl.value);
    targetIntake.value = newGoal;
    await fetchFullHistory();
    final uid = await FirebaseService().getUserId();
    if (uid != null) {
      try {
        await FirebaseService().firestore.collection('users').doc(uid).update({'waterGoal': newGoal});
      } catch (error) {
        log('Error syncing profile goal: $error');
      }
    }
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
        return Assets.images.png.cupFill1;
      case 'Cup':
      case 'Bardak':
        return Assets.images.png.cupFill2;
      case 'Big Cup':
      case 'Büyük Bardak':
        return Assets.images.png.cupFill3;
      case 'Glass':
      case 'Su Bardağı':
        return Assets.images.png.cupFill4;
      case 'Coffee Cup':
      case 'Kahve Fincanı':
        return Assets.images.png.cupFill5;
      case 'Mug':
      case 'Kupa':
        return Assets.images.png.cupFill6;
      case 'Bottle':
      case 'Şişe':
        return Assets.images.png.cupFill8;
      case 'Jug':
      case 'Sürahi':
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
    final goal = (isMlUnit ? targetIntake.value * 29.5735 : targetIntake.value / 29.5735).round();
    await _waterLog.setGoal(goal, isMlUnit);
    _applyDisplayUnit(isMlUnit);
    targetIntake.value = goal;
    await fetchFullHistory();
  }

  void _applyDisplayUnit(bool isMlUnit) {
    isMl.value = isMlUnit;
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

  Future<bool?> showGoalCompletionDialog({String? confirmation}) async {
    playWaterSound();

    final (title, description, image) = switch (currentStreak.value) {
      7 => (AppString.oneWeek.tr, AppString.oneWeekDesc.tr, Assets.images.png.thirdAwardPpng),
      30 => (AppString.thirtyDays.tr, AppString.thirtyDaysDesc.tr, Assets.images.png.fourAward),
      100 => (AppString.hundredDays.tr, AppString.hundredDaysDesc.tr, Assets.images.png.fiveAward),
      365 => (AppString.threeSixtyFiveDays.tr, AppString.threeSixtyFiveDaysDesc.tr, Assets.images.png.sixAward),
      _ => ('Goal Completed!', 'Great job! You reached your daily hydration goal.', Assets.images.png.firstAward),
    };

    return Get.dialog<bool>(
      TweenAnimationBuilder(
        duration: const Duration(milliseconds: 800),
        tween: Tween<double>(begin: 0.0, end: 1.0),
        curve: Curves.elasticOut,
        builder: (context, double scale, child) {
          return Transform.scale(
            scale: scale,
            child: AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  image.image(width: 120.w, height: 120.h),
                  SizedBox(height: 16.h),
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Inter Tight',
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF006666),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter Tight',
                      fontSize: 14.sp,
                      color: Colors.black54,
                    ),
                  ),
                  if (confirmation != null) ...[SizedBox(height: 8.h), Text(confirmation, textAlign: TextAlign.center)],
                  SizedBox(height: 20.h),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF006666),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                    onPressed: () => Get.back(result: true),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                      child: Text(
                        'Awesome',
                        style: TextStyle(
                          fontFamily: 'Inter Tight',
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Get.back(result: false),
                    child: Text(AppString.undoWaterLog.tr),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      barrierDismissible: false,
    );
  }
}

enum StatsPeriod { weekly, monthly, yearly }

enum ChartMode { bar, line }

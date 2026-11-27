import 'dart:async';

import 'package:water_intake/services/notification_service.dart';
import 'package:water_intake/services/reminder_store.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageItemData {
  final String code;
  final String displayName;
  final String flag;

  LanguageItemData({required this.code, required this.displayName, required this.flag});
}

class AccountController extends GetxController {
  var isNotificationEnabled = true.obs;
  StreamSubscription<void>? _reminderSubscription;
  var selectedLanguage = 'Turkish'.obs;
  var selectedPlan = 2.obs; // Premium screen selected plan

  var searchQuery = ''.obs;
  final searchController = TextEditingController();

  final List<LanguageItemData> allLanguages = [
    LanguageItemData(code: 'English (United States)', displayName: 'English (United States)', flag: '🇺🇸'),
    LanguageItemData(code: 'Türkçe', displayName: 'Türkçe', flag: '🇹🇷'),
    LanguageItemData(code: 'Español', displayName: 'Español', flag: '🇪🇸'),
    LanguageItemData(code: 'Deutsch', displayName: 'Deutsch', flag: '🇩🇪'),
    LanguageItemData(code: 'Français', displayName: 'Français', flag: '🇫🇷'),
    LanguageItemData(code: 'हिन्दी', displayName: 'हिन्दी', flag: '🇮🇳'),
    LanguageItemData(code: 'فارسی', displayName: 'فارسی', flag: '🇮🇷'),
    LanguageItemData(code: 'العربية', displayName: 'العربية', flag: '🇸🇦'),
    LanguageItemData(code: 'اردو', displayName: 'اردو', flag: '🇵🇰'),
  ];

  List<LanguageItemData> get filteredLanguages {
    if (searchQuery.value.isEmpty) {
      return allLanguages;
    }
    return allLanguages.where((lang) => lang.displayName.toLowerCase().contains(searchQuery.value.toLowerCase())).toList();
  }

  void filterLanguages(String query) {
    searchQuery.value = query;
  }

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
  }

  @override
  void onInit() {
    super.onInit();
    _reminderSubscription = ReminderStore.instance.changes.listen((_) => _loadReminderSetting());
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedLang = prefs.getString('selected_language');

    if (savedLang == null) {
      final deviceLocale = Get.deviceLocale;
      if (deviceLocale?.languageCode == 'tr') {
        selectedLanguage.value = 'Türkçe';
      } else if (deviceLocale?.languageCode == 'es') {
        selectedLanguage.value = 'Español';
      } else if (deviceLocale?.languageCode == 'de') {
        selectedLanguage.value = 'Deutsch';
      } else if (deviceLocale?.languageCode == 'fr') {
        selectedLanguage.value = 'Français';
      } else if (deviceLocale?.languageCode == 'hi') {
        selectedLanguage.value = 'हिन्दी';
      } else if (deviceLocale?.languageCode == 'fa') {
        selectedLanguage.value = 'فارسی';
      } else if (deviceLocale?.languageCode == 'ar') {
        selectedLanguage.value = 'العربية';
      } else if (deviceLocale?.languageCode == 'ur') {
        selectedLanguage.value = 'اردو';
      } else {
        selectedLanguage.value = 'English (United States)';
      }
    } else {
      if (savedLang == 'English') {
        selectedLanguage.value = 'English (United States)';
      } else if (savedLang == 'Turkish') {
        selectedLanguage.value = 'Türkçe';
      } else if (savedLang == 'Spanish') {
        selectedLanguage.value = 'Español';
      } else if (savedLang == 'German') {
        selectedLanguage.value = 'Deutsch';
      } else {
        selectedLanguage.value = savedLang;
      }
    }

    await _loadReminderSetting();
  }

  Future<void> _loadReminderSetting() async {
    final enabled = await ReminderStore.instance.isEnabled();
    if (!isClosed) isNotificationEnabled.value = enabled;
  }

  Future<void> toggleNotifications(bool value) => ReminderStore.instance.setEnabled(value);

  Future<void> changeLanguage(String language) async {
    selectedLanguage.value = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_language', language);
    await NotificationService().refreshReminderSchedule();

    if (language == 'Turkish' || language == 'Türkçe') {
      Get.updateLocale(const Locale('tr', 'TR'));
    } else if (language == 'Spanish' || language == 'Español') {
      Get.updateLocale(const Locale('es', 'ES'));
    } else if (language == 'German' || language == 'Deutsch') {
      Get.updateLocale(const Locale('de', 'DE'));
    } else if (language == 'French' || language == 'Français') {
      Get.updateLocale(const Locale('fr', 'FR'));
    } else if (language == 'Hindi' || language == 'हिन्दी') {
      Get.updateLocale(const Locale('hi', 'IN'));
    } else if (language == 'Persian' || language == 'فارسی') {
      Get.updateLocale(const Locale('fa', 'IR'));
    } else if (language == 'Arabic' || language == 'العربية') {
      Get.updateLocale(const Locale('ar', 'SA'));
    } else if (language == 'Urdu' || language == 'اردو') {
      Get.updateLocale(const Locale('ur', 'PK'));
    } else {
      Get.updateLocale(const Locale('en', 'US'));
    }
  }

  void setPlan(int index) {
    selectedPlan.value = index;
  }

  @override
  void onClose() {
    _reminderSubscription?.cancel();
    searchController.dispose();
    super.onClose();
  }
}

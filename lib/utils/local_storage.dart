import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static final LocalStorage _instance = LocalStorage._internal();
  factory LocalStorage() => _instance;
  LocalStorage._internal();

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static SharedPreferences get _getPrefs {
    if (_prefs == null) {
      throw Exception('LocalStorage not initialized. Call LocalStorage.init() in main.dart');
    }
    return _prefs!;
  }

  static const String _isSetupCompleteKey = 'isSetupComplete';
  static const String _lastFeedbackPromptTimestampKey = 'lastFeedbackPromptTimestamp';

  static const String _lastLogDateKey = 'lastLogDate';
  static const String _customCupsKey = 'customCups';
  static const String _customTypesKey = 'customTypes';
  static const String _appOpenCountKey = 'appOpenCount';
  static const String _lastOpenDateKey = 'lastOpenDate';
  static const String _feedbackGivenKey = 'feedbackGiven';
  static const String _lastFeedbackTimestampKey = 'lastFeedbackTimestamp';
  static const String _lastFeedbackVersionKey = 'lastFeedbackVersion';
  static const String _selectedCupIndexKey = 'selectedCupIndex';
  static const String _timeFormatKey = 'timeFormat';
  static const String _feedbackStageKey = 'feedbackStage';

  static const String _climateKey = 'climate';
  static const String _userIdKey = 'userId';
  static const String _favoriteDrinksKey = 'favoriteDrinks';

  static Future<void> setSetupComplete(bool value) async {
    await _getPrefs.setBool(_isSetupCompleteKey, value);
  }

  static Future<List<String>> loadFavoriteDrinks() async {
    return _getPrefs.getStringList(_favoriteDrinksKey) ?? [];
  }

  static Future<void> saveFavoriteDrinks(List<String> drinks) async {
    await _getPrefs.setStringList(_favoriteDrinksKey, drinks);
  }

  static Future<bool> isSetupComplete() async {
    return _getPrefs.getBool(_isSetupCompleteKey) ?? false;
  }

  static const String _customDrinksListKey = 'customDrinksListKey';

  static Future<void> saveCustomDrinks(List<String> drinks) async {
    await _getPrefs.setStringList(_customDrinksListKey, drinks);
  }

  static Future<List<String>> loadCustomDrinks() async {
    return _getPrefs.getStringList(_customDrinksListKey) ?? [];
  }

  static const String _drinkAmountsKey = 'drinkAmounts';

  static Future<void> saveDrinkAmounts(Map<String, int> amounts) async {
    final Map<String, String> stringMap = amounts.map((k, v) => MapEntry(k, v.toString()));
    await _getPrefs.setString(_drinkAmountsKey, stringMap.keys.map((k) => '$k:${stringMap[k]}').join(','));
  }

  static Future<void> saveCustomCups(List<int> amounts, List<String> types) async {
    if (amounts.length > 7) {
      await _getPrefs.setStringList(_customCupsKey, amounts.sublist(7).map((e) => e.toString()).toList());
      await _getPrefs.setStringList(_customTypesKey, types.sublist(7));
    } else {
      await _getPrefs.remove(_customCupsKey);
      await _getPrefs.remove(_customTypesKey);
    }
  }

  static Future<int> getFeedbackStage() async {
    return _getPrefs.getInt(_feedbackStageKey) ?? 0;
  }

  static Future<Map<String, List<String>?>> loadCustomCups() async {
    return {'amounts': _getPrefs.getStringList(_customCupsKey), 'types': _getPrefs.getStringList(_customTypesKey)};
  }

  static Future<void> saveRecords(String date, List<String> recordsJson) async {
    await _getPrefs.setStringList('records_$date', recordsJson);
  }

  static Future<List<String>?> loadRecords(String date) async {
    return _getPrefs.getStringList('records_$date');
  }

  static Future<int> getAppOpenCount() async {
    return _getPrefs.getInt(_appOpenCountKey) ?? 0;
  }

  static Future<void> setAppOpenCount(int count) async {
    await _getPrefs.setInt(_appOpenCountKey, count);
  }

  static Future<String?> getLastOpenDate() async {
    return _getPrefs.getString(_lastOpenDateKey);
  }

  static Future<void> setLastOpenDate(String date) async {
    await _getPrefs.setString(_lastOpenDateKey, date);
  }

  static Future<bool> isFeedbackGiven() async {
    return _getPrefs.getBool(_feedbackGivenKey) ?? false;
  }

  static Future<void> setFeedbackGiven(bool value) async {
    await _getPrefs.setBool(_feedbackGivenKey, value);
  }

  static Future<int> getLastFeedbackTimestamp() async {
    return _getPrefs.getInt(_lastFeedbackTimestampKey) ?? 0;
  }

  static Future<void> setLastFeedbackTimestamp(int timestamp) async {
    await _getPrefs.setInt(_lastFeedbackTimestampKey, timestamp);
  }

  static Future<String?> getLastFeedbackVersion() async {
    return _getPrefs.getString(_lastFeedbackVersionKey);
  }

  static Future<void> setLastFeedbackVersion(String version) async {
    await _getPrefs.setString(_lastFeedbackVersionKey, version);
  }

  static const String _weightUnitKey = 'weightUnit';
  static const String _intakeUnitKey = 'intakeUnit';
  static const String _soundEnabledKey = 'soundEnabled';
  static const String _vibrationEnabledKey = 'vibrationEnabled';

  static Future<void> setSelectedCupIndex(int index) async {
    await _getPrefs.setInt(_selectedCupIndexKey, index);
  }

  static Future<void> setLastFeedbackPromptTimestamp(int timestamp) async {
    await _getPrefs.setInt(_lastFeedbackPromptTimestampKey, timestamp);
  }

  static Future<int> getSelectedCupIndex() async {
    return _getPrefs.getInt(_selectedCupIndexKey) ?? 3;
  }

  static Future<void> setWeightUnit(String unit) async {
    await _getPrefs.setString(_weightUnitKey, unit);
  }

  static Future<void> setFeedbackStage(int stage) async {
    await _getPrefs.setInt(_feedbackStageKey, stage);
  }

  static Future<String> getWeightUnit() async {
    return _getPrefs.getString(_weightUnitKey) ?? 'kg';
  }

  static Future<int> getLastFeedbackPromptTimestamp() async {
    return _getPrefs.getInt(_lastFeedbackPromptTimestampKey) ?? 0;
  }

  static Future<void> setIntakeUnit(String unit) async {
    await _getPrefs.setString(_intakeUnitKey, unit);
  }

  static Future<String> getIntakeUnit() async {
    return _getPrefs.getString(_intakeUnitKey) ?? 'ml';
  }

  static Future<void> setSoundEnabled(bool value) async {
    await _getPrefs.setBool(_soundEnabledKey, value);
  }

  static Future<bool> isSoundEnabled() async {
    return _getPrefs.getBool(_soundEnabledKey) ?? true;
  }

  static Future<void> setVibrationEnabled(bool value) async {
    await _getPrefs.setBool(_vibrationEnabledKey, value);
  }

  static Future<bool> isVibrationEnabled() async {
    return _getPrefs.getBool(_vibrationEnabledKey) ?? true;
  }

  static Future<void> setTimeFormat(String format) async {
    await _getPrefs.setString(_timeFormatKey, format);
  }

  static Future<String> getTimeFormat() async {
    return _getPrefs.getString(_timeFormatKey) ?? '12-hour';
  }

  static Future<void> setClimate(String climate) async {
    await _getPrefs.setString(_climateKey, climate);
  }

  static Future<String> getClimate() async {
    return _getPrefs.getString(_climateKey) ?? 'Temperate';
  }

  static Future<String?> getUserId() async {
    return _getPrefs.getString(_userIdKey);
  }

  static Future<void> setUserId(String userId) async {
    await _getPrefs.setString(_userIdKey, userId);
  }
}

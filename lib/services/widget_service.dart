import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

/// Pushes today's hydration progress to the home-screen widgets
/// (iOS WidgetKit extension `WaterWidget`, Android `WaterWidgetProvider`).
class WidgetService {
  WidgetService._();

  /// Must match the App Group of the Runner app and the widget extension.
  static const String appGroupId = 'group.com.sarang.reminder';
  static const String _iosWidgetName = 'WaterWidget';
  static const String _androidWidgetName = 'WaterWidgetProvider';

  static Future<void> init() async {
    try {
      await HomeWidget.setAppGroupId(appGroupId);
    } catch (e) {
      debugPrint('WidgetService init failed: $e');
    }
  }

  /// Writes the current state and asks the OS to re-render the widget.
  static Future<void> updateProgress({
    required int current,
    required int goal,
    required bool isMl,
  }) async {
    try {
      final String unit = isMl ? 'ml' : 'oz';
      final int pct = goal > 0 ? ((current / goal) * 100).clamp(0, 100).round() : 0;
      await HomeWidget.saveWidgetData<String>('amount_text', '$current / $goal $unit');
      await HomeWidget.saveWidgetData<int>('progress_pct', pct);
      await HomeWidget.updateWidget(
        iOSName: _iosWidgetName,
        androidName: _androidWidgetName,
      );
    } catch (e) {
      debugPrint('WidgetService update failed: $e');
    }
  }
}

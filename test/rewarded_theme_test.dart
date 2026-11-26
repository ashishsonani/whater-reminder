import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:water_intake/theme/rewarded_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const key = 'oceanDuskThemeUnlockedUntil';

  test(
    'a theme reward lasts 24 hours and is restored after reopening',
    () async {
      SharedPreferences.setMockInitialValues({});
      final reward = ThemeReward();
      final reopened = ThemeReward();
      addTearDown(reward.dispose);
      addTearDown(reopened.dispose);

      final now = DateTime.now();
      await reward.grant();
      expect(reward.value!.difference(now).inMinutes, 24 * 60);

      await reopened.restore();
      expect(
        reopened.value!.millisecondsSinceEpoch,
        reward.value!.millisecondsSinceEpoch,
      );
    },
  );

  test('an expired reward is ignored on startup', () async {
    SharedPreferences.setMockInitialValues({
      key: DateTime.now()
          .subtract(const Duration(minutes: 1))
          .millisecondsSinceEpoch,
    });
    final reward = ThemeReward();
    addTearDown(reward.dispose);

    await reward.restore();
    expect(reward.value, isNull);
  });
}

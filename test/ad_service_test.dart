import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:water_intake/services/ad_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'the interstitial opportunity repeats every five successful logs',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      const counterKey = 'waterLogsSinceAdOpportunity';

      for (var count = 1; count < 5; count++) {
        await AdService.onWaterLogged(completedGoal: false);
        expect(prefs.getInt(counterKey), count);
      }

      await AdService.onWaterLogged(completedGoal: true);
      expect(prefs.getInt(counterKey), 0);

      await AdService.onWaterLogged(completedGoal: false);
      expect(prefs.getInt(counterKey), 1);
    },
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:water_intake/utils/app_strings.dart';
import 'package:water_intake/services/iap_service.dart';
import 'package:water_intake/view/account/screen/premium_screen.dart';

void main() {
  testWidgets(
    'debug paywall lists all durations when store prices are unavailable',
    (tester) async {
      expect(IAPService.enabled, isTrue);

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, _) => const MaterialApp(home: PremiumScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppString.upgradeToPremium), findsOneWidget);
      expect(find.text('1 month'), findsOneWidget);
      expect(find.text('3 months'), findsOneWidget);
      expect(find.text('6 months'), findsOneWidget);
      final checkout = tester.widget<ElevatedButton>(
        find.byKey(const Key('premium-checkout')),
      );
      expect(checkout.onPressed, isNull);
    },
  );
}

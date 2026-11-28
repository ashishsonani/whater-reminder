import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../route/route.dart' show AppRoutes;
import '../../../services/ad_service.dart';
import '../../../utils/local_storage.dart';
import '../../../services/notification_service.dart';

class SplashController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    _navigateToNext();
  }

  void _navigateToNext() async {
    await WidgetsBinding.instance.endOfFrame;
    final minimumSplashTime = Future<void>.delayed(const Duration(seconds: 3));
    await AdService.fetchRemoteConfig();
    await AdService.gatherConsentAndInit();
    await NotificationService().requestPermissions();
    if (AdService.canLoadAppOpen) {
      await AdService.appOpenAdManager.showAdIfAvailable(
        timeout: const Duration(seconds: 4),
      );
    }
    await minimumSplashTime;
    if (isClosed) return;

    bool isSetupComplete = await LocalStorage.isSetupComplete();
    if (isSetupComplete) {
      Get.offAllNamed(AppRoutes.dashboard);
    } else {
      Get.offAllNamed(AppRoutes.onboarding);
    }
  }
}

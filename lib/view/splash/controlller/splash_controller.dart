import 'package:get/get.dart';

import '../../../route/route.dart' show AppRoutes;
import '../../../services/ad_service.dart';
import '../../../utils/local_storage.dart';

class SplashController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    _navigateToNext();
  }

  void _navigateToNext() async {
    // Fetch remote ads config in parallel with the delay
    await Future.wait([
      Future.delayed(const Duration(seconds: 3)),
      AdService.fetchRemoteConfig(),
    ]);

    // Show App Open Ad on startup if available
    AdService.appOpenAdManager.showAdIfAvailable();

    bool isSetupComplete = await LocalStorage.isSetupComplete();
    if (isSetupComplete) {
      Get.offAllNamed(AppRoutes.dashboard);
    } else {
      Get.offAllNamed(AppRoutes.onboarding);
    }
  }
}

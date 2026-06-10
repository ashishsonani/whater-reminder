import 'package:get/get.dart';

import '../../../route/route.dart' show AppRoutes;
import '../../../utils/local_storage.dart';

class SplashController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    _navigateToNext();
  }

  void _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 3));
    bool isSetupComplete = await LocalStorage.isSetupComplete();
    if (isSetupComplete) {
      Get.offAllNamed(AppRoutes.dashboard);
    } else {
      Get.offAllNamed(AppRoutes.onboarding);
    }
  }
}

import 'package:get/get.dart';
import 'package:water_intake/view/home/controller/home_controller.dart';

class DashboardController extends GetxController {
  var selectedIndex = 0.obs;
  var isTipVisible = true.obs;

  void changeIndex(int index) {
    selectedIndex.value = index;
    if (index == 0) {
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().refreshAllData();
      }
    }
  }

  void hideTip() {
    isTipVisible.value = false;
  }
}


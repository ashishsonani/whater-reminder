import 'package:get/get.dart';
import 'package:water_intake/view/home/controller/home_controller.dart';
import '../controller/dashboard_controller.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => DashboardController());
    Get.lazyPut(() => HomeController());
  }
}

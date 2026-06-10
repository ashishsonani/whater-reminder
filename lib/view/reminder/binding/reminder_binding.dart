import 'package:get/get.dart';
import 'package:water_intake/view/reminder/controller/reminder_controller.dart';

class ReminderBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ReminderController());
  }
}

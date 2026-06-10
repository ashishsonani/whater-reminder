import 'package:get/get.dart';
import '../controller/drink_reminders_controller.dart';

class DrinkRemindersBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DrinkRemindersController>(() => DrinkRemindersController());
  }
}

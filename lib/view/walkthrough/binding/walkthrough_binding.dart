import 'package:get/get.dart';
import '../controller/walkthrough_controller.dart';

class WalkthroughBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(WalkthroughController(), permanent: true);
  }
}

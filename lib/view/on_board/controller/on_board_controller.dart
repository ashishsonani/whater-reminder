import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:water_intake/route/route.dart';

class OnBoardController extends GetxController {
  var currentPage = 0.obs;
  final PageController pageController = PageController();

  void onPageChanged(int index) {
    currentPage.value = index;
  }

  void skip() {
    Get.offAllNamed(AppRoutes.walkthrough);
  }

  void next() {
    if (currentPage.value < 1) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    } else {
      skip(); // Navigate to walkthrough
    }
  }
}

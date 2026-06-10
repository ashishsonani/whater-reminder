import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:water_intake/services/firebase_service.dart';
import 'package:water_intake/utils/app_strings.dart';

import '../screen/feedback/feedback_success_screen.dart';

class FeedbackController extends GetxController {
  var isLoading = false.obs;
  var selectedTopic = "".obs;

  final List<String> feedbackTopics = [AppString.feature, AppString.content, AppString.bug, AppString.thanks, AppString.other];

  final TextEditingController feedbackDetailController = TextEditingController();
  var feedbackImage = "".obs;
  var feedbackCharCount = 0.obs;
  var showFeedbackError = false.obs;

  void resetFeedbackDetail() {
    selectedTopic.value = "";
    feedbackDetailController.clear();
    feedbackCharCount.value = 0;
    feedbackImage.value = "";
    showFeedbackError.value = false;
  }

  Future<void> addAppFeedback() async {
    if (feedbackCharCount.value < 10) {
      showFeedbackError.value = true;
      return;
    }
    showFeedbackError.value = false;
    isLoading.value = true;

    try {
      String? uid = await FirebaseService().getUserId();
      final packageInfo = await PackageInfo.fromPlatform();

      await FirebaseService().firestore.collection('feedback').add({
        'uid': uid ?? 'anonymous',
        'topic': selectedTopic.value.toLowerCase(),
        'feedback': feedbackDetailController.text.trim(),
        'app_version': packageInfo.version,
        'timestamp': FieldValue.serverTimestamp(),
        // Note: Image upload to Storage could be added here if needed,
        // but for now we'll store the local path or skip if Storage is not set up.
        'image_path_local': feedbackImage.value,
      });

      Get.back(); // Close feedback screen
      Get.snackbar(AppString.thankYou.tr, AppString.feedbackSentSuccess.tr, backgroundColor: Colors.white, colorText: Colors.black);

      resetFeedbackDetail();
      Get.off(() => const FeedbackSuccessScreen());
    } catch (e) {
      log('Error submitting feedback: $e');
      Get.snackbar(AppString.error.tr, AppString.failedToSendFeedback.tr, backgroundColor: Colors.white, colorText: Colors.black);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    feedbackDetailController.dispose();
    super.onClose();
  }
}

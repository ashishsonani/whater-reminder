import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:water_intake/common/common_button.dart';
import 'package:water_intake/theme/app_colors.dart';
import 'package:water_intake/utils/app_strings.dart';
import 'package:water_intake/theme/app_text_styles.dart';

import '../../../../common/new_common_app_bar.dart' show newCommonAppBar;
import '../../controller/feedback_controller.dart';

class FeedbackDetailScreen extends StatelessWidget {
  const FeedbackDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure controller is registered
    final controller = Get.put(FeedbackController());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: newCommonAppBar(
        backgroundColor: Colors.white,
        // elevation: 0,
        // leading: IconButton(
        //   icon: const Icon(Icons.arrow_back, color: Color(0xff343A40)),
        //   onPressed: () => Get.back(),
        // ),
        title: AppString.feedback.tr,
        // style: AppTextStyle.latoBoldBlack16.copyWith(fontSize: 16.sp, fontWeight: FontWeight.w600),
        // ),
        centerTitle: false,
      ),
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        behavior: HitTestBehavior.opaque,
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 21.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 5.h),

              _buildSectionHeader(AppString.whatsOnYourMind.tr),
              _buildSubtitle(AppString.pickTopic.tr),
              SizedBox(height: 15.h),
              Obx(
                () => Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: controller.feedbackTopics.map((topic) {
                    return _buildTopicChip(topic, controller);
                  }).toList(),
                ),
              ),

              SizedBox(height: 25.h),
              _buildSectionHeader(AppString.tellUsMore.tr),
              SizedBox(height: 10.h),
              _buildFeedbackInputField(controller),
              SizedBox(height: 8.h),
              Obx(
                () => Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    "${controller.feedbackCharCount.value}/500",
                    style: AppTextStyle.latoRegularBlack14.copyWith(fontSize: 10.sp, color: const Color(0xff8596AB)),
                  ),
                ),
              ),

              SizedBox(height: 40.h),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomButton(context, controller),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTextStyle.latoBoldBlack16.copyWith(fontSize: 14.sp, fontWeight: FontWeight.w600, color: AppColors.black1),
    );
  }

  Widget _buildSubtitle(String text) {
    return Text(
      text,
      style: AppTextStyle.latoRegularBlack14.copyWith(fontSize: 14.sp, color: const Color(0xff6C757D)),
    );
  }

  Widget _buildTopicChip(String topic, FeedbackController controller) {
    bool isSelected = controller.selectedTopic.value == topic;
    return GestureDetector(
      onTap: () {
        controller.selectedTopic.value = topic;
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: isSelected ? AppColors.primary : const Color(0xffE6E6E6), width: 1),
        ),
        child: Text(
          topic.tr,
          style: AppTextStyle.latoMediumBlack14.copyWith(fontSize: 12.sp, color: const Color(0xff212529)),
        ),
      ),
    );
  }

  Widget _buildFeedbackInputField(FeedbackController controller) {
    return Obx(() {
      final hasError = controller.showFeedbackError.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: hasError ? const Color(0xffFF3B30) : const Color(0xffE6E6E6), width: 1),
            ),
            child: TextField(
              controller: controller.feedbackDetailController,
              maxLines: 4,
              maxLength: 500,
              decoration: InputDecoration(
                border: InputBorder.none,
                counterText: "",
                hintText: _getHintText(controller),
                hintStyle: AppTextStyle.latoRegularBlack14.copyWith(fontSize: 14.sp, color: const Color(0xffB0BBC9)),
              ),
              onChanged: (val) {
                controller.feedbackCharCount.value = val.length;
                if (val.isNotEmpty && controller.selectedTopic.value.isEmpty) {
                  controller.selectedTopic.value = AppString.other;
                }
                if (hasError && val.length >= 10) {
                  controller.showFeedbackError.value = false;
                }
              },
            ),
          ),
          if (hasError) ...[
            SizedBox(height: 4.h),
            Text(
              AppString.describeValidation.tr,
              style: AppTextStyle.latoRegularBlack14.copyWith(fontSize: 11.sp, color: const Color(0xffFF3B30)),
            ),
          ],
        ],
      );
    });
  }

  String _getHintText(FeedbackController controller) {
    final topic = controller.selectedTopic.value;
    if (topic == AppString.feature) return AppString.featureHint.tr;
    if (topic == AppString.bug) return AppString.bugHint.tr;
    if (topic == AppString.thanks) return AppString.thanksHint.tr;
    if (topic == AppString.other) return AppString.otherHint.tr;
    return AppString.whatDidYouExperience.tr;
  }

  Widget _buildBottomButton(BuildContext context, FeedbackController controller) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 21.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), offset: const Offset(0, -4), blurRadius: 10)],
      ),
      child: Obx(() {
        final isTopicSelected = controller.selectedTopic.value.isNotEmpty;
        final isFeedbackEntered = controller.feedbackCharCount.value > 0;
        final isEnabled = isTopicSelected && isFeedbackEntered;
        return CommonButton(
          height: 42.h,
          backgroundColor: isEnabled ? AppColors.primary : const Color(0xffB0BBC9),
          text: AppString.feedback.tr,
          textColor: Colors.white,
          onPressed: isEnabled ? () => controller.addAppFeedback() : null,
          borderRadius: 12.r,
        );
      }),
    );
  }
}

class DottedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = const Color(0xffB0BBC9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const double dashWidth = 5;
    const double dashSpace = 3;
    final RRect rrect = RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(12));

    final Path path = Path()..addRRect(rrect);

    final Path dashPath = Path();
    double distance = 0.0;
    for (final PathMetric metric in path.computeMetrics()) {
      while (distance < metric.length) {
        dashPath.addPath(metric.extractPath(distance, distance + dashWidth), Offset.zero);
        distance += dashWidth + dashSpace;
      }
      distance = 0.0;
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

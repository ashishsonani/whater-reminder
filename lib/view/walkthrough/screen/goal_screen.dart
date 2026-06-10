import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:water_intake/common/common_button.dart';
import 'package:water_intake/gen/assets.gen.dart';
import 'package:water_intake/theme/app_colors.dart';
import 'package:water_intake/theme/app_text_styles.dart';
import 'package:water_intake/utils/app_strings.dart';
import 'package:water_intake/view/walkthrough/controller/walkthrough_controller.dart';

import '../../../route/route.dart' show AppRoutes;

class GoalScreen extends StatelessWidget {
  GoalScreen({super.key});
  final controller = Get.find<WalkthroughController>();

  @override
  Widget build(BuildContext context) {
    // Find the existing controller

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            children: [
              SizedBox(height: 60.h),
              Text(
                AppString.whatsYourDailyGoal.tr,
                style: AppTextStyle.h2.copyWith(color: AppColors.black1),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30.h),
              // Unit Toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildGoalUnitButton(controller, title: AppString.ml.tr, isMlUnit: true),
                  SizedBox(width: 16.w),
                  _buildGoalUnitButton(controller, title: AppString.oz.tr, isMlUnit: false),
                ],
              ),
              Spacer(),
              Center(
                child: Obx(() {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '${controller.waterGoal.value}',
                            style: AppTextStyle.h1.copyWith(fontSize: 48.sp, color: AppColors.black1),
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            controller.isMl.value ? AppString.ml.tr : AppString.oz.tr,
                            style: AppTextStyle.body.copyWith(fontSize: 16.sp, color: AppColors.grey4),
                          ),
                        ],
                      ),
                      SizedBox(height: 30.h),
                      GestureDetector(
                        onTap: () {
                          _showAdjustDialog(context, controller);
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 20.w),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30.r),
                            border: Border.all(color: AppColors.grey3),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Assets.images.png.edit.image(scale: 3.5),

                              SizedBox(width: 8.w),
                              Text(AppString.adjust.tr, style: AppTextStyle.button.copyWith(color: AppColors.black2)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),

              SizedBox(height: 30.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 11.w),
                child: Row(
                  children: [
                    Expanded(
                      child: CommonButton(
                        text: AppString.skip.tr,
                        onPressed: () => Get.toNamed(AppRoutes.addReminder),
                        backgroundColor: AppColors.teal.withValues(alpha: 0.1),
                        textColor: AppColors.teal,
                        textStyle: AppTextStyle.skipButton,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: CommonButton(
                        text: AppString.continueText.tr,
                        onPressed: () async {
                          await controller.updateWaterGoalInFirebase();
                          Get.offAllNamed(AppRoutes.addReminder);
                        },
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 30.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoalUnitButton(WalkthroughController controller, {required String title, required bool isMlUnit}) {
    return Obx(() {
      bool isSelected = controller.isMl.value == isMlUnit;
      return GestureDetector(
        onTap: () => controller.toggleGoalUnit(isMlUnit),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 9.h, horizontal: 20.w),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.teal : AppColors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: isSelected ? AppColors.teal : AppColors.cardEdge),
            boxShadow: isSelected ? null : [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Center(
            child: Text(
              title,
              style: AppTextStyle.f10W400C23.copyWith(
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.white : AppColors.black1,
                fontSize: 18.sp,
              ),
            ),
          ),
        ),
      );
    });
  }

  void _showAdjustDialog(BuildContext context, WalkthroughController controller) {
    controller.tempWaterGoal.value = controller.waterGoal.value;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
          backgroundColor: AppColors.paper,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 15.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppString.adjustIntakeGoal.tr,
                      style: AppTextStyle.button.copyWith(fontSize: 18.sp, color: AppColors.grey4),
                    ),
                    GestureDetector(
                      onTap: () {
                        Get.toNamed(AppRoutes.intakeGoalInfo);
                      },
                      child: Assets.images.png.essential.image(scale: 3.8),
                    ),
                  ],
                ),
                SizedBox(height: 30.h),
                Obx(() {
                  double minVal = controller.isMl.value ? 500 : 17;
                  double maxVal = controller.isMl.value ? 10000 : 338;
                  double fraction = (controller.tempWaterGoal.value - minVal) / (maxVal - minVal);
                  fraction = fraction.clamp(0.0, 1.0);

                  return Container(
                    width: double.infinity,
                    alignment: Alignment(-1 + fraction, 0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${controller.tempWaterGoal.value}',
                          style: AppTextStyle.h1.copyWith(fontSize: 20.sp, color: AppColors.black1, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          controller.isMl.value ? AppString.ml.tr : AppString.oz.tr,
                          style: AppTextStyle.body.copyWith(fontSize: 14.sp, color: AppColors.grey1),
                        ),
                        SizedBox(width: 10.w),
                        GestureDetector(
                          onTap: () {
                            controller.tempWaterGoal.value = controller.getRecommendedGoal();
                          },
                          child: Assets.images.png.exchange.image(scale: 3.5),
                        ),
                      ],
                    ),
                  );
                }),
                SizedBox(height: 10.h),
                Obx(
                  () => SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 6.h,
                      padding: EdgeInsets.zero,
                      activeTrackColor: AppColors.teal,
                      inactiveTrackColor: AppColors.grey3,
                      thumbColor: AppColors.teal,
                      overlayColor: AppColors.teal.withOpacity(0.2),
                      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8.w),
                    ),
                    child: Slider(
                      value: controller.tempWaterGoal.value.toDouble(),
                      min: controller.isMl.value ? 500 : 17,
                      max: controller.isMl.value ? 10000 : 338,
                      onChanged: (val) {
                        controller.tempWaterGoal.value = val.round();
                      },
                    ),
                  ),
                ),
                Obx(() {
                  double minVal = controller.isMl.value ? 500 : 17;
                  double maxVal = controller.isMl.value ? 10000 : 338;
                  double fraction = (controller.tempWaterGoal.value - minVal) / (maxVal - minVal);
                  fraction = fraction.clamp(0.0, 1.0);

                  return Container(
                    width: double.infinity,
                    alignment: Alignment(-1 + fraction, 0),
                    child: GestureDetector(
                      onTap: () {
                        controller.tempWaterGoal.value = controller.getRecommendedGoal();
                      },
                      child: Text(
                        "${AppString.recommended.tr}",
                        style: AppTextStyle.button.copyWith(fontSize: 10.sp, color: AppColors.teal, fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                }),
                SizedBox(height: 28.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Get.back(),
                      child: Text(
                        AppString.cancel.tr,
                        style: AppTextStyle.body.copyWith(color: AppColors.grey4, fontWeight: FontWeight.w600),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    TextButton(
                      onPressed: () {
                        controller.waterGoal.value = controller.tempWaterGoal.value;
                        controller.updateWaterGoalInFirebase();
                        Get.back();
                      },
                      child: Text(
                        AppString.ok.tr,
                        style: AppTextStyle.body.copyWith(color: AppColors.teal, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

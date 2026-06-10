import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:water_intake/gen/assets.gen.dart';

import '../../../../../common/common_button.dart';
import '../../../../../route/route.dart';
import 'package:water_intake/theme/app_fonts.dart';
import 'package:water_intake/theme/app_colors.dart';
import '../../../../../utils/app_strings.dart';
import 'package:water_intake/theme/app_text_styles.dart';
import '../controller/preferences_controller.dart';
import '../preferences_bottom_sheets.dart';

class WaterIntakeGoalScreen extends StatelessWidget {
  const WaterIntakeGoalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PreferencesController>();

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.paper,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xff343A40)),
          onPressed: () => Get.back(),
        ),
        title: Text(
          AppString.intakeGoal.tr,
          style: TextStyle(color: const Color(0xff212529), fontSize: 16.sp, fontWeight: FontWeight.w600, fontFamily: AppFonts.lato),
        ),

        centerTitle: false,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            children: [
              SizedBox(height: 16.h),

              // Recommended Goal Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 24.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),border: Border.all(color: AppColors.cardEdge),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  children: [
                    Text(
                      AppString.recommendedGoal.tr,
                      style: TextStyle(color: const Color(0xff6C757D), fontSize: 14.sp, fontFamily: AppFonts.lato),
                    ),
                    SizedBox(height: 12.h),
                    Obx(
                      () => Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '${controller.intakeGoal.value}',
                            style: TextStyle(
                              color: AppColors.teal,
                              fontSize: 40.sp,
                              fontWeight: FontWeight.w600,
                              fontFamily: AppFonts.lato,
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            controller.intakeUnit.value,
                            style: TextStyle(color: const Color(0xffADB5BD), fontSize: 16.sp, fontFamily: AppFonts.lato),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      AppString.basedOnPersonalData.tr,
                      style: TextStyle(color: const Color(0xff6C757D), fontSize: 14.sp, fontFamily: AppFonts.lato),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20.h),

              // Personal Data Section
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),border: Border.all(color: AppColors.cardEdge),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  children: [
                    Obx(
                      () => _buildInfoTile(
                        icon: Assets.images.png.profileUser.image(scale: 3.5),
                        title: AppString.gender.tr,
                        value: controller.gender.value.tr,
                        onTap: () {
                          PreferencesBottomSheets.showSelectionBottomSheet(
                            context: context,
                            title: AppString.editGender.tr,
                            options: [
                              AppString.male,
                              AppString.female,
                              AppString.pregnant,
                              AppString.breastfeeding,
                              AppString.preferNotToSay,
                            ],
                            descriptions: ['', '', AppString.plus15PercentWater.tr, AppString.plus30PercentWater.tr, ''],
                            currentValue: controller.gender.value,
                            onSave: (val) => controller.updateGender(val),
                            icons: [
                              Assets.images.png.male.image(
                                scale: 8.5,
                                color: controller.gender.value == AppString.male ? const Color(0xff4B9CFF) : const Color(0xff495057),
                              ),
                              Assets.images.png.female.image(
                                scale: 8.5,
                                color: controller.gender.value == AppString.female ? const Color(0xff4B9CFF) : const Color(0xff495057),
                              ),
                              Assets.images.png.pregnantWoman.image(
                                scale: 8.5,
                                color: controller.gender.value == AppString.pregnant ? const Color(0xff4B9CFF) : const Color(0xff495057),
                              ),
                              Assets.images.png.babyBottle.image(
                                scale: 8.5,
                                color: controller.gender.value == AppString.breastfeeding ? const Color(0xff4B9CFF) : const Color(0xff495057),
                              ),
                              Assets.images.png.profileUser.image(
                                scale: 3.5,
                                color: controller.gender.value == AppString.preferNotToSay ? const Color(0xff4B9CFF) : const Color(0xff495057),
                              ),
                            ],
                          );
                        },
                      ),
                    ),

                    Obx(
                      () => _buildInfoTile(
                        icon: Assets.images.png.growthStar.image(scale: 3.5),
                        title: AppString.weight.tr,
                        value: '${controller.weightValue.value} ${controller.weightUnit.value.tr}',
                        onTap: () {
                          PreferencesBottomSheets.showWeightPickerBottomSheet(context, controller);
                        },
                      ),
                    ),

                    Obx(
                      () => _buildInfoTile(
                        icon: Assets.images.png.activity.image(scale: 3.5),
                        title: AppString.activityLevel.tr,
                        value: controller.activityLevel.value.tr,
                        onTap: () {
                          PreferencesBottomSheets.showSelectionBottomSheet(
                            context: context,
                            title: AppString.editActivityLevel.tr,
                            options: [
                              AppString.sedentary,
                              AppString.lightActivity,
                              AppString.moderateActive,
                              AppString.veryActive,
                            ],
                            descriptions: [
                              AppString.sedentaryDesc.tr,
                              AppString.lightActivityDesc.tr,
                              AppString.moderateActiveDesc.tr,
                              AppString.veryActiveDesc.tr,
                            ],
                            currentValue: controller.activityLevel.value,
                            onSave: (val) => controller.updateActivityLevel(val),
                            icons: [
                              Assets.images.png.sedentry.image(scale: 3.5),
                              Assets.images.png.lightActivity.image(scale: 3.5),
                              Assets.images.png.modrate.image(scale: 3.5),
                              Assets.images.png.veryActive.image(scale: 3.5),
                            ],
                          );
                        },
                      ),
                    ),

                    Obx(
                      () => _buildInfoTile(
                        icon: Assets.images.png.weather3.image(scale: 3.5),
                        title: AppString.climate.tr,
                        value: controller.climate.value.tr,
                        onTap: () {
                          PreferencesBottomSheets.showSelectionBottomSheet(
                            context: context,
                            title: AppString.editClimate.tr,
                            options: [AppString.hot, AppString.temperate, AppString.cold],
                            currentValue: controller.climate.value,
                            onSave: (val) => controller.updateClimate(val),
                            icons: [
                              Assets.images.png.hot.image(scale: 3.5),
                              Assets.images.png.temp.image(scale: 3.5),
                              Assets.images.png.cold.image(scale: 3.5),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),
              CommonButton(
                text: AppString.adjustManually.tr,
                onPressed: () {
                  _showAdjustDialog(context, controller);
                },
                backgroundColor: AppColors.teal.withValues(alpha: 0.1),
                textColor: AppColors.teal,
                textStyle: AppTextStyle.skipButton,
                border: BorderSide(color: AppColors.teal.withValues(alpha: 0.1), width: 1.5),
              ),
              SizedBox(height: 12.h),

              CommonButton(
                text: AppString.save.tr,
                onPressed: () {
                  controller.updateIntakeGoal(controller.intakeGoal.value);
                  Get.back();
                },
                backgroundColor: AppColors.teal,
                textColor: AppColors.white,
                textStyle: AppTextStyle.skipButton,
              ),
              SizedBox(height: 30.h),
            ],
          ),
        );
      }),
    );
  }

  void _showAdjustDialog(BuildContext context, PreferencesController controller) {
    RxInt tempGoal = controller.intakeGoal.value.obs;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
          backgroundColor: AppColors.white,
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
                        Get.back();

                        Get.toNamed(AppRoutes.intakeGoalInfo);
                      },
                      child: Assets.images.png.essential.image(scale: 3.8),
                    ),
                  ],
                ),
                SizedBox(height: 30.h),
                Obx(() {
                  bool isMl = controller.intakeUnit.value == 'ml';
                  double minVal = isMl ? 500 : 17;
                  double maxVal = isMl ? 10000 : 338;
                  double fraction = (tempGoal.value - minVal) / (maxVal - minVal);
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
                          '${tempGoal.value}',
                          style: AppTextStyle.h1.copyWith(fontSize: 20.sp, color: AppColors.black1, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          isMl ? AppString.ml.tr : AppString.oz.tr,
                          style: AppTextStyle.body.copyWith(fontSize: 14.sp, color: AppColors.grey1),
                        ),
                        SizedBox(width: 10.w),
                        GestureDetector(
                          onTap: () {
                            tempGoal.value = controller.getRecommendedGoal();
                          },
                          child: Assets.images.png.exchange.image(scale: 3.5),
                        ),
                      ],
                    ),
                  );
                }),
                SizedBox(height: 10.h),
                Obx(() {
                  bool isMl = controller.intakeUnit.value == 'ml';
                  return SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 6.h,
                      padding: EdgeInsets.zero,
                      activeTrackColor: AppColors.primary,
                      inactiveTrackColor: AppColors.grey3,
                      thumbColor: AppColors.primary,
                      overlayColor: AppColors.primary.withOpacity(0.2),
                      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8.w),
                    ),
                    child: Slider(
                      value: tempGoal.value.toDouble().clamp(isMl ? 500.0 : 17.0, isMl ? 10000.0 : 338.0),
                      min: isMl ? 500 : 17,
                      max: isMl ? 10000 : 338,
                      onChanged: (val) {
                        tempGoal.value = val.round();
                      },
                    ),
                  );
                }),
                Obx(() {
                  bool isMl = controller.intakeUnit.value == 'ml';
                  double minVal = isMl ? 500 : 17;
                  double maxVal = isMl ? 10000 : 338;
                  double fraction = (tempGoal.value - minVal) / (maxVal - minVal);
                  fraction = fraction.clamp(0.0, 1.0);

                  return Container(
                    width: double.infinity,
                    alignment: Alignment(-1 + fraction, 0),
                    child: GestureDetector(
                      onTap: () {
                        tempGoal.value = controller.getRecommendedGoal();
                      },
                      child: Text(
                        AppString.recommended.tr,
                        style: AppTextStyle.button.copyWith(fontSize: 10.sp, color: AppColors.primary, fontWeight: FontWeight.bold),
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
                        controller.updateIntakeGoal(tempGoal.value);
                        Get.back();
                      },
                      child: Text(
                        AppString.ok.tr,
                        style: AppTextStyle.body.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
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

  Widget _buildInfoTile({required Widget icon, required String title, required String value, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          children: [
            icon,
            SizedBox(width: 16.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w500, fontFamily: AppFonts.lato, color: const Color(0xff343A40)),
              ),
            ),
            Text(
              value,
              style: TextStyle(fontSize: 14.sp, fontFamily: AppFonts.lato, color: const Color(0xffADB5BD)),
            ),
            SizedBox(width: 8.w),
            Icon(Icons.keyboard_arrow_right, size: 20.w, color: const Color(0xffADB5BD)),
          ],
        ),
      ),
    );
  }
}

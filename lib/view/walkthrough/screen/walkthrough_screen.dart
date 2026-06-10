import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:water_intake/common/common_button.dart';
import 'package:water_intake/gen/assets.gen.dart';
import 'package:water_intake/theme/app_colors.dart';
import 'package:water_intake/utils/app_strings.dart';
import 'package:water_intake/theme/app_text_styles.dart';
import 'package:water_intake/view/walkthrough/controller/walkthrough_controller.dart';

class WalkthroughScreen extends StatelessWidget {
  const WalkthroughScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WalkthroughController>();

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Obx(() {
        if (controller.isCreatingPlan.value) {
          return _buildLoadingScreen(controller);
        }
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              children: [
                SizedBox(height: 20.h),
                // Progress Bar
                Obx(
                  () => Row(
                    children: [
                      SizedBox(
                        width: 40.w,
                        child: controller.currentStep.value != 1
                            ? GestureDetector(
                                onTap: () => controller.previousStep(),
                                child: Icon(Icons.arrow_back, color: AppColors.black, size: 24.w),
                              )
                            : const SizedBox(),
                      ),
                      // SizedBox(width: 26.w),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6.r),
                          child: LinearProgressIndicator(
                            value: controller.currentStep.value / controller.totalSteps,
                            backgroundColor: AppColors.grey2,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.teal),
                            minHeight: 8.h,
                          ),
                        ),
                      ),
                      SizedBox(width: 20.w),
                      Text(
                        '${controller.currentStep.value}/${controller.totalSteps}',
                        style: AppTextStyle.body.copyWith(fontWeight: FontWeight.bold, color: AppColors.black1, fontSize: 16.sp),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12.h),
                Expanded(
                  child: Obx(() {
                    if (controller.currentStep.value == 1) {
                      return _buildStep1(controller);
                    } else if (controller.currentStep.value == 2) {
                      return _buildStep2(controller);
                    } else if (controller.currentStep.value == 3) {
                      return _buildStep3(controller);
                    } else if (controller.currentStep.value == 4) {
                      return _buildStep4(controller);
                    } else if (controller.currentStep.value == 5) {
                      return _buildStep5(controller);
                    } else if (controller.currentStep.value == 6) {
                      return _buildStep6(controller);
                    } else if (controller.currentStep.value == 7) {
                      return _buildStep7(controller);
                    }
                    return const SizedBox.shrink();
                  }),
                ),

                SizedBox(height: 30.h),

                CommonButton(text: AppString.continueText.tr, onPressed: () => controller.nextStep()),
                SizedBox(height: 30.h),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildLoadingScreen(WalkthroughController controller) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 40.h),
        child: Column(
          children: [
            Text(
              AppString.generatingPlan.tr,
              style: AppTextStyle.h2.copyWith(fontSize: 22.sp, color: AppColors.black1),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 14.h),
            Text(
              AppString.pleaseWait.tr,
              style: AppTextStyle.body.copyWith(fontSize: 16.sp, color: AppColors.grey4),
              textAlign: TextAlign.center,
            ),
            Expanded(
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 220.w,
                      height: 220.w,
                      child: CircularProgressIndicator(
                        value: controller.progressValue.value / 100,
                        strokeWidth: 14.w,
                        backgroundColor: AppColors.grey2,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.teal),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Text(
                      '${controller.progressValue.value}%',
                      style: AppTextStyle.h1.copyWith(fontSize: 48.sp, color: AppColors.black1),
                    ),
                  ],
                ),
              ),
            ),
            Text(
              AppString.thisWillTakeAMoment.tr,
              style: AppTextStyle.button.copyWith(fontSize: 14.sp, color: AppColors.grey4),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderCard(WalkthroughController controller, {required String title, required String image, required String gender}) {
    return Obx(() {
      bool isSelected = controller.selectedGender.value == gender;
      return GestureDetector(
        onTap: () => controller.selectGender(gender),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(18.w),
              // height: 110.w,
              // width: 110.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.teal : AppColors.white,
                border: Border.all(
                  color: isSelected ? AppColors.teal : AppColors.cardEdge,
                ),
                boxShadow: isSelected
                    ? null
                    : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(child: Image.asset(image, scale: 3.9, color: isSelected ? AppColors.white : const Color(0xFF2D3142))),
            ),
            SizedBox(height: 11.h),
            Text(
              title,
              style: AppTextStyle.body.copyWith(fontWeight: FontWeight.w600, color: AppColors.black1),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStep1(WalkthroughController controller) {
    return Column(
      children: [
        Text(
          AppString.whatsYourGender.tr,
          style: AppTextStyle.h2.copyWith(fontSize: 20.sp, color: AppColors.black1),
        ),
        SizedBox(height: 60.h),
        // Gender Grid
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 20.w,
            mainAxisSpacing: 20.h,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildGenderCard(controller, title: AppString.male.tr, image: Assets.images.png.male.path, gender: 'male'),
              _buildGenderCard(controller, title: AppString.female.tr, image: Assets.images.png.female.path, gender: 'female'),
              _buildGenderCard(controller, title: AppString.pregnant.tr, image: Assets.images.png.pregnantWoman.path, gender: 'pregnant'),
              _buildGenderCard(
                controller,
                title: AppString.breastfeeding.tr,
                image: Assets.images.png.babyBottle.path,
                gender: 'breastfeeding',
              ),
            ],
          ),
        ),
        Center(
          child: GestureDetector(
            onTap: () {
              controller.selectGender('');
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30.r),
                border: Border.all(color: AppColors.grey3),
              ),
              child: Text(
                AppString.preferNotToSay.tr,
                style: AppTextStyle.body.copyWith(fontWeight: FontWeight.w600, color: AppColors.black2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2(WalkthroughController controller) {
    return Column(
      children: [
        Text(
          AppString.howMuchWeight.tr,
          style: AppTextStyle.h2.copyWith(fontSize: 20.sp, color: AppColors.black1),
        ),
        SizedBox(height: 30.h),
        // Toggle Buttons kg/lb
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildUnitButton(controller, title: AppString.kg.tr, isKg: true),
            SizedBox(width: 16.w),
            _buildUnitButton(controller, title: AppString.lb.tr, isKg: false),
          ],
        ),
        SizedBox(height: 40.h),
        Expanded(
          child: ListWheelScrollView.useDelegate(
            controller: controller.weightScrollController,
            itemExtent: 50.h,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: (index) {
              controller.setWeight(index + 1);
            },
            childDelegate: ListWheelChildBuilderDelegate(
              builder: (context, index) {
                if (index < 0 || index >= 500) return null;
                int weightValue = index + 1;
                return Obx(() {
                  bool isSelected = controller.weight.value == weightValue;
                  return Container(
                    width: 65.w,
                    // padding: EdgeInsets.symmetric(vertical: 0.h),
                    decoration: isSelected ? BoxDecoration(color: AppColors.teal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10.r)) : null,
                    child: Center(
                      child: Text(
                        weightValue.toString().padLeft(2, '0'),
                        style: AppTextStyle.f10W400C23.copyWith(
                          fontSize: 24.sp,
                          color: isSelected ? AppColors.teal : AppColors.black1.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                });
              },
              childCount: 500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUnitButton(WalkthroughController controller, {required String title, required bool isKg}) {
    return Obx(() {
      bool isSelected = controller.isKg.value == isKg;
      return GestureDetector(
        onTap: () => controller.toggleWeightUnit(isKg),
        child: Container(
          // width: 80.w,
          padding: EdgeInsets.symmetric(vertical: 9.h, horizontal: 20.w),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.teal : AppColors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isSelected ? AppColors.teal : AppColors.cardEdge,
            ),
            boxShadow: isSelected
                ? null
                : [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
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

  Widget _buildStep3(WalkthroughController controller) {
    return Column(
      children: [
        Text(
          AppString.whatsYourAge.tr,
          style: AppTextStyle.h2.copyWith(fontSize: 20.sp, color: AppColors.black1),
        ),
        SizedBox(height: 70.h),
        Expanded(
          child: ListWheelScrollView.useDelegate(
            controller: controller.ageScrollController,
            itemExtent: 50.h,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: (index) {
              controller.setAge(index + 1);
            },
            childDelegate: ListWheelChildBuilderDelegate(
              builder: (context, index) {
                if (index < 0 || index >= 100) return null;
                int ageValue = index + 1;
                return Obx(() {
                  bool isSelected = controller.age.value == ageValue;
                  return Container(
                    width: 65.w,
                    // padding: E/**/dgeInsets.symmetric(vertical: 1.h),
                    decoration: isSelected ? BoxDecoration(color: AppColors.teal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10.r)) : null,
                    child: Center(
                      child: Text(
                        ageValue.toString().padLeft(2, '0'),
                        style: AppTextStyle.f10W400C23.copyWith(
                          fontSize: 24.sp,
                          color: isSelected ? AppColors.teal : AppColors.black1.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                });
              },
              childCount: 100,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep4(WalkthroughController controller) {
    return Column(
      children: [
        Text(
          AppString.whatsTimeWakeUp.tr,
          style: AppTextStyle.h2.copyWith(fontSize: 20.sp, color: AppColors.black1),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 20.h),
        // Toggle Buttons 12H/24H
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildTimeFormatButton(controller, title: AppString.format12H.tr, is12H: true),
            SizedBox(width: 16.w),
            _buildTimeFormatButton(controller, title: AppString.format24H.tr, is12H: false),
          ],
        ),
        SizedBox(height: 40.h),
        Expanded(
          child: Obx(() {
            bool is12H = controller.is12HourFormat.value;
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Hours Wheel
                SizedBox(
                  width: 85.w,
                  child: ListWheelScrollView.useDelegate(
                    controller: controller.hourScrollController,
                    itemExtent: 50.h,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: (index) {
                      controller.setWakeUpHour(is12H ? index + 1 : index);
                    },
                    childDelegate: ListWheelChildBuilderDelegate(
                      builder: (context, index) {
                        if (is12H) {
                          if (index < 0 || index > 11) return null;
                        } else {
                          if (index < 0 || index > 23) return null;
                        }
                        int hourValue = is12H ? index + 1 : index;
                        return Obx(() {
                          bool isSelected = controller.wakeUpHour.value == hourValue;
                          return _buildWheelItem(hourValue.toString().padLeft(2, '0'), isSelected);
                        });
                      },
                      childCount: is12H ? 12 : 24,
                    ),
                  ),
                ),

                SizedBox(width: 8.w),
                // Minutes Wheel
                SizedBox(
                  width: 85.w,
                  child: ListWheelScrollView.useDelegate(
                    controller: controller.minuteScrollController,
                    itemExtent: 50.h,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: (index) {
                      controller.setWakeUpMinute(index);
                    },
                    childDelegate: ListWheelChildBuilderDelegate(
                      builder: (context, index) {
                        if (index < 0 || index > 59) return null;
                        return Obx(() {
                          bool isSelected = controller.wakeUpMinute.value == index;
                          return _buildWheelItem(index.toString().padLeft(2, '0'), isSelected);
                        });
                      },
                      childCount: 60,
                    ),
                  ),
                ),
                // AM/PM Wheel (Only if 12H format)
                if (is12H) ...[
                  SizedBox(width: 8.w),
                  SizedBox(
                    width: 80.w,
                    child: ListWheelScrollView.useDelegate(
                      controller: controller.amPmScrollController,
                      itemExtent: 50.h,
                      physics: const FixedExtentScrollPhysics(),
                      onSelectedItemChanged: (index) {
                        controller.setAmPm(index == 0);
                      },
                      childDelegate: ListWheelChildBuilderDelegate(
                        builder: (context, index) {
                          if (index < 0 || index > 1) return null;
                          bool isAmValue = index == 0;
                          return Obx(() {
                            bool isSelected = controller.isAm.value == isAmValue;
                            String text = isAmValue ? AppString.am.tr : AppString.pm.tr;
                            return _buildWheelItem(text, isSelected);
                          });
                        },
                        childCount: 2,
                      ),
                    ),
                  ),
                ],
              ],
            );
          }),
        ),
      ],
    );
  }

  Widget _buildStep5(WalkthroughController controller) {
    return Column(
      children: [
        Text(
          AppString.whatsTimeGoToBed.tr,
          style: AppTextStyle.h2.copyWith(fontSize: 20.sp, color: AppColors.black1),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 30.h),
        // Toggle Buttons 12H/24H
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildTimeFormatButton(controller, title: AppString.format12H.tr, is12H: true),
            SizedBox(width: 16.w),
            _buildTimeFormatButton(controller, title: AppString.format24H.tr, is12H: false),
          ],
        ),
        SizedBox(height: 40.h),
        Expanded(
          child: Obx(() {
            bool is12H = controller.is12HourFormat.value;
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Hours Wheel
                SizedBox(
                  width: 85.w,
                  child: ListWheelScrollView.useDelegate(
                    controller: controller.bedHourScrollController,
                    itemExtent: 50.h,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: (index) {
                      controller.setBedTimeHour(is12H ? index + 1 : index);
                    },
                    childDelegate: ListWheelChildBuilderDelegate(
                      builder: (context, index) {
                        if (is12H) {
                          if (index < 0 || index > 11) return null;
                        } else {
                          if (index < 0 || index > 23) return null;
                        }
                        int hourValue = is12H ? index + 1 : index;
                        return Obx(() {
                          bool isSelected = controller.bedTimeHour.value == hourValue;
                          return _buildWheelItem(hourValue.toString().padLeft(2, '0'), isSelected);
                        });
                      },
                      childCount: is12H ? 12 : 24,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  ':',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                    fontFamily: AppTextStyle.fontFamily,
                  ),
                ),
                SizedBox(width: 8.w),
                // Minutes Wheel
                SizedBox(
                  width: 85.w,
                  child: ListWheelScrollView.useDelegate(
                    controller: controller.bedMinuteScrollController,
                    itemExtent: 50.h,
                    physics: const FixedExtentScrollPhysics(),
                    onSelectedItemChanged: (index) {
                      controller.setBedTimeMinute(index);
                    },
                    childDelegate: ListWheelChildBuilderDelegate(
                      builder: (context, index) {
                        if (index < 0 || index > 59) return null;
                        return Obx(() {
                          bool isSelected = controller.bedTimeMinute.value == index;
                          return _buildWheelItem(index.toString().padLeft(2, '0'), isSelected);
                        });
                      },
                      childCount: 60,
                    ),
                  ),
                ),
                // AM/PM Wheel (Only if 12H format)
                if (is12H) ...[
                  SizedBox(width: 8.w),
                  SizedBox(
                    width: 85.w,
                    child: ListWheelScrollView.useDelegate(
                      controller: controller.bedAmPmScrollController,
                      itemExtent: 50.h,
                      physics: const FixedExtentScrollPhysics(),
                      onSelectedItemChanged: (index) {
                        controller.setBedAmPm(index == 0);
                      },
                      childDelegate: ListWheelChildBuilderDelegate(
                        builder: (context, index) {
                          if (index < 0 || index > 1) return null;
                          bool isAmValue = index == 0;
                          return Obx(() {
                            bool isSelected = controller.isBedTimeAm.value == isAmValue;
                            String text = isAmValue ? AppString.am.tr : AppString.pm.tr;
                            return _buildWheelItem(text, isSelected);
                          });
                        },
                        childCount: 2,
                      ),
                    ),
                  ),
                ],
              ],
            );
          }),
        ),
      ],
    );
  }

  Widget _buildWheelItem(String text, bool isSelected) {
    return Container(
      width: 65.w,
      // padding: EdgeInsets.symmetric(vertical: 1.h),
      decoration: isSelected ? BoxDecoration(color: AppColors.teal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12.r)) : null,
      child: Center(
        child: Text(
          text,
          style: AppTextStyle.f10W400C23.copyWith(
            fontSize: 22.sp,
            color: isSelected ? AppColors.teal : AppColors.black1.withValues(alpha: 0.5),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildTimeFormatButton(WalkthroughController controller, {required String title, required bool is12H}) {
    return Obx(() {
      bool isSelected = controller.is12HourFormat.value == is12H;
      return GestureDetector(
        onTap: () => controller.toggleTimeFormat(is12H),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 5.h, horizontal: 12.w),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.teal : AppColors.white,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: isSelected ? AppColors.teal : AppColors.cardEdge,
            ),
            boxShadow: isSelected
                ? null
                : [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
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

  Widget _buildStep6(WalkthroughController controller) {
    return Column(
      children: [
        Text(
          AppString.whatsYourActivityLevel.tr,
          style: AppTextStyle.h2.copyWith(fontSize: 20.sp, color: AppColors.black1),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 25.h),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                _buildActivityCard(
                  controller,
                  title: AppString.sedentary.tr,
                  desc: AppString.sedentaryDesc.tr,
                  imagePath: Assets.images.png.sedentry.path,
                  value: 'sedentary',
                ),
                _buildActivityCard(
                  controller,
                  title: AppString.lightActivity.tr,
                  desc: AppString.lightActivityDesc.tr,
                  imagePath: Assets.images.png.lightActivity.path,
                  value: 'light',
                ),
                _buildActivityCard(
                  controller,
                  title: AppString.moderateActive.tr,
                  desc: AppString.moderateActiveDesc.tr,
                  imagePath: Assets.images.png.modrate.path,
                  value: 'moderate',
                ),
                _buildActivityCard(
                  controller,
                  title: AppString.veryActive.tr,
                  desc: AppString.veryActiveDesc.tr,
                  imagePath: Assets.images.png.veryActive.path,
                  value: 'very_active',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityCard(
    WalkthroughController controller, {
    required String title,
    required String desc,
    imagePath,
    required String value,
  }) {
    return Obx(() {
      bool isSelected = controller.selectedActivity.value == value;
      return GestureDetector(
        onTap: () => controller.selectActivity(value),
        child: Container(
          margin: EdgeInsets.only(bottom: 16.h),
          padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isSelected ? AppColors.teal : Colors.grey.shade300, width: isSelected ? 1.5:1
            ),
            boxShadow: isSelected
                ? null
                : [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(imagePath, width: 36.w, height: 36.w, fit: BoxFit.contain),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyle.h2.copyWith(fontSize: 16.sp, color: AppColors.black2, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      desc,
                      style: AppTextStyle.body.copyWith(fontSize: 14.sp, color: AppColors.grey4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildStep7(WalkthroughController controller) {
    return Column(
      children: [
        Text(
          AppString.whatsTheClimate.tr,
          style: AppTextStyle.h2.copyWith(fontSize: 20.sp, color: AppColors.black1),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 40.h),
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildClimateCard(controller, title: AppString.hot.tr, imagePath: Assets.images.png.hot.path, value: 'hot'),
                  _buildClimateCard(controller, title: AppString.temperate.tr, imagePath: Assets.images.png.temp.path, value: 'temperate'),
                  _buildClimateCard(controller, title: AppString.cold.tr, imagePath: Assets.images.png.cold.path, value: 'cold'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClimateCard(WalkthroughController controller, {required String title, required String imagePath, required String value}) {
    return Obx(() {
      bool isSelected = controller.selectedClimate.value == value;
      return GestureDetector(
        onTap: () => controller.selectClimate(value),
        child: Container(
          margin: EdgeInsets.only(bottom: 20.h),
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isSelected ? AppColors.teal : Colors.grey.shade300, width: isSelected ? 1.5 : 1
            ),
            boxShadow: isSelected
                ? null
                : [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Image.asset(imagePath, width: 32.w, height: 32.w, fit: BoxFit.contain),
              SizedBox(width: 20.w),
              Text(
                title,
                style: AppTextStyle.button.copyWith(fontSize: 15.sp, color: AppColors.black3),
              ),
            ],
          ),
        ),
      );
    });
  }
}

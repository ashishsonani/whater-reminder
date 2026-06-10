import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:water_intake/common/common_button.dart';
import 'package:water_intake/gen/assets.gen.dart';
import 'package:water_intake/theme/app_colors.dart';
import 'package:water_intake/utils/app_strings.dart';
import 'package:water_intake/theme/app_text_styles.dart';
import 'package:water_intake/view/reminder/controller/reminder_controller.dart';
import 'package:water_intake/view/walkthrough/controller/walkthrough_controller.dart';

class AddReminderScreen extends StatelessWidget {
  const AddReminderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool fromAccount = Get.arguments is Map && Get.arguments['fromAccount'] == true;
    final controller = Get.find<ReminderController>();

    // Check if walkthrough controller has 24h format setting
    if (Get.isRegistered<WalkthroughController>()) {
      controller.is12HourFormat.value = Get.find<WalkthroughController>().is12HourFormat.value;
    }

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.paper,
        elevation: 0,
        surfaceTintColor: AppColors.paper,
        centerTitle: true,
        automaticallyImplyLeading: fromAccount,
        leading: fromAccount
            ? IconButton(
                onPressed: () => Get.back(),
                icon: Icon(Icons.arrow_back_ios, color: AppColors.black1, size: 20.sp),
              )
            : null,
        title: Text(
          AppString.addReminder.tr,
          style: AppTextStyle.h2.copyWith(fontSize: 16.sp, color: AppColors.black1),
        ),
        actions: [
          GestureDetector(onTap: () => _showAddReminderBottomSheet(context, controller), child: Assets.images.png.plus.image(scale: 4.2)),
          SizedBox(width: 20.w),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // SizedBox(height: 10 .h),
            // List of Reminders
            Expanded(
              child: Obx(
                () => ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  itemCount: controller.reminders.length,
                  itemBuilder: (context, index) {
                    var reminder = controller.reminders[index];
                    return Obx(() {
                      bool isSwiped = reminder.isSwiped.value;
                      String fullTime = reminder.timeRange;
                      String displayFullTime = fullTime
                          .replaceAll('AM', AppString.am.tr)
                          .replaceAll('PM', AppString.pm.tr);
                      String amPm = fullTime.endsWith('AM') ? AppString.am.tr : (fullTime.endsWith('PM') ? AppString.pm.tr : '');

                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onHorizontalDragUpdate: (details) {
                          if (details.primaryDelta! < -0.5) {
                            controller.toggleSwipe(index, true); // Swiped left
                          } else if (details.primaryDelta! > 0.5) {
                            controller.toggleSwipe(index, false); // Swiped right
                          }
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    (reminder.timeRange == '8 AM – 10 PM' || reminder.timeRange == '08:00 – 22:00')
                                        ? AppString.defaultTimeRange.tr
                                        : ((isSwiped && amPm.isNotEmpty) ? amPm : displayFullTime),
                                    style: AppTextStyle.h2.copyWith(fontSize: 16.sp, color: AppColors.black1, fontWeight: FontWeight.w600),
                                  ),
                                  if (reminder.interval.isNotEmpty) ...[
                                    Text(
                                      (reminder.interval == 'Every 2 hours' || reminder.interval == '2 saatte bir')
                                          ? AppString.everyTwoHours.tr
                                          : reminder.interval,
                                      style: AppTextStyle.body.copyWith(fontSize: 12.sp, color: AppColors.grey4),
                                    ),
                                  ],
                                ],
                              ),
                              Row(
                                children: [
                                  CupertinoSwitch(
                                    value: reminder.isActive,
                                    activeTrackColor: AppColors.teal,
                                    onChanged: (val) {
                                      controller.toggleReminder(index, val);
                                    },
                                  ),
                                  if (isSwiped) ...[
                                    SizedBox(width: 12.w),
                                    GestureDetector(
                                      onTap: () => controller.deleteReminder(index),
                                      child: Assets.images.png.delete1.image(scale: 3.5),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    });
                  },
                ),
              ),
            ),
            // Bottom Button (Only show if not from account)
            if (!fromAccount)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 30.h),
                child: CommonButton(
                  text: AppString.letsHydrate.tr,
                  onPressed: () {
                    controller.completeSetup();
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showAddReminderBottomSheet(BuildContext context, ReminderController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.paper,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 10.h),
              // Drag handle
              Container(
                width: 35.w,
                height: 4.h,
                decoration: BoxDecoration(color: AppColors.grey6, borderRadius: BorderRadius.circular(2.r)),
              ),
              SizedBox(height: 12.h),
              // Header
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(AppString.addReminder.tr, style: AppTextStyle.button.copyWith(color: AppColors.black1)),
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: Icon(Icons.close, color: AppColors.grey1, size: 20.sp),
                    ),
                  ],
                ),
              ),
              Divider(color: AppColors.grey6, height: 30.h),
              // Time Picker
              SizedBox(
                height: 250.h,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 35.0.w),
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
                              controller.selectedHour.value = is12H ? index + 1 : index;
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
                                  bool isSelected = controller.selectedHour.value == hourValue;
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
                            controller: controller.minuteScrollController,
                            itemExtent: 50.h,
                            physics: const FixedExtentScrollPhysics(),
                            onSelectedItemChanged: (index) {
                              controller.selectedMinute.value = index;
                            },
                            childDelegate: ListWheelChildBuilderDelegate(
                              builder: (context, index) {
                                if (index < 0 || index > 59) return null;
                                return Obx(() {
                                  bool isSelected = controller.selectedMinute.value == index;
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
                              controller: controller.amPmScrollController,
                              itemExtent: 50.h,
                              physics: const FixedExtentScrollPhysics(),
                              onSelectedItemChanged: (index) {
                                controller.isAm.value = index == 0;
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
              ),
              SizedBox(height: 30.h),
              // Buttons
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
                child: Row(
                  children: [
                    Expanded(
                      child: CommonButton(
                        text: AppString.cancel.tr,
                        backgroundColor: AppColors.teal.withValues(alpha: 0.1),
                        textColor: AppColors.teal,
                        // height: 50.h,
                        onPressed: () => Get.back(),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: CommonButton(
                        text: AppString.save.tr,
                        backgroundColor: AppColors.teal,
                        textColor: AppColors.white,
                        // height: 50.h,
                        onPressed: () => controller.saveReminder(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWheelItem(String text, bool isSelected) {
    return Container(
      width: 70.w,
      padding: EdgeInsets.symmetric(vertical: 1.h),
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
}

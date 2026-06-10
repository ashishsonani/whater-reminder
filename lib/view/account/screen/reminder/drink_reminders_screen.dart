import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:water_intake/common/common_button.dart';

import '../../../../common/new_common_app_bar.dart';
import '../../../../gen/assets.gen.dart';
import 'package:water_intake/theme/app_fonts.dart';
import 'package:water_intake/theme/app_colors.dart';
import '../../../../utils/app_strings.dart';
import 'package:water_intake/theme/app_text_styles.dart';
import 'controller/drink_reminders_controller.dart';

class DrinkRemindersScreen extends StatelessWidget {
  const DrinkRemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DrinkRemindersController());

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: newCommonAppBar(
        centerTitle: false,
        title: AppString.drinkReminder.tr,
        onBack: () {
          Get.back();
        },
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          children: [
            SizedBox(height: 12.h),
            _buildMasterToggle(controller),
            SizedBox(height: 16.h),
            _buildRemindersCard(context, controller),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  Widget _buildMasterToggle(DrinkRemindersController controller) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.cardEdge),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            AppString.reminder.tr,
            style: TextStyle(
              fontSize: 14.sp,
              // fontWeight: FontWeight.w600,
              fontFamily: AppFonts.lato,
              color: const Color(0xff212529),
            ),
          ),
          Obx(
            () => _buildSwitch(
              value: controller.isReminderEnabled.value,
              onChanged: (val) => controller.toggleGlobalReminders(val),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemindersCard(
    BuildContext context,
    DrinkRemindersController controller,
  ) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.cardEdge),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppString.reminder.tr,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontFamily: AppFonts.lato,
                  color: const Color(0xff212529),
                ),
              ),
              GestureDetector(
                onTap: () => _showAddReminderBottomSheet(context, controller),
                child: Icon(Icons.add, color: AppColors.teal, size: 24.sp),
              ),
            ],
          ),
          SizedBox(height: 11.h),
          const Divider(color: Color(0xffE6E6E6)),
          Obx(
            () => controller.isLoading.value
                ? const Center(child: CupertinoActivityIndicator())
                : controller.reminders.isEmpty
                ? _buildEmptyRemindersState()
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: controller.reminders.length,
                    separatorBuilder: (context, index) => SizedBox(height: 3.h),
                    itemBuilder: (context, index) {
                      final item = controller.reminders[index];
                      return ReminderItem(
                        reminder: item,
                        onToggle: (val) => controller.toggleReminder(index),
                        onDelete: () => controller.deleteReminder(index),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyRemindersState() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Assets.images.png.time.image(scale: 3.1, color: Color(0xff333B47)),
          SizedBox(height: 2.h),
          Text(
            AppString.noReminderSet.tr,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              fontFamily: AppFonts.lato,
              color: const Color(0xff333B47),
            ),
          ),
          // SizedBox(height: 2.h),
          Text(
            AppString.tapToAddReminder.tr,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w400,
              fontFamily: AppFonts.lato,
              color: const Color(0xff6C757D),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddReminderBottomSheet(
    BuildContext context,
    DrinkRemindersController controller,
  ) {
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
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 12.h),
              // Header
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppString.addReminder.tr,
                      style: AppTextStyle.latoBoldBlack16.copyWith(
                        fontSize: 16.sp,
                        color: const Color(0xff344054),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: Icon(
                        Icons.close,
                        color: const Color(0xff8596AB),
                        size: 20.sp,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(color: Colors.grey.shade300, height: 30.h),
              // Toggle Buttons 12H/24H
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTimeFormatButton(
                    controller,
                    title: AppString.format12H.tr,
                    is12H: true,
                  ),
                  SizedBox(width: 16.w),
                  _buildTimeFormatButton(
                    controller,
                    title: AppString.format24H.tr,
                    is12H: false,
                  ),
                ],
              ),
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
                              controller.selectedHour.value = is12H
                                  ? index + 1
                                  : index;
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
                                  bool isSelected =
                                      controller.selectedHour.value ==
                                      hourValue;
                                  return _buildWheelItem(
                                    hourValue.toString().padLeft(2, '0'),
                                    isSelected,
                                  );
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
                            color: const Color(0xff212529),
                            fontFamily: AppFonts.lato,
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
                                  bool isSelected =
                                      controller.selectedMinute.value == index;
                                  return _buildWheelItem(
                                    index.toString().padLeft(2, '0'),
                                    isSelected,
                                  );
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
                                    bool isSelected =
                                        controller.isAm.value == isAmValue;
                                    String text = isAmValue
                                        ? AppString.am.tr
                                        : AppString.pm.tr;
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
              SizedBox(height: 10.h),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 20.h),
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
                        onPressed: () async {
                          String hourStr = controller.is12HourFormat.value
                              ? controller.selectedHour.value.toString()
                              : controller.selectedHour.value
                                    .toString()
                                    .padLeft(2, '0');
                          String minuteStr = controller.selectedMinute.value
                              .toString()
                              .padLeft(2, '0');
                          String amPmStr = controller.is12HourFormat.value
                              ? (controller.isAm.value ? 'am' : 'pm')
                              : '';

                          bool success = await controller.addReminder(
                            "$hourStr:$minuteStr",
                            amPm: amPmStr,
                          );
                          if (success) {
                            Get.back();
                          } else {
                            Get.snackbar(
                              AppString.info.tr,
                              AppString.reminderAlreadySet.tr,
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Buttons
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
      decoration: isSelected
          ? BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.cardEdge),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            )
          : null,
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 22.sp,
            color: isSelected
                ? AppColors.teal
                : const Color(0xff212529).withOpacity(0.5),
            fontWeight: FontWeight.w600,
            fontFamily: AppFonts.lato,
          ),
        ),
      ),
    );
  }

  Widget _buildTimeFormatButton(
    DrinkRemindersController controller, {
    required String title,
    required bool is12H,
  }) {
    return Obx(() {
      bool isSelected = controller.is12HourFormat.value == is12H;
      return GestureDetector(
        onTap: () => controller.is12HourFormat.value = is12H,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 15.w),
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

  Widget _buildSwitch({
    required bool value,
    required Function(bool) onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 46.w,
        height: 25.h,
        padding: EdgeInsets.symmetric(horizontal: 2.w),
        decoration: BoxDecoration(
          color: value ? AppColors.teal : const Color(0xffB0BBC9),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20.w,
            height: 20.w,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ReminderItem extends StatefulWidget {
  final reminder;
  final Function(bool) onToggle;
  final VoidCallback onDelete;

  const ReminderItem({
    super.key,
    required this.reminder,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  State<ReminderItem> createState() => _ReminderItemState();
}

class _ReminderItemState extends State<ReminderItem> {
  double offset = 0.0;

  @override
  Widget build(BuildContext context) {
    bool isSwiped = offset < 0;
    String timeStr = widget.reminder.time ?? "00:00";

    // --- Localization Logic ---
    String fullTime = timeStr;
    String displayFullTime = fullTime
        .replaceAll('AM', AppString.am.tr)
        .replaceAll('PM', AppString.pm.tr);
    String amPm = fullTime.endsWith('AM')
        ? AppString.am.tr
        : (fullTime.endsWith('PM') ? AppString.pm.tr : '');

    String? displayInterval = widget.reminder.interval;
    if (displayInterval != null) {
      if (displayInterval == 'Every 2 hours' ||
          displayInterval == '2 saatte bir' ||
          displayInterval.toLowerCase().contains("every 2 hours")) {
        displayInterval = AppString.everyTwoHours.tr;
      }
    }

    String finalTimeDisplay =
        (fullTime == '8 AM – 10 PM' ||
            fullTime == '08:00 – 22:00' ||
            (fullTime.contains("08:00") && fullTime.contains("10:00")))
        ? AppString.defaultTimeRange.tr
        : ((isSwiped && amPm.isNotEmpty) ? amPm : displayFullTime);
    // ---------------------------

    String amPmPart = "";
    if (timeStr.contains(" ")) {
      var parts = timeStr.split(" ");
      amPmPart = parts.length > 1 ? parts[1].tr : "";
    }

    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        setState(() {
          offset += details.delta.dx;
          if (offset > 0) offset = 0;
          if (offset < -50.w) offset = -50.w;
        });
      },
      onHorizontalDragEnd: (details) {
        setState(() {
          if (offset < -25.w) {
            offset = -50.w;
          } else {
            offset = 0;
          }
        });
      },
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          Padding(
            padding: EdgeInsets.only(right: 4.w),
            child: GestureDetector(
              onTap: widget.onDelete,
              child: Assets.images.png.delete1.image(scale: 3.5),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            transform: Matrix4.translationValues(offset, 0, 0),
            color: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSwiped
                          ? (amPm.isNotEmpty ? amPm : amPmPart)
                          : finalTimeDisplay,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        fontFamily: AppFonts.lato,
                        color: const Color(0xff212529),
                      ),
                    ),
                    if (displayInterval != null &&
                        !isSwiped &&
                        displayInterval.isNotEmpty)
                      Text(
                        displayInterval,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w400,
                          fontFamily: AppFonts.lato,
                          color: const Color(0xff8596AB),
                        ),
                      ),
                  ],
                ),
                _CommonSwitch(
                  value: widget.reminder.isEnabled ?? false,
                  onChanged: widget.onToggle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommonSwitch extends StatelessWidget {
  final bool value;
  final Function(bool) onChanged;

  const _CommonSwitch({required this.value, required Function(bool) onChanged})
    : onChanged = onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 46.w,
        height: 25.h,
        padding: EdgeInsets.symmetric(horizontal: 2.w),
        decoration: BoxDecoration(
          color: value ? AppColors.teal : const Color(0xffB0BBC9),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20.w,
            height: 20.w,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

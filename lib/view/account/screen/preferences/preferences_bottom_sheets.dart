import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:water_intake/utils/app_strings.dart';

import 'package:water_intake/theme/app_fonts.dart';
import '../../../../common/common_button.dart';
import 'package:water_intake/theme/app_colors.dart';
import 'controller/preferences_controller.dart';

class PreferencesBottomSheets {
  static void showInfoScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: const Color(0xffF8F9FB),
          appBar: AppBar(
            backgroundColor: const Color(0xffF8F9FB),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xff343A40)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              AppString.info.tr,
              style: TextStyle(color: const Color(0xff212529), fontSize: 16.sp, fontWeight: FontWeight.w600, fontFamily: AppFonts.lato),
            ),
            centerTitle: false,
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppString.dailyWaterIntakeInfo.tr,
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, fontFamily: AppFonts.lato, color: const Color(0xff212529)),
                ),
                SizedBox(height: 12.h),
                Text(
                  AppString.dailyWaterIntakeDesc.tr,
                  style: TextStyle(fontSize: 14.sp, fontFamily: AppFonts.lato, color: const Color(0xff6C757D), height: 1.5),
                ),
                SizedBox(height: 24.h),
                Text(
                  AppString.importantNote.tr,
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, fontFamily: AppFonts.lato, color: const Color(0xff212529)),
                ),
                SizedBox(height: 12.h),
                Text(
                  AppString.dailyWaterIntakeDesc.tr,
                  style: TextStyle(fontSize: 14.sp, fontFamily: AppFonts.lato, color: const Color(0xff6C757D), height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static void showSelectionBottomSheet({
    required BuildContext context,
    required String title,
    required List<String> options,
    required String currentValue,
    required Function(String) onSave,
    List<Widget>? icons,
    List<String>? descriptions,
  }) {
    String tempSelected = currentValue;

    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setState) {
          return Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, fontFamily: AppFonts.lato),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xffADB5BD)),
                      onPressed: () => Get.back(),
                    ),
                  ],
                  // SizedBox(height: 16.h),
                ),
                SizedBox(height: 10.h),

                Divider(height: 1, color: Colors.grey.shade400),
                SizedBox(height: 16.h),
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: 350.h),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      bool isSelected = tempSelected == options[index];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            tempSelected = options[index];
                          });
                        },
                        child: Container(
                          margin: EdgeInsets.only(bottom: 12.h),
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: descriptions != null ? 16.h : 12.h),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(color: isSelected ? AppColors.teal.withValues(alpha: 0.8) : Colors.grey.shade300, width: isSelected ? 1.5:1),
                          ),
                          child: Row(
                            children: [
                              if (icons != null) ...[icons[index], SizedBox(width: 16.w)],
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      options[index].tr,
                                      style: TextStyle(
                                        fontSize: 15.sp,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                        color: isSelected ? AppColors.teal : const Color(0xff212529),
                                        fontFamily: AppFonts.lato,
                                      ),
                                    ),
                                    if (descriptions != null && descriptions[index].isNotEmpty) ...[
                                      SizedBox(height: 4.h),
                                      Text(
                                        descriptions[index],
                                        style: TextStyle(fontSize: 12.sp, color: const Color(0xffADB5BD), fontFamily: AppFonts.lato),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              // if (isSelected && descriptions == null) const Icon(Icons.check_circle, color: Color(0xff4B9CFF), size: 24),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // SizedBox(height: 24.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
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
                          onPressed: () {
                            onSave(tempSelected);
                            Get.back();
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // SizedBox(height: 10.h),
              ],
            ),
          );
        },
      ),
      isScrollControlled: true,
    );
  }

  static void showWeightPickerBottomSheet(BuildContext context, PreferencesController controller) {
    int tempWeight = controller.weightValue.value;

    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setState) {
          return Container(
            padding: EdgeInsets.all(20.w),
            height: 400.h,
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
            ),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 40.w,
                    height: 4.h,
                    margin: EdgeInsets.only(bottom: 16.h),
                    decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2.r)),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppString.editWeight.tr,
                      style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, fontFamily: AppFonts.lato),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xffADB5BD)),
                      onPressed: () => Get.back(),
                    ),
                  ],
                  // SizedBox(height: 16.h),
                ),
                SizedBox(height: 5.h),

                Divider(height: 1, color: Colors.grey.shade400),
                SizedBox(height: 5.h),

                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: ListWheelScrollView.useDelegate(
                          controller: FixedExtentScrollController(initialItem: tempWeight - 30),
                          itemExtent: 50.h,
                          physics: const FixedExtentScrollPhysics(),
                          onSelectedItemChanged: (int index) {
                            setState(() {
                              tempWeight = index + 30;
                            });
                          },
                          childDelegate: ListWheelChildBuilderDelegate(
                            builder: (context, index) {
                              if (index < 0 || index > 270) return null;
                              int weightValue = index + 30;
                              bool isSelected = tempWeight == weightValue;
                              return Container(
                                width: 70.w,
                                padding: EdgeInsets.symmetric(vertical: 1.h),
                                decoration: isSelected
                                    ? BoxDecoration(color: AppColors.teal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10.r))
                                    : null,
                                child: Center(
                                  child: Text(
                                    weightValue.toString().padLeft(2, '0'),
                                    style: TextStyle(
                                      fontFamily: AppFonts.lato,
                                      fontSize: 24.sp,
                                      color: isSelected ? AppColors.teal : Color(0xffADB5BD),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              );
                            },
                            childCount: 271,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Obx(
                          () => Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () => controller.toggleWeightUnit('kg'),
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
                                  decoration: BoxDecoration(
                                    color: controller.weightUnit.value == 'kg' ? AppColors.teal.withValues(alpha: 0.1) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Text(
                                    'kg',
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: controller.weightUnit.value == 'kg' ? FontWeight.bold : FontWeight.normal,
                                      color: controller.weightUnit.value == 'kg' ? AppColors.teal : const Color(0xffADB5BD),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 8.h),
                              GestureDetector(
                                onTap: () => controller.toggleWeightUnit('lb'),
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
                                  decoration: BoxDecoration(
                                    color: controller.weightUnit.value == 'lb' ? AppColors.teal.withValues(alpha: 0.1) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Text(
                                    'lb',
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: controller.weightUnit.value == 'lb' ? FontWeight.bold : FontWeight.normal,
                                      color: controller.weightUnit.value == 'lb' ? AppColors.teal : const Color(0xffADB5BD),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
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
                          onPressed: () {
                            controller.updateWeightValue(tempWeight);
                            Get.back();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      isScrollControlled: true,
    );
  }

  static void showTimePickerBottomSheet({
    required BuildContext context,
    required String title,
    required String initialTime, // e.g., '08:00 AM' or '08:00'
    required Function(String) onSave,
  }) {
    // Parse initial time robustly
    int hour = 8;
    int minute = 0;
    String amPm = 'AM';
    bool is12H = true;

    try {
      if (initialTime.contains('AM') || initialTime.contains('PM') || initialTime.contains('ÖÖ') || initialTime.contains('ÖS')) {
        is12H = true;
        String cleanStr = initialTime.replaceAll('ÖÖ', 'AM').replaceAll('ÖS', 'PM');
        DateTime dt = DateFormat("hh:mm a").parse(cleanStr);
        hour = dt.hour;
        minute = dt.minute;
        if (hour >= 12) {
          amPm = 'PM';
          if (hour > 12) hour -= 12;
        } else {
          amPm = 'AM';
          if (hour == 0) hour = 12;
        }
      } else {
        is12H = false;
        DateTime dt = DateFormat("HH:mm").parse(initialTime);
        hour = dt.hour;
        minute = dt.minute;
        amPm = 'AM';
      }
    } catch (e) {
      print("Error parsing initial time: $e");
    }

    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setState) {
          return Container(
            padding: EdgeInsets.all(20.w),
            height: 480.h,
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
            ),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 40.w,
                    height: 4.h,
                    margin: EdgeInsets.only(bottom: 16.h),
                    decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2.r)),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        fontFamily: AppFonts.lato,
                        color: const Color(0xff212529),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xffADB5BD)),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),

                Divider(height: 1, color: Colors.grey.shade400),
                SizedBox(height: 20.h),
                // Toggle Buttons 12H/24H
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildTimeFormatButton(
                      title: AppString.format12H.tr,
                      isSelected: is12H,
                      onTap: () {
                        setState(() {
                          if (!is12H) {
                            is12H = true;
                            if (hour >= 12) {
                              if (hour > 12) hour -= 12;
                              amPm = 'PM';
                            } else {
                              if (hour == 0) hour = 12;
                              amPm = 'AM';
                            }
                          }
                        });
                      },
                    ),
                    SizedBox(width: 16.w),
                    _buildTimeFormatButton(
                      title: AppString.format24H.tr,
                      isSelected: !is12H,
                      onTap: () {
                        setState(() {
                          if (is12H) {
                            is12H = false;
                            if (amPm == 'PM' && hour < 12) hour += 12;
                            if (amPm == 'AM' && hour == 12) hour = 0;
                          }
                        });
                      },
                    ),
                  ],
                ),
                SizedBox(height: 30.h),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Hours Wheel
                      SizedBox(
                        width: 85.w,
                        child: ListWheelScrollView.useDelegate(
                          controller: FixedExtentScrollController(initialItem: is12H ? hour - 1 : hour),
                          itemExtent: 50.h,
                          physics: const FixedExtentScrollPhysics(),
                          onSelectedItemChanged: (index) {
                            setState(() {
                              hour = is12H ? index + 1 : index;
                            });
                          },
                          childDelegate: ListWheelChildBuilderDelegate(
                            builder: (context, index) {
                              if (is12H) {
                                if (index < 0 || index > 11) return null;
                              } else {
                                if (index < 0 || index > 23) return null;
                              }
                              int hourValue = is12H ? index + 1 : index;
                              bool isSelected = hour == hourValue;
                              return _buildWheelItem(hourValue.toString().padLeft(2, '0'), isSelected);
                            },
                            childCount: is12H ? 12 : 24,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        ':',
                        style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, color: const Color(0xff212529)),
                      ),
                      SizedBox(width: 8.w),
                      // Minutes Wheel
                      SizedBox(
                        width: 85.w,
                        child: ListWheelScrollView.useDelegate(
                          controller: FixedExtentScrollController(initialItem: minute),
                          itemExtent: 50.h,
                          physics: const FixedExtentScrollPhysics(),
                          onSelectedItemChanged: (index) {
                            setState(() {
                              minute = index;
                            });
                          },
                          childDelegate: ListWheelChildBuilderDelegate(
                            builder: (context, index) {
                              if (index < 0 || index > 59) return null;
                              bool isSelected = minute == index;
                              return _buildWheelItem(index.toString().padLeft(2, '0'), isSelected);
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
                            controller: FixedExtentScrollController(initialItem: amPm == 'AM' ? 0 : 1),
                            itemExtent: 50.h,
                            physics: const FixedExtentScrollPhysics(),
                            onSelectedItemChanged: (index) {
                              setState(() {
                                amPm = index == 0 ? 'AM' : 'PM';
                              });
                            },
                            childDelegate: ListWheelChildBuilderDelegate(
                              builder: (context, index) {
                                if (index < 0 || index > 1) return null;
                                String text = index == 0 ? AppString.amText.tr : AppString.pmText.tr;
                                bool isSelected = (index == 0 && amPm == 'AM') || (index == 1 && amPm == 'PM');
                                return _buildWheelItem(text, isSelected);
                              },
                              childCount: 2,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
                  child: Row(
                    children: [
                      Expanded(
                        child: CommonButton(
                          text: AppString.cancel.tr,
                          backgroundColor: AppColors.teal.withValues(alpha: 0.1),
                          textColor: AppColors.teal,
                          onPressed: () => Get.back(),
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: CommonButton(
                          text: AppString.save.tr,
                          backgroundColor: AppColors.teal,
                          textColor: AppColors.white,
                          onPressed: () {
                            String result;
                            if (is12H) {
                              result = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $amPm';
                            } else {
                              result = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
                            }
                            onSave(result);
                            Get.back();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      isScrollControlled: true,
    );
  }

  static Widget _buildWheelItem(String text, bool isSelected) {
    return Container(
      width: 70.w,
      padding: EdgeInsets.symmetric(vertical: 1.h),
      decoration: isSelected ? BoxDecoration(color: AppColors.teal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12.r)) : null,
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 22.sp,
            color: isSelected ? AppColors.teal : const Color(0xff212529).withOpacity(0.5),
            fontWeight: FontWeight.w600,
            fontFamily: AppFonts.lato,
          ),
        ),
      ),
    );
  }

  static Widget _buildTimeFormatButton({required String title, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 20.w),
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
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xff212529),
              fontSize: 16.sp,
              fontFamily: AppFonts.lato,
            ),
          ),
        ),
      ),
    );
  }
}

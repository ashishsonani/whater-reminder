import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:water_intake/gen/assets.gen.dart';

import '../../../../../common/new_common_app_bar.dart';
import 'package:water_intake/theme/app_fonts.dart';
import '../../../../../utils/app_strings.dart';
import '../../../../route/route.dart' show AppRoutes;
import 'package:water_intake/theme/app_colors.dart';
import 'controller/preferences_controller.dart';
import 'preferences_bottom_sheets.dart';

class PreferencesScreen extends StatelessWidget {
  const PreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PreferencesController>();

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: newCommonAppBar(
        centerTitle: false,
        title: AppString.preferences.tr,
        isDivider: false,
        onBack: () {
          Get.back();
        },
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.teal),
          );
        }
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            children: [
              SizedBox(height: 16.h),

              // Goal Section
              _buildSection([
                Obx(
                  () => _buildPreferenceTile(
                    icon: Assets.images.png.gc.image(
                      width: 24.w,
                      color: const Color(0xff495057),
                    ),
                    title: AppString.intakeGoal.tr,
                    value:
                        '${controller.intakeGoal.value} ${controller.intakeUnit.value}',
                    onTap: () {
                      Get.toNamed(AppRoutes.waterIntakeGoal);
                    },
                  ),
                ),
              ]),

              SizedBox(height: 16.h),

              // Units Section
              _buildSection([
                Obx(
                  () => _buildPreferenceTile(
                    icon: Assets.images.png.delivery.image(
                      width: 24.w,
                      color: const Color(0xff495057),
                    ),
                    title: AppString.cupUnits.tr,
                    value: controller.intakeUnit.value,
                    popupOptions: ['ml', 'oz'],
                    onPopupSelected: (val) => controller.toggleIntakeUnit(val),
                    onTap: () {},
                  ),
                ),
                Obx(
                  () => _buildPreferenceTile(
                    icon: Assets.images.png.gauge.image(
                      width: 24.w,
                      color: const Color(0xff495057),
                    ),
                    title: AppString.weightUnit.tr,
                    value: controller.weightUnit.value,
                    popupOptions: ['kg', 'lb'],
                    onPopupSelected: (val) => controller.toggleWeightUnit(val),
                    onTap: () {},
                  ),
                ),
              ]),

              SizedBox(height: 16.h),

              // Time Section
              _buildSection([
                Obx(
                  () => _buildPreferenceTile(
                    icon: Assets.images.png.timeNew.image(
                      width: 24.w,
                      color: const Color(0xff495057),
                    ),
                    title: AppString.timeFormat.tr,
                    value: controller.timeFormat.value == '12-hour'
                        ? AppString.format12Hour.tr
                        : AppString.format24Hour.tr,
                    popupOptions: [
                      AppString.format12Hour.tr,
                      AppString.format24Hour.tr,
                    ],
                    onPopupSelected: (val) => controller.updateTimeFormat(
                      val == AppString.format12Hour.tr ? '12-hour' : '24-hour',
                    ),
                    onTap: () {},
                  ),
                ),
                Obx(
                  () => _buildPreferenceTile(
                    icon: Assets.images.png.weather.image(
                      width: 24.w,
                      color: const Color(0xff495057),
                    ),
                    title: AppString.wakeUpTime.tr,
                    value: controller.getFormattedTime(
                      controller.wakeUpTime.value,
                    ),
                    onTap: () {
                      PreferencesBottomSheets.showTimePickerBottomSheet(
                        context: context,
                        title: AppString.wakeUpTime.tr,
                        initialTime: controller.wakeUpTime.value,
                        onSave: (val) => controller.updateWakeUpTime(val),
                      );
                    },
                  ),
                ),
                Obx(
                  () => _buildPreferenceTile(
                    icon: Assets.images.png.moon.image(
                      width: 24.w,
                      color: const Color(0xff495057),
                    ),
                    title: AppString.bedTime.tr,
                    value: controller.getFormattedTime(
                      controller.bedTime.value,
                    ),
                    onTap: () {
                      PreferencesBottomSheets.showTimePickerBottomSheet(
                        context: context,
                        title: AppString.bedTime.tr,
                        initialTime: controller.bedTime.value,
                        onSave: (val) => controller.updateBedTime(val),
                      );
                    },
                  ),
                ),
              ]),

              SizedBox(height: 16.h),

              // Reset Section
              _buildSection([
                _buildPreferenceTile(
                  icon: Assets.images.png.exchange.image(
                    width: 24.w,
                    color: const Color(0xff495057),
                  ),
                  title: AppString.resetAllTracking.tr,
                  trailing: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xffFEE2E2),
                      borderRadius: BorderRadius.circular(100.r),
                    ),
                    child: Text(
                      AppString.reset.tr,
                      style: TextStyle(
                        color: const Color(0xffFF3B30),
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w500,
                        fontFamily: AppFonts.lato,
                      ),
                    ),
                  ),
                  onTap: () {
                    _showResetDialog(context, controller);
                  },
                ),
              ]),

              // SizedBox(height: 24.h),
              //
              // // Ad Placeholder (AliExpress style from image)
              // Container(
              //   width: double.infinity,
              //   decoration: BoxDecoration(
              //     color: Colors.white,
              //     borderRadius: BorderRadius.circular(16.r),
              //     boxShadow: [
              //       BoxShadow(
              //         color: Colors.black.withOpacity(0.03),
              //         blurRadius: 10,
              //         offset: const Offset(0, 4),
              //       ),
              //     ],
              //   ),
              //   child: Column(
              //     crossAxisAlignment: CrossAxisAlignment.start,
              //     children: [
              //       ClipRRect(
              //         borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
              //         child: Stack(
              //           children: [
              //             Image.network(
              //               'https://picsum.photos/seed/ads/600/300',
              //               width: double.infinity,
              //               height: 160.h,
              //               fit: BoxFit.cover,
              //             ),
              //             Positioned(
              //               top: 8.h,
              //               right: 8.w,
              //               child: Container(
              //                 padding: EdgeInsets.all(4.w),
              //                 decoration: const BoxDecoration(
              //                   color: Colors.white,
              //                   shape: BoxShape.circle,
              //                 ),
              //                 child: Icon(Icons.info_outline, size: 14.w, color: Colors.blue),
              //               ),
              //             ),
              //           ],
              //         ),
              //       ),
              //       Padding(
              //         padding: EdgeInsets.all(12.w),
              //         child: Row(
              //           children: [
              //             Container(
              //               width: 40.w,
              //               height: 40.w,
              //               decoration: BoxDecoration(
              //                 color: Colors.red,
              //                 borderRadius: BorderRadius.circular(8.r),
              //               ),
              //               child: const Icon(Icons.shopping_bag, color: Colors.white),
              //             ),
              //             SizedBox(width: 12.w),
              //             Expanded(
              //               child: Column(
              //                 crossAxisAlignment: CrossAxisAlignment.start,
              //                 children: [
              //                   Row(
              //                     children: [
              //                       Container(
              //                         padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              //                         decoration: BoxDecoration(
              //                           border: Border.all(color: Colors.orange),
              //                           borderRadius: BorderRadius.circular(2.r),
              //                         ),
              //                         child: Text(
              //                           'Ad',
              //                           style: TextStyle(
              //                             color: Colors.orange,
              //                             fontSize: 8.sp,
              //                             fontWeight: FontWeight.bold,
              //                           ),
              //                         ),
              //                       ),
              //                       SizedBox(width: 4.w),
              //                       Text(
              //                         'AliExpress',
              //                         style: TextStyle(
              //                           color: const Color(0xff495057),
              //                           fontSize: 14.sp,
              //                           fontWeight: FontWeight.w600,
              //                           fontFamily: AppFonts.lato,
              //                         ),
              //                       ),
              //                     ],
              //                   ),
              //                 ],
              //               ),
              //             ),
              //             Container(
              //               padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
              //               decoration: BoxDecoration(
              //                 color: const Color(0xffFF8787),
              //                 borderRadius: BorderRadius.circular(8.r),
              //               ),
              //               child: Text(
              //                 'OPEN',
              //                 style: TextStyle(
              //                   color: Colors.white,
              //                   fontSize: 13.sp,
              //                   fontWeight: FontWeight.bold,
              //                 ),
              //               ),
              //             ),
              //           ],
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
              SizedBox(height: 40.h),
            ],
          ),
        );
      }),
    );
  }

  void _showResetDialog(
    BuildContext context,
    PreferencesController controller,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.paper,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Text(
          AppString.resetAllTracking.tr,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xff212529),
            fontFamily: AppFonts.lato,
          ),
        ),
        content: Text(
          AppString.areYouSureReset.tr,
          style: TextStyle(
            fontSize: 14.sp,
            color: const Color(0xff495057),
            fontFamily: AppFonts.lato,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppString.cancel.tr,
              style: TextStyle(
                color: AppColors.teal,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                fontFamily: AppFonts.lato,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              controller.resetAllTracking();
              Navigator.pop(context);
            },
            child: Text(
              AppString.reset.tr,
              style: TextStyle(
                color: const Color(0xffFF3B30),
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                fontFamily: AppFonts.lato,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.cardEdge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: children.asMap().entries.map((entry) {
          int idx = entry.key;
          Widget child = entry.value;
          return Column(
            children: [child, if (idx < children.length - 1) SizedBox()],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPreferenceTile({
    required Widget icon,
    required String title,
    String? value,
    Widget? trailing,
    List<String>? popupOptions,
    Function(String)? onPopupSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          icon,
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w500,
                fontFamily: AppFonts.lato,
                color: const Color(0xff212529),
              ),
            ),
          ),
          if (popupOptions != null)
            PopupMenuButton<String>(
              onSelected: onPopupSelected,
              offset: const Offset(0, 45),
              color: Colors.white,
              elevation: 4,
              itemBuilder: (context) => popupOptions
                  .map(
                    (opt) => PopupMenuItem(
                      value: opt,
                      padding: EdgeInsets.zero,
                      height: 40.h,
                      child: Container(
                        // width: 120.w,
                        height: 40.h,
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        decoration: BoxDecoration(
                          color: value == opt
                              ? AppColors.teal.withValues(alpha: 0.1)
                              : Colors.white,
                          border: Border.all(color: AppColors.cardEdge),
                        ),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          opt,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppColors.teal,
                            fontWeight: value == opt
                                ? FontWeight.bold
                                : FontWeight.w500,
                            fontFamily: AppFonts.lato,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value ?? '',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                      fontFamily: AppFonts.lato,
                      color: const Color(0xff969593),
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: 20.w,
                    color: const Color(0xffADB5BD),
                  ),
                ],
              ),
            )
          else
            InkWell(
              onTap: onTap,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (value != null)
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w400,
                        fontFamily: AppFonts.lato,
                        color: const Color(0xff969593),
                      ),
                    ),
                  if (trailing != null) trailing,
                  if (trailing == null) ...[
                    SizedBox(width: 8.w),
                    Icon(
                      Icons.keyboard_arrow_right,
                      size: 20.w,
                      color: const Color(0xffADB5BD),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

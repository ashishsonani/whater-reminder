import 'package:water_intake/common/curved_nav/curved_navigation_bar.dart';
import 'package:water_intake/common/curved_nav/curved_navigation_bar_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:water_intake/theme/app_colors.dart';
import 'package:water_intake/utils/app_strings.dart';
import 'package:water_intake/view/account/screen/account_screen.dart';
import 'package:water_intake/view/dashboard/controller/dashboard_controller.dart';
import 'package:water_intake/view/home/screen/history/water_intake_history_view.dart';
import 'package:water_intake/view/home/screen/home_screen.dart';

import '../../home/screen/statistic/screen/statistic_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();

    final List<Widget> screens = [
      const HomeScreen(),
      const WaterIntakeHistoryView(),
      const StatisticScreen(),
      const AccountScreen(),
    ];

    return WillPopScope(
      onWillPop: () async {
        final bool shouldPop = await _showExitDialog(context) ?? false;
        if (shouldPop) {
          SystemNavigator.pop();
        }
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColors.paper,
        body: Obx(
              () => IndexedStack(
            index: controller.selectedIndex.value,
            children: screens,
          ),
        ),
      bottomNavigationBar: Obx(
        () => SafeArea(
          top: false,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.tealBright,
                  AppColors.teal,
                  AppColors.tealDeep,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: CurvedNavigationBar(
              index: controller.selectedIndex.value,
              // Package geometry (floating button, notch curve) is calibrated
              // for heights <= ~75, so don't let tablet scaling exceed that.
              height: 60.h.clamp(60.0, 75.0),
              backgroundColor:Colors.transparent,
              color: Colors.white,
              buttonBackgroundColor: Colors.white,
              animationDuration: const Duration(milliseconds: 300),
              animationCurve: Curves.easeInOut,
              onTap: (index) {
                controller.changeIndex(index);
              },
              items: [
                CurvedNavigationBarItem(
                  child: SvgPicture.asset(
                    'assets/images/svg/house.svg',
                    width: 22.sp.clamp(22.0, 28.0),
                    height: 22.sp.clamp(22.0, 28.0),
                    colorFilter: ColorFilter.mode(
                      controller.selectedIndex.value == 0
                          ? AppColors.teal // Dark grey/black when selected
                          : AppColors.inkMute, // Softer grey when unselected
                      BlendMode.srcIn,
                    ),
                  ),
                  label: AppString.home.tr,
                  labelStyle: TextStyle(
                    fontFamily: 'Inter Tight',
                    fontSize: 10.sp.clamp(10.0, 12.0),
                    fontWeight: controller.selectedIndex.value == 0
                        ? FontWeight.w600
                        : FontWeight.w500,
                    color: controller.selectedIndex.value == 0
                        ? AppColors.teal
                        : AppColors.inkMute,
                    letterSpacing: 0.2,
                  ),
                ),
                CurvedNavigationBarItem(
                  child: SvgPicture.asset(
                    'assets/images/svg/file-text.svg',
                    width: 22.sp.clamp(22.0, 28.0),
                    height: 22.sp.clamp(22.0, 28.0),
                    colorFilter: ColorFilter.mode(
                      controller.selectedIndex.value == 1
                          ? AppColors.teal
                          : AppColors.inkMute,
                      BlendMode.srcIn,
                    ),
                  ),
                  label: AppString.history.tr,
                  labelStyle: TextStyle(
                    fontFamily: 'Inter Tight',
                    fontSize: 10.sp.clamp(10.0, 12.0),
                    fontWeight: controller.selectedIndex.value == 1
                        ? FontWeight.w600
                        : FontWeight.w500,
                    color: controller.selectedIndex.value == 1
                        ? AppColors.teal
                        : AppColors.inkMute,
                    letterSpacing: 0.2,
                  ),
                ),
                CurvedNavigationBarItem(
                  child: SvgPicture.asset(
                    'assets/images/svg/chart.svg',
                    width: 22.sp.clamp(22.0, 28.0),
                    height: 22.sp.clamp(22.0, 28.0),
                    colorFilter: ColorFilter.mode(
                      controller.selectedIndex.value == 2
                          ? AppColors.teal
                          : AppColors.inkMute,
                      BlendMode.srcIn,
                    ),
                  ),
                  label: AppString.statistics.tr,
                  labelStyle: TextStyle(
                    fontFamily: 'Inter Tight',
                    fontSize: 10.sp.clamp(10.0, 12.0),
                    fontWeight: controller.selectedIndex.value == 2
                        ? FontWeight.w600
                        : FontWeight.w500,
                    color: controller.selectedIndex.value == 2
                        ? AppColors.teal
                        : AppColors.inkMute,
                    letterSpacing: 0.2,
                  ),
                ),
                CurvedNavigationBarItem(
                  child: SvgPicture.asset(
                    'assets/images/svg/circle-user.svg',
                    width: 22.sp.clamp(22.0, 28.0),
                    height: 22.sp.clamp(22.0, 28.0),
                    colorFilter: ColorFilter.mode(
                      controller.selectedIndex.value == 3
                          ? AppColors.teal
                          : AppColors.inkMute,
                      BlendMode.srcIn,
                    ),
                  ),
                  label: AppString.account.tr,
                  labelStyle: TextStyle(
                    fontFamily: 'Inter Tight',
                    fontSize: 10.sp.clamp(10.0, 12.0),
                    fontWeight: controller.selectedIndex.value == 3
                        ? FontWeight.w600
                        : FontWeight.w500,
                    color: controller.selectedIndex.value == 3
                        ? AppColors.black2
                        : AppColors.inkMute,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

  Future<bool?> _showExitDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Text(
          'Exit App?',
          style: TextStyle(
            fontFamily: 'Inter Tight',
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.tealDeep,
          ),
        ),
        content: Text(
          'Are you sure you want to close the app?',
          style: TextStyle(
            fontFamily: 'Inter Tight',
            fontSize: 14.sp,
            fontWeight: FontWeight.w400,
            color: AppColors.black2,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'Inter Tight',
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.inkMute,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.teal,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Exit',
              style: TextStyle(
                fontFamily: 'Inter Tight',
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
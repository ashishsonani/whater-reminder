import 'package:curved_labeled_navigation_bar/curved_navigation_bar.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar_item.dart';
import 'package:flutter/material.dart';
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

    return Scaffold(
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
              height: 60.h,
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
                    width: 22.sp,
                    height: 22.sp,
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
                    fontSize: 10.sp,
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
                    width: 22.sp,
                    height: 22.sp,
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
                    fontSize: 10.sp,
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
                    width: 22.sp,
                    height: 22.sp,
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
                    fontSize: 10.sp,
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
                    width: 22.sp,
                    height: 22.sp,
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
                    fontSize: 10.sp,
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
    );
  }
}
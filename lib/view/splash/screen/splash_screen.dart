import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:water_intake/gen/assets.gen.dart';
import 'package:water_intake/theme/app_colors.dart';
import 'package:water_intake/utils/app_strings.dart';
import 'package:water_intake/view/splash/controlller/splash_controller.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize SplashController
    Get.put(SplashController());

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Logo at Center
          // Center(
          //   child: Assets.images.svg.splashLogo.svg(width: 100.w, height: 100.w),
          // ),
          Center(
            child: Assets.images.png.splashLogo.image(width: 150.w, height: 150.w),
          ),
          // Text at Bottom (50px from bottom)
          Positioned(
            bottom: 50.h,
            child: Text(
              AppString.waterIntake.tr,
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

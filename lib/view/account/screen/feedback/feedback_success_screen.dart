import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:water_intake/common/common_button.dart';
import 'package:water_intake/common/new_common_app_bar.dart' show newCommonAppBar;
import 'package:water_intake/utils/app_strings.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_text_styles.dart';

class FeedbackSuccessScreen extends StatelessWidget {
  const FeedbackSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: newCommonAppBar(backgroundColor: Colors.white, title: AppString.feedback.tr, centerTitle: false),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Container(
              width: 72.w,
              height: 72.w,
              decoration: const BoxDecoration(color: Color(0xffF0F7FF), shape: BoxShape.circle),
              child: Center(
                child: Icon(Icons.check_circle_outline_rounded, color: AppColors.primary, size: 40.sp),
              ),
            ),
            SizedBox(height: 28.h),
            Text(
              AppString.thanksForYourFeedback.tr,
              textAlign: TextAlign.center,
              style: AppTextStyle.latoBoldBlack16.copyWith(fontSize: 22.sp, color: const Color(0xff212529), fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10.h),
            Text(
              AppString.thanksForYourFeedbackDesc.tr,
              textAlign: TextAlign.center,
              style: AppTextStyle.latoRegularBlack14.copyWith(fontSize: 13.sp, color: const Color(0xff6C757D)),
            ),
            const Spacer(flex: 2),
            CommonButton(
              height: 45.h,
              backgroundColor: AppColors.primary,
              text: AppString.done.tr,
              textColor: Colors.white,
              onPressed: () => Get.back(),
              // borderRadius: 12.r,
            ),
            SizedBox(height: 10.h),
          ],
        ),
      ),
    );
  }
}

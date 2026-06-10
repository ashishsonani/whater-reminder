import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:water_intake/common/common_button.dart';
import 'package:water_intake/gen/assets.gen.dart';
import 'package:water_intake/theme/app_colors.dart';
import 'package:water_intake/utils/app_strings.dart';
import 'package:water_intake/theme/app_text_styles.dart';
import 'package:water_intake/view/on_board/controller/on_board_controller.dart';

class OnBoardingScreen extends StatelessWidget {
  const OnBoardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OnBoardController>();

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: controller.pageController,
              onPageChanged: controller.onPageChanged,
              children: [
                _buildPage(
                  image: Assets.images.png.onBoard.image(height: 250.h,width: 250.w),
                  title: AppString.onBoardTitle1.tr,
                  description: AppString.onBoardDesc1.tr,
                ),
                _buildPage(
                  image: Assets.images.png.onBoard2.image(height: 250.h,width: 250.w),
                  title: AppString.onBoardTitle2.tr,
                  description: AppString.onBoardDesc2.tr,
                ),
              ],
            ),
          ),

          // Indicator
          Obx(
            () => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(2, (index) => _buildIndicator(index == controller.currentPage.value)),
            ),
          ),

          SizedBox(height: 40.h),

          // Buttons
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Obx(
              () => controller.currentPage.value == 0
                  ? Row(
                      children: [
                        Expanded(
                          child: CommonButton(
                            text: AppString.skip.tr,
                            onPressed: () => controller.skip(),
                            backgroundColor: AppColors.teal.withValues(alpha: 0.1),
                            textColor: AppColors.teal,
                            textStyle: AppTextStyle.skipButton,
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: CommonButton(
                            text: AppString.continueText.tr,
                            textStyle: AppTextStyle.skipButton.copyWith(color: AppColors.white),
                            onPressed: () => controller.next(),
                          ),
                        ),
                      ],
                    )
                  : CommonButton(text: AppString.continueText.tr, onPressed: () => controller.next()),
            ),
          ),
          SizedBox(height: 40.h),
        ],
      ),
    );
  }

  Widget _buildPage({required Widget image, required String title, required String description}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 40.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Image Container
          Center(child: image),
          // SizedBox(height: 40.h),
          Text(title, style: AppTextStyle.h1, textAlign: TextAlign.center),
          SizedBox(height: 16.h),
          Text(description, style: AppTextStyle.body, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildIndicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      height: 8.h,
      width: isActive ? 24.w : 8.w,
      decoration: BoxDecoration(color: isActive ? AppColors.teal : AppColors.grey2, borderRadius: BorderRadius.circular(20.r)),
    );
  }
}

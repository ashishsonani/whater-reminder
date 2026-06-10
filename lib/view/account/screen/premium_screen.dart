import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:water_intake/gen/assets.gen.dart';
import 'package:water_intake/theme/app_colors.dart';
import 'package:water_intake/theme/app_text_styles.dart';

import '../../../utils/app_strings.dart';
import '../controller/account_controller.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AccountController>();

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Color(0xff8596AB),
                    size: 24,
                  ),
                  onPressed: () => Get.back(),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(5.w),

                        decoration: BoxDecoration(
                          color: AppColors.teal.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Assets.images.png.king.image(scale: 14),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        AppString.upgradeToPremium.tr,
                        textAlign: TextAlign.center,
                        style: AppTextStyle.latoBoldBlack16.copyWith(
                          fontSize: 22.sp,
                          color: AppColors.black1,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        AppString.premiumSubtitle.tr,
                        textAlign: TextAlign.center,
                        style: AppTextStyle.latoRegularBlack14.copyWith(
                          fontSize: 13.sp,
                          color: AppColors.grey4,
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: 24.h),
                      _buildPremiumFeature(
                        Assets.images.png.bottle.image(
                          scale: 3.5,
                          color: AppColors.teal,
                        ),
                        AppString.moreDrinkTypes.tr,
                        AppString.moreDrinkTypesDesc.tr,
                      ),
                      _buildPremiumFeature(
                        Assets.images.png.exit.image(
                          scale: 3.5,
                          color: AppColors.teal,
                        ),
                        AppString.noAds.tr,
                        AppString.noAdsDesc.tr,
                      ),
                      _buildPremiumFeature(
                        Assets.images.png.time.image(
                          scale: 4,
                          color: AppColors.teal,
                        ),
                        AppString.smartReminders.tr,
                        AppString.smartRemindersDesc.tr,
                      ),
                      _buildPremiumFeature(
                        Assets.images.png.primiu.image(
                          scale: 4,
                          color: AppColors.teal,
                        ),
                        AppString.premiumInsights.tr,
                        AppString.premiumInsightsDesc.tr,
                      ),

                      SizedBox(height: 30.h),
                      Text(
                        AppString.startYourFreeTrial.tr,
                        style: AppTextStyle.latoBoldBlack16.copyWith(
                          fontSize: 20.sp,
                          color: AppColors.black1,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 24.h),
                      _buildPlanCard(
                        0,
                        AppString.weekly.tr,
                        "\$1.00",
                        "\$0.50",
                        AppString.perWeek.tr,
                        AppString.save50.tr,
                        controller,
                      ),
                      SizedBox(height: 16.h),
                      _buildPlanCard(
                        1,
                        AppString.monthly.tr,
                        "\$4.00",
                        "\$1.00",
                        AppString.perMonth.tr,
                        AppString.save75.tr,
                        controller,
                      ),
                      SizedBox(height: 16.h),
                      _buildPlanCard(
                        2,
                        AppString.yearly.tr,
                        "\$52.00",
                        "\$10.00",
                        AppString.perYear.tr,
                        AppString.save80.tr,
                        controller,
                      ),
                      SizedBox(height: 30.h),

                      SizedBox(
                        width: double.infinity,
                        height: 45.h,
                        child: ElevatedButton(
                          onPressed: () {
                            Get.back();
                            // final iapService = IAPService.to;
                            // String productId = '';
                            // if (controller.selectedPlan.value == 0) {
                            //   productId = 'water_premium_weekly';
                            // } else if (controller.selectedPlan.value == 1) {
                            //   productId = 'water_premium_monthly';
                            // } else if (controller.selectedPlan.value == 2) {
                            //   productId = 'water_premium_yearly';
                            // }
                            //
                            // final product = iapService.products.where((p) => p.id == productId).firstOrNull;
                            // if (product != null) {
                            //   iapService.buyProduct(product);
                            // } else {
                            //   Get.snackbar("Error", "Product not found. Please try again later.", snackPosition: SnackPosition.BOTTOM);
                            // }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.teal,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.r),
                            ),
                            elevation: 0,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                AppString.startFreeTrial.tr,
                                style: AppTextStyle.latoBoldWhite16.copyWith(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Obx(() {
                                int selected = controller.selectedPlan.value;
                                String sub = "";
                                if (selected == 0)
                                  sub = AppString.first3dFree.tr;
                                else if (selected == 1)
                                  sub = AppString.first7dFree.tr;
                                else if (selected == 2)
                                  sub = AppString.first15dFree.tr;
                                return Text(
                                  sub,
                                  style: AppTextStyle.latoRegularBlack14
                                      .copyWith(
                                        fontSize: 11.sp,
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                      // SizedBox(height: 12.h),
                      // GestureDetector(
                      //   onTap: () => IAPService.to.restorePurchases(),
                      //   child: Text(
                      //     "Restore Purchase",
                      //     style: AppTextStyle.latoRegularBlack14.copyWith(
                      //       fontSize: 12.sp,
                      //       color: AppColors.primary,
                      //       fontWeight: FontWeight.w600,
                      //     ),
                      //   ),
                      // ),
                      SizedBox(height: 12.h),
                      Text(
                        AppString.autoRenewable.tr,
                        style: AppTextStyle.latoRegularBlack14.copyWith(
                          fontSize: 11.sp,
                          color: AppColors.teal,
                        ),
                      ),

                      SizedBox(height: 15.h),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumFeature(Widget iconWidget, String title, String desc) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: iconWidget,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyle.latoRegularBlack14.copyWith(
                    fontSize: 14.sp,
                    color: AppColors.black1,
                  ),
                ),
                Text(
                  desc,
                  style: AppTextStyle.latoRegularBlack14.copyWith(
                    fontSize: 12.sp,
                    color: AppColors.grey5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(
    int index,
    String title,
    String oldPrice,
    String price,
    String period,
    String saveText,
    AccountController controller,
  ) {
    return Obx(() {
      bool isSelected = controller.selectedPlan.value == index;

      // Get real price from IAPService
      String productId = '';
      if (index == 0) {
        productId = 'water_premium_weekly';
      } else if (index == 1) {
        productId = 'water_premium_monthly';
      } else if (index == 2) {
        productId = 'water_premium_yearly';
      }

      // final product = IAPService.to.products.where((p) => p.id == productId).firstOrNull;

      return GestureDetector(
        onTap: () {
          controller.setPlan(index);
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              decoration: isSelected
                  ? BoxDecoration(
                  color: Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: AppColors.teal, width: 1.5),
                      boxShadow: [
                              BoxShadow(
                                color: AppColors.teal.withValues(alpha: 0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                    )
                  : BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: Colors.grey.shade200,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
              child: Row(
                children: [
                  Icon(
                    isSelected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: isSelected
                        ? AppColors.teal
                        : const Color(0xffADB5BD),
                    size: 24.sp,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTextStyle.latoRegularBlack14.copyWith(
                            fontSize: 14.sp,
                            color: AppColors.black1,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Row(
                          children: [
                            Text(
                              oldPrice,
                              style: AppTextStyle.latoRegularBlack14.copyWith(
                                fontSize: 12.sp,
                                color: const Color(0xffADB5BD),
                                decoration: TextDecoration.lineThrough,
                                decorationColor: const Color(0xffADB5BD),
                              ),
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              price,
                              style: AppTextStyle.latoBoldBlack16.copyWith(
                                fontSize: 12.sp,
                                color: AppColors.black1,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        price,
                        style: AppTextStyle.latoBoldBlack16.copyWith(
                          fontSize: 16.sp,
                          color: AppColors.black1,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        " $period",
                        style: AppTextStyle.latoBoldBlack16.copyWith(
                          fontSize: 16.sp,
                          color: AppColors.black1,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isSelected)
              Positioned(
                top: -10.h,
                right: 20.w,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xffFEE2E2),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    saveText,
                    style: AppTextStyle.latoBoldWhite16.copyWith(
                      fontSize: 10.sp,
                      color: Color(0xffFF3B30),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}

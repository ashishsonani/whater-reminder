import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:water_intake/gen/assets.gen.dart';
import 'package:water_intake/theme/app_colors.dart';
import 'package:water_intake/theme/app_text_styles.dart';
import 'package:water_intake/utils/app_strings.dart';

import '../../../route/route.dart';
import '../../../services/ad_service.dart';
import '../../home/widget/water_widgets.dart';
import '../controller/account_controller.dart';
import '../widget/language_selection_bottom_sheet.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AccountController());

    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.paper,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Text(
            AppString.account.tr,
            style: AppTextStyle.latoMediumBlack14.copyWith(fontSize: 16.sp, color: AppColors.black1, fontWeight: FontWeight.w600),
          ),
        ),
        centerTitle: false,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            children: [
              SizedBox(height: 10.h),
              _buildSection([
                _buildTile(
                  icon: Assets.images.png.location.image(scale: 3.5, color: const Color(0xff475467)),
                  title: AppString.language.tr,
                  trailing: Obx(
                    () => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          controller.selectedLanguage.value,
                          style: AppTextStyle.latoRegularBlack14.copyWith(color: const Color(0xff969593), fontSize: 13.sp),
                        ),
                        SizedBox(width: 4.w),
                        Icon(Icons.chevron_right, size: 18.sp, color: const Color(0xffD0D5DD)),
                      ],
                    ),
                  ),
                  onTap: () => _showLanguageBottomSheet(context, controller),
                ),
                _buildTile(
                  icon: Assets.images.png.bell.image(scale: 3.5, color: const Color(0xff475467)),
                  title: AppString.notification.tr,
                  trailing: Obx(
                    () => CupertinoSwitch(
                      activeColor: AppColors.teal,
                      value: controller.isNotificationEnabled.value,
                      onChanged: (val) => controller.toggleNotifications(val),
                    ),
                  ),
                ),
                _buildTile(
                  icon: Assets.images.png.king.image(scale: 3.5, color: const Color(0xff475467)),
                  title: AppString.upgradeToPremium.tr,
                  onTap: () => Get.toNamed(AppRoutes.premium),
                ),
              ]),
              SizedBox(height: 20.h),
              _buildSection([
                _buildTile(
                  icon: Assets.images.png.time.image(scale: 3.5, color: const Color(0xff475467)),
                  title: AppString.drinkReminder.tr,
                  onTap: () => Get.toNamed(AppRoutes.drinkReminders),
                ),
                _buildTile(
                  icon: Assets.images.png.setting.image(scale: 3.5, color: const Color(0xff475467)),
                  title: AppString.preferences.tr,
                  onTap: () => Get.toNamed(AppRoutes.preferences),
                ),
              ]),
              SizedBox(height: 20.h),
              _buildSection([
                _buildTile(
                  icon: Assets.images.png.money.image(scale: 3.5, color: const Color(0xff475467)),
                  title: AppString.termsAndConditions.tr,
                  onTap: () => Get.toNamed(AppRoutes.termsAndConditions),
                ),
                _buildTile(
                  icon: Assets.images.png.privercy.image(scale: 3.5, color: const Color(0xff475467)),
                  title: AppString.privacyPolicy.tr,
                  onTap: () => Get.toNamed(AppRoutes.privacyPolicy),
                ),
              ]),
              SizedBox(height: 20.h),
              _buildSection([
                _buildTile(
                  icon: Assets.images.png.emailMessage.image(scale: 3.5, color: const Color(0xff475467)),
                  title: AppString.sendFeedback.tr,
                  onTap: () {
                    Get.dialog(const StarRatingDialog(), barrierColor: Colors.black.withOpacity(0.5), barrierDismissible: false);
                  },
                ),
                _buildTile(
                  icon: Assets.images.png.star.image(scale: 3.5, color: const Color(0xff475467)),
                  title: AppString.rateUs.tr,
                  onTap: () async {
                    String url = "";
                    if (GetPlatform.isAndroid) {
                      url = "https://play.google.com/store/apps/details?id=com.codelineinfotech.waterintake";
                    } else {
                      url = "https://apps.apple.com/us/app/drink-water-remainder/id6766213522";
                    }
                    final Uri uri = Uri.parse(url);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                ),
                _buildTile(
                  icon: Assets.images.png.share.image(scale: 3.5, color: const Color(0xff475467)),
                  title: AppString.shareApp.tr,
                  onTap: () {
                    String message = AppString.shareAppMessage.tr;
                    if (GetPlatform.isAndroid) {
                      message += "https://play.google.com/store/apps/details?id=com.codelineinfotech.waterintake";
                    } else {
                      message += "https://apps.apple.com/us/app/drink-water-remainder/id6766213522";
                    }
                    Share.share(message);
                  },
                ),
              ]),
              SizedBox(height: 15.h),
              const CommonNativeAd(),
              SizedBox(height: 10.h),
              Text(
                "${AppString.version.tr} 1.0.3",
                style: AppTextStyle.latoRegularBlack14.copyWith(color: AppColors.teal, fontSize: 12.sp),
              ),
              SizedBox(height: 30.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: AppColors.cardEdge),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Column(children: children),
    );
  }

  Widget _buildTile({required Widget icon, required String title, Widget? trailing, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        child: Row(
          children: [
            SizedBox(
              width: 24.w,
              height: 24.w,
              child: Center(child: icon),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                title,
                style: AppTextStyle.latoRegularBlack14.copyWith(
                  fontSize: 14.sp,
                  color: const Color(0xff212529),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (trailing != null) trailing else Icon(Icons.chevron_right, size: 18.sp, color: const Color(0xffD0D5DD)),
          ],
        ),
      ),
    );
  }

  void _showLanguageBottomSheet(BuildContext context, AccountController controller) {
    Get.bottomSheet(const LanguageSelectionBottomSheet(), isScrollControlled: true);
  }
}

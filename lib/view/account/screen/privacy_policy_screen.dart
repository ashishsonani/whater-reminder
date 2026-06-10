import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:water_intake/common/new_common_app_bar.dart';
import 'package:water_intake/theme/app_colors.dart';
import 'package:water_intake/utils/app_strings.dart';
import 'package:water_intake/theme/app_text_styles.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: newCommonAppBar(title: AppString.privacyPolicy.tr, centerTitle: false, showBack: true, onBack: () => Get.back()),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(left: 24.w, right: 24.w, bottom: 24.w, top: 10.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(AppString.privacyPolicyTitle.tr, AppString.privacyPolicyIntro.tr),
              _buildSection(AppString.infoNotCollectTitle.tr, AppString.infoNotCollectContent.tr),
              _buildSection(AppString.personalInfoTitle.tr, AppString.personalInfoContent.tr),
              _buildSection(AppString.analyticsTitle.tr, AppString.analyticsContent.tr),
              _buildSection(AppString.dataExportTitle.tr, AppString.dataExportContent.tr),
              _buildSection(AppString.thirdPartyIntegrationsTitle.tr, AppString.thirdPartyIntegrationsContent.tr),
              _buildSection(AppString.childrenPrivacyTitle.tr, AppString.childrenPrivacyContent.tr),
              _buildSection(AppString.advertisingTitle.tr, AppString.advertisingContent.tr),
              _buildSection(AppString.googleApiComplianceTitle.tr, AppString.googleApiComplianceContent.tr),
              _buildSection(AppString.medicalDisclaimerTitle.tr, AppString.medicalDisclaimerContent.tr),
              _buildSection(AppString.contactUsTitle.tr, AppString.contactUsContent.tr),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty) ...[
          Text(
            title,
            style: AppTextStyle.latoBoldPrimary16.copyWith(fontSize: 14.sp, color: const Color(0xff212529), fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 10.h),
        ],
        Text.rich(
          TextSpan(
            style: AppTextStyle.latoRegularBlack14.copyWith(fontSize: 14.sp, color: const Color(0xff8596AB), height: 1.5),
            children: _parseTextWithBold(
              content,
              AppTextStyle.latoRegularBlack14.copyWith(fontSize: 14.sp, color: const Color(0xff212529), fontWeight: FontWeight.w600),
            ),
          ),
          textAlign: TextAlign.justify,
        ),
        SizedBox(height: 15.h),
      ],
    );
  }

  List<TextSpan> _parseTextWithBold(String text, TextStyle boldStyle) {
    final List<TextSpan> spans = [];
    final RegExp regex = RegExp(r'\*\*(.*?)\*\*');
    int lastMatchEnd = 0;

    for (final Match match in regex.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(text: text.substring(lastMatchEnd, match.start)));
      }
      spans.add(TextSpan(text: match.group(1), style: boldStyle));
      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastMatchEnd)));
    }

    return spans;
  }
}

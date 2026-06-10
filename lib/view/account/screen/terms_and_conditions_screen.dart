import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:water_intake/common/new_common_app_bar.dart';
import 'package:water_intake/theme/app_colors.dart';
import 'package:water_intake/utils/app_strings.dart';
import 'package:water_intake/theme/app_text_styles.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: newCommonAppBar(
        backgroundColor: AppColors.paper,
        title: AppString.termsAndConditions.tr,
        centerTitle: false,
        showBack: true,
        onBack: () => Get.back(),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            left: 24.w,
            right: 24.w,
            bottom: 24.w,
            top: 10.h,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  style: AppTextStyle.latoRegularBlack14.copyWith(
                    fontSize: 14.sp,
                    color: const Color(0xff8596AB),
                    height: 1.5,
                  ),
                  children: _parseTextWithBold(
                    AppString.termsIntro.tr,
                    AppTextStyle.latoRegularBlack14.copyWith(
                      fontSize: 14.sp,
                      color: const Color(0xff212529),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                textAlign: TextAlign.justify,
              ),
              SizedBox(height: 15.h),
              _buildSection(
                AppString.termsSection1Title.tr,
                AppString.termsSection1Content.tr,
              ),
              _buildSection(
                AppString.termsSection2Title.tr,
                AppString.termsSection2Content.tr,
              ),
              _buildSection(
                AppString.termsSection3Title.tr,
                AppString.termsSection3Content.tr,
              ),
              _buildSection(
                AppString.termsSection4Title.tr,
                AppString.termsSection4Content.tr,
              ),
              _buildSection(
                AppString.termsSection5Title.tr,
                AppString.termsSection5Content.tr,
              ),
              _buildSection(
                AppString.termsSection6Title.tr,
                AppString.termsSection6Content.tr,
              ),
              _buildSection(
                AppString.termsSection7Title.tr,
                AppString.termsSection7Content.tr,
              ),
              _buildSection(
                AppString.termsSection8Title.tr,
                AppString.termsSection8Content.tr,
              ),
              _buildSection(
                AppString.termsSection9Title.tr,
                AppString.termsSection9Content.tr,
              ),
              _buildSection(
                AppString.termsSection10Title.tr,
                AppString.termsSection10Content.tr,
              ),
              _buildSection(
                AppString.termsSection11Title.tr,
                AppString.termsSection11Content.tr,
              ),
              _buildSection(
                AppString.termsSection12Title.tr,
                AppString.termsSection12Content.tr,
              ),
              _buildSection(
                AppString.termsSection13Title.tr,
                AppString.termsSection13Content.tr,
              ),
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
            style: AppTextStyle.latoBoldPrimary16.copyWith(
              fontSize: 14.sp,
              color: const Color(0xff212529),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 10.h),
        ],
        Text.rich(
          TextSpan(
            style: AppTextStyle.latoRegularBlack14.copyWith(
              fontSize: 14.sp,
              color: const Color(0xff8596AB),
              height: 1.5,
            ),
            children: _parseTextWithBold(
              content,
              AppTextStyle.latoRegularBlack14.copyWith(
                fontSize: 14.sp,
                color: const Color(0xff212529),
                fontWeight: FontWeight.w600,
              ),
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

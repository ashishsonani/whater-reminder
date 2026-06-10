import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../common/new_common_app_bar.dart';
import '../../../utils/app_strings.dart';
import 'package:water_intake/theme/app_text_styles.dart' show AppTextStyle;

class RecommendedInfoView extends StatelessWidget {
  const RecommendedInfoView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: newCommonAppBar(title: AppString.recommendedInfo.tr, centerTitle: false, showBack: true, onBack: () => Get.back()),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(left: 24.w, right: 24.w, bottom: 24.w, top: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppString.dailyWaterIntakeInformation.tr,
                style: AppTextStyle.latoBoldPrimary16.copyWith(
                  fontSize: 14.sp,
                  color: const Color(0xff212529),
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                AppString.dailyWaterIntakeInformationDetails.tr,
                textAlign: TextAlign.justify,
                style: AppTextStyle.latoRegularBlack14.copyWith(fontSize: 14.sp, color: const Color(0xff8596AB), height: 1.5),
              ),
              SizedBox(height: 15.h),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppString.recommendedDailyWaterIntakeByWeight.tr,
                    style: AppTextStyle.latoBoldPrimary16.copyWith(
                      fontSize: 14.sp,
                      color: const Color(0xff212529),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    AppString.weightIntakeList.tr,
                    textAlign: TextAlign.justify,
                    style: AppTextStyle.latoRegularBlack14.copyWith(fontSize: 13.sp, color: const Color(0xff8596AB), height: 1.8),
                  ),
                ],
              ),
              // SizedBox(height: 16.h),
              // const Divider(color: Color(0xffEAECF0)),
              SizedBox(height: 16.h),
              Text(
                AppString.importantNote.tr,
                style: AppTextStyle.latoBoldPrimary16.copyWith(
                  fontSize: 14.sp,
                  color: const Color(0xff212529),
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                AppString.importantNoteDetails.tr,
                textAlign: TextAlign.justify,
                style: AppTextStyle.latoRegularBlack14.copyWith(
                  fontSize: 13.sp,
                  color: const Color(0xff8596AB),
                  // height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

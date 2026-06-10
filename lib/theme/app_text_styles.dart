import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:water_intake/theme/app_colors.dart';
import 'package:water_intake/theme/app_fonts.dart';

class AppTextStyle {
  static const String fontFamily = 'Segoe UI';

  static TextStyle h1 = TextStyle(fontFamily: fontFamily, fontSize: 21.sp, fontWeight: FontWeight.bold, color: AppColors.black2);

  static TextStyle h2 = TextStyle(fontFamily: fontFamily, fontSize: 20.sp, fontWeight: FontWeight.bold, color: AppColors.black);

  static TextStyle body = TextStyle(fontFamily: fontFamily, fontSize: 13.sp, fontWeight: FontWeight.normal, color: AppColors.grey1);

  static TextStyle button = TextStyle(fontFamily: fontFamily, fontSize: 14.sp, fontWeight: FontWeight.w600, color: AppColors.white);

  static TextStyle skipButton = TextStyle(fontFamily: fontFamily, fontSize: 14.sp, fontWeight: FontWeight.w600, color: AppColors.primary);

  // Lato Font Family
  // static const String latoFontFamily = 'Lato';

  // Example of common text style based on the requested naming convention
  static TextStyle f10W400C23 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10.sp,
    fontWeight: FontWeight.w400,
    color: const Color(0xFF232323),
  );

  static TextStyle mediumWhite12 = TextStyle(
    fontSize: 12,
    color: AppColors.white,
    fontWeight: AppFontWeight.MEDIUM,
    fontFamily: fontFamily,
  );
  static TextStyle mediumAppColor12 = const TextStyle(
    fontSize: 12,
    color: AppColors.primary,
    fontWeight: AppFontWeight.MEDIUM,
    fontFamily: fontFamily,
  );
  static TextStyle mediumWhite16 = TextStyle(
    fontSize: 16,
    color: AppColors.white,
    fontWeight: AppFontWeight.MEDIUM,
    fontFamily: fontFamily,
  );
  static TextStyle mediumBlack18 = TextStyle(
    fontSize: 18,
    color: AppColors.black,
    fontWeight: AppFontWeight.MEDIUM,
    fontFamily: fontFamily,
  );
  static TextStyle regularBlack18 = TextStyle(
    fontSize: 18,
    color: AppColors.black,
    fontWeight: AppFontWeight.REGULAR,
    fontFamily: fontFamily,
  );
  static TextStyle boldBlack18 = TextStyle(fontSize: 18, color: AppColors.black, fontWeight: AppFontWeight.BOLD, fontFamily: fontFamily);
  static TextStyle mediumPink18 = TextStyle(
    fontSize: 18,
    color: AppColors.pinkDarkColor,
    fontWeight: AppFontWeight.MEDIUM,
    fontFamily: fontFamily,
  );
  static TextStyle boldPrimary22Intel = TextStyle(
    fontSize: 22,
    color: AppColors.primary,
    fontWeight: AppFontWeight.BOLD,
    fontFamily: fontFamily,
  );

  ///
  /// Product Sans

  static TextStyle regularBlack14ProductSans = TextStyle(
    fontSize: 14,
    color: AppColors.black,
    fontWeight: AppFontWeight.REGULAR,
    fontFamily: fontFamily,
  );

  /// poppins

  static TextStyle mediumBlack18Poppins = TextStyle(
    fontSize: 18,
    color: AppColors.black,
    fontWeight: AppFontWeight.MEDIUM,
    fontFamily: fontFamily,
  );
  static TextStyle boldBlack18Poppins = TextStyle(
    fontSize: 18,
    color: AppColors.black,
    fontWeight: AppFontWeight.BOLD,
    fontFamily: fontFamily,
  );
  static TextStyle white14w600Poppins = TextStyle(
    fontSize: 14,
    color: AppColors.white,
    fontWeight: AppFontWeight.W600,
    fontFamily: fontFamily,
  );
  static TextStyle white16BoldPoppins = TextStyle(
    fontSize: 16,
    color: AppColors.white,
    fontWeight: AppFontWeight.BOLD,
    fontFamily: fontFamily,
  );

  /// NEW FONT STYLES
  ///

  /// FOR TITLES AND HEADERS
  static TextStyle primary20AvenirBold = TextStyle(
    fontSize: 20,
    color: AppColors.primary,
    fontWeight: AppFontWeight.EXTRA_BOLD,
    fontFamily: fontFamily,
    height: 1.75,
    wordSpacing: 2.0,
    letterSpacing: 0.25,
  );
  static TextStyle primary18AvenirBold = TextStyle(
    fontSize: 18,
    color: AppColors.primary,
    fontWeight: AppFontWeight.EXTRA_BOLD,
    fontFamily: fontFamily,
    height: 1.75,
    wordSpacing: 2.0,
    letterSpacing: 0.25,
  );
  static TextStyle primary16AvenirMedium = TextStyle(
    fontSize: 16,
    color: AppColors.primary,
    fontWeight: AppFontWeight.MEDIUM,
    fontFamily: fontFamily,
    height: 1.75,
    wordSpacing: 1.5,
    letterSpacing: 0.25,
  );
  static TextStyle primary14AvenirMedium = TextStyle(
    fontSize: 14,
    color: AppColors.primary,
    fontWeight: AppFontWeight.MEDIUM,
    fontFamily: fontFamily,
    height: 1.75,
    wordSpacing: 2.0,
    letterSpacing: 0.25,
  );

  static TextStyle white18AvenirMedium = TextStyle(
    fontSize: 16,
    color: AppColors.white,
    fontWeight: AppFontWeight.MEDIUM,
    fontFamily: fontFamily,
    // // height: 1.75,
    // wordSpacing: 2.0,
    // letterSpacing: 0.25,
  );
  static TextStyle white18AvenirBold = TextStyle(
    fontSize: 18,
    color: AppColors.white,
    fontWeight: AppFontWeight.BOLD,
    fontFamily: fontFamily,
    height: 1.75,
    wordSpacing: 2.0,
    letterSpacing: 0.25,
  );

  /// FOR REGULAR TEXT
  static TextStyle black14AvenirMedium = TextStyle(
    fontSize: 14,
    color: AppColors.black,
    fontWeight: AppFontWeight.MEDIUM,
    fontFamily: fontFamily,
    height: 1.75,
    wordSpacing: 2.0,
    letterSpacing: 0.50,
  );
  static TextStyle black16AvenirMedium = TextStyle(
    fontSize: 16,
    color: AppColors.black,
    fontWeight: AppFontWeight.MEDIUM,
    fontFamily: fontFamily,
    height: 1.75,
    wordSpacing: 1.2,
    letterSpacing: 0.50,
  );
  static TextStyle black18AvenirMedium = TextStyle(
    fontSize: 18,
    color: AppColors.black,
    fontWeight: AppFontWeight.MEDIUM,
    fontFamily: fontFamily,
    // height: 1.75,
    // wordSpacing: 1.2,
    // letterSpacing: 0.50,
  );

  static TextStyle grey14AvenirMedium = TextStyle(
    fontSize: 14,
    color: AppColors.greyFontColor,
    fontWeight: AppFontWeight.MEDIUM,
    fontFamily: fontFamily,
    height: 1.75,
    wordSpacing: 2.0,
    letterSpacing: 0.50,
  );
  static TextStyle grey16AvenirMedium = TextStyle(
    fontSize: 16,
    color: AppColors.greyFontColor,
    fontWeight: AppFontWeight.MEDIUM,
    fontFamily: fontFamily,
    height: 1.75,
    wordSpacing: 2.0,
    letterSpacing: 0.50,
  );
  static TextStyle grey18AvenirMedium = TextStyle(
    fontSize: 18,
    color: AppColors.greyFontColor,
    fontWeight: AppFontWeight.MEDIUM,
    fontFamily: fontFamily,
    height: 1.75,
    wordSpacing: 2.0,
    letterSpacing: 0.50,
  );

  static TextStyle grey20AvenirMedium = TextStyle(
    fontSize: 20,
    color: AppColors.greyFontColor,
    fontWeight: AppFontWeight.MEDIUM,
    fontFamily: fontFamily,
    height: 1.75,
    wordSpacing: 2.0,
    letterSpacing: 0.50,
  );

  static TextStyle pink20AvenirMedium = TextStyle(
    fontSize: 18,
    color: AppColors.pinkDarkColor,
    fontWeight: AppFontWeight.MEDIUM,
    fontFamily: fontFamily,
    height: 1.75,
    wordSpacing: 0,
    letterSpacing: 0.25,
  );

  ///NEW FLOW /////////////////////////
  static TextStyle latoBoldWhite16 = TextStyle(
    fontSize: 14.sp,
    color: AppColors.white,
    fontWeight: AppFontWeight.BOLD,
    fontFamily: fontFamily,
  );
  static TextStyle latoRegularWhite16 = TextStyle(
    fontSize: 14.sp,
    color: AppColors.white,
    fontWeight: AppFontWeight.REGULAR,
    fontFamily: fontFamily,
  );
  static TextStyle latoBoldBlack16 = TextStyle(
    fontSize: 16.sp,
    color: AppColors.black,
    fontWeight: AppFontWeight.BOLD,
    fontFamily: fontFamily,
  );
  static TextStyle latoRegularBlack14 = TextStyle(
    fontSize: 14.sp,
    color: AppColors.black,
    fontWeight: AppFontWeight.REGULAR,
    fontFamily: fontFamily,
  );
  static TextStyle latoMediumBlack14 = TextStyle(
    fontSize: 14.sp,
    color: AppColors.black,
    fontWeight: AppFontWeight.MEDIUM,
    fontFamily: fontFamily,
  );
  static TextStyle latoBoldPrimary16 = TextStyle(
    fontSize: 16.sp,
    color: AppColors.primary,
    fontWeight: AppFontWeight.BOLD,
    fontFamily: fontFamily,
  );
}

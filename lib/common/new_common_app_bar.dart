import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:water_intake/theme/app_colors.dart';
import 'package:water_intake/theme/app_text_styles.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

PreferredSizeWidget newCommonAppBar({
  String? title,
  bool centerTitle = true,
  bool showBack = true,
  bool isDivider = true,
  Color backgroundColor = AppColors.paper,
  Color? iconColor,
  List<Widget>? actions,
  VoidCallback? onBack,
}) {
  return AppBar(
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // IMPORTANT
      statusBarIconBrightness: Brightness.dark, // Android
      statusBarBrightness: Brightness.light, // iOS
    ),
    backgroundColor: AppColors.paper,
    surfaceTintColor: AppColors.paper,
    elevation: 0,
    automaticallyImplyLeading: false,
    centerTitle: centerTitle,
    bottom: PreferredSize(
      preferredSize: Size(double.infinity, 5.h),
      child: isDivider ? Divider(color: Color(0xffE6E6E6), height: 5.h) : SizedBox.fromSize(),
    ),
    leading: showBack
        ? IconButton(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            padding: EdgeInsets.only(left: 10.h),
            icon: Icon(Platform.isAndroid ? Icons.arrow_back_rounded : Icons.arrow_back_ios_new_rounded),
            onPressed:
                onBack ??
                () {
                  Get.back();
                },
          )
        : null,
    title: title != null
        ? Text(
            title,
            style: AppTextStyle.latoBoldWhite16.copyWith(fontWeight: FontWeight.w600, color: AppColors.oxff333B47, fontSize: 14.sp),
          )
        : SizedBox(),
    actions: actions,
  );
}

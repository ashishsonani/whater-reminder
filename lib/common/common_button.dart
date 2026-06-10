import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:water_intake/theme/app_colors.dart';
import 'package:water_intake/theme/app_text_styles.dart';

class CommonButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;
  final double? borderRadius;
  final TextStyle? textStyle;
  final BorderSide? border;

  const CommonButton({
    super.key,
    required this.text,
    this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height,
    this.borderRadius,
    this.textStyle,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? 38.h,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all(backgroundColor ?? AppColors.teal),
          foregroundColor: MaterialStateProperty.all(textColor ?? AppColors.white),
          overlayColor: MaterialStateProperty.all(Colors.transparent),
          elevation: MaterialStateProperty.all(0),
          shadowColor: MaterialStateProperty.all(Colors.transparent),
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius ?? 48.r), side: border ?? BorderSide.none),
          ),
        ),
        child: Text(
          text,
          textAlign: TextAlign.justify,
          style: (textStyle ?? AppTextStyle.button).copyWith(color: textColor ?? AppColors.white),
        ),
      ),
    );
  }
}

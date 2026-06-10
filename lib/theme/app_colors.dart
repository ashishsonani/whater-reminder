import 'package:flutter/material.dart';

/// Color tokens for the Hydro app.
/// Mirrors the CSS variables from the HTML reference 1:1.
class AppColors {
  AppColors._();

  // Ink / text
  static const ink = Color(0xFF0F172A);
  static const inkSoft = Color(0xFF334155);
  static const inkMute = Color(0xFF64748B);
  static const inkFaint = Color(0xFF94A3B8);

  // Surfaces
  static const paper = Color(0xFFF8FAFC);
  static const paperWarm = Color(0xFFF1F5F9);
  static const card = Color(0xFFFFFFFF);
  static const cardEdge = Color(0xFFE2E8F0);

  // Brand — sky blue
  static const teal = Color(0xFF0EA5E9);
  static const tealDeep = Color(0xFF0369A1);
  static const tealBright = Color(0xFF38BDF8);
  static const tealSoft = Color(0xFFE0F2FE);

  // Accents
  static const accent = Color(0xFFE36B4C);      // muted coral
  static const accentSoft = Color(0xFFF4D9CF);
  static const gold = Color(0xFFC8A04A);
  static const goldSoft = Color(0x2EC8A04A);    // ~18% alpha
  static const good = Color(0xFF4A7C59);        // forest green

  // Background gradient behind the phone frame (web demo)
  static const bgGradientTop = Color(0xFF334155);
  static const bgGradientBottom = Color(0xFF0F172A);

  // Drink-button gradient stops
  static const drinkBtnLight = tealBright;
  static const drinkBtnMid = teal;
  static const drinkBtnDark = tealDeep;

  // Legacy/App-specific Colors
  // Primary Colors
  static const Color primary = Color(0xFF0EA5E9);
  static const Color black2 = Color(0xFF333B47);
  static const Color primaryLight = Color(0xFFBBDEFB);
  static const Color grey1 = Color(0xFF8596AB);
  static const Color grey2 = Color(0xFFDDDDDD);
  static const Color primaryDark = Color(0xFF1976D2);
  static const Color white2 = Color(0xFFEFF6FF);

  // Accent black
  static const Color black1 = Color(0xFF212529);
  static const Color black3 = Color(0xFF394453);
  static const Color secondary = Color(0xFF00BCD4);

  // Neutral grey
  static const Color grey3 = Color(0xFFE6E6E6);
  static const Color grey4 = Color(0xFF6C757D);
  static const Color grey5 = Color(0xFF969593);
  static const Color grey6 = Color(0xFFB0BBC9);
  static const Color grey7 = Color(0xFF595C5D);
  static const Color white = Color(0xFFFFFFFF);
  static const Color white1 = Color(0xFFF3F3F3);
  static const Color black = Color(0xFF000000);
  static const Color grey = Color(0xFF9E9E9E);
  static const Color lightGrey = Color(0xFFE0E0E0);

  // Status Colors
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF388E3C);
  static const Color warning = Color(0xFFFBC02D);

  // Water Intake Specific
  static const Color waterBlue = Color(0xFF4FC3F7);
  static const Color deepWater = Color(0xFF0288D1);
  static const Color hydrationGoal = Color(0xFF81D4FA);

  static const Color blueDark = Color(0xff2853AF);
  static const Color tealLegacy = Color(0xFF0EA5E9);
  static const Color greay = Color(0xffedf1f7);

  static const Color primaryColor2 = Color(0xFFCECECE);
  static const Color pinkColor = Color(0xffF1E5FD);
  static const Color oxffFFDEE7 = Color(0xffFDF1F3);
  static const Color oxffF3F3F3 = Color(0xffF3F3F3);

  static const Color red = Colors.red;
  static const Color greyColor = Color(0xff504E4E);
  static const Color oxff333B47 = Color(0xff333B47);
  static const Color oxff394453 = Color(0xff394453);
  static const Color grey1Color = Color(0xff615371);
  static const Color grey2Color = Color(0xff8C8A8A);
  static const Color pinkDarkColor = Color(0xfff21f7e);
  static const Color blueDarkColor = Color(0xff2f3e96);
  static const Color darkPurpleColor = Color(0xff615371);
  static const Color orangeColor = Color(0xffFEB18F);
  static const Color blueColor = Color(0xff7CACF8);
  static const Color greyDarkColor = Color(0xff3F414E);
  static const Color lightSkyColor = Color(0xffB9C4F9);
  static const Color greenLightColor = Color(0xffD9ECDF);
  static const lightBlack2 = Color(0xFF343F54);
  static const lightGreyColor = Color(0xFFEFF1F3);
  static const hintGreyColor = Color(0xFF7D8FAB);
  static const blueFontColor = Color(0xFF333E92);
  static const containerColor1 = Color(0xFFF6F8FE);
  static const greenColor = Color(0xFF11C06C);
  static const whiteContainerColor = Color(0xFFF2F2F2);
  static const orangeDarkColor = Color(0xFFFF8D4D);
  static const yellowColor = Color(0xFFFFC702);
  static const redColor = Color(0xFFFF2B1E);
  static const redColor2 = Color(0xFFF65142);
  static const greenLightColor2 = Color(0xFFD2E3D5);
  static const purpleColor = Color(0xFF80476B);
  static const skyColor = Color(0xFFC1CDF1);
  static const greyButtonColor = Color(0xFFC4C4C4);
  static const greyFontColor = Color(0xFF757575);
  static const weightTrackingColor = Color(0xFFA3BABC);
  static const numberOfKickColor = Color(0xFF87476F);
  static const symptomsColor = Color(0xFFC1805A);
  static const babyNamesColor = Color(0xFFD4594A);
  static const profileAppBarColor = Color(0xFF0EA5E9);
  static const greyFontColor2 = Color(0xFF262626);
  static const dividerColor = Color(0xFFA9AED2);
  static const greenSuccessColor = Color(0xFF3CAF2B);
  static const lightGreyColor2 = Color(0xFFD9D9D9);
  static const lightGreyColor3 = Color(0xFFF5F5F5);
  static const lightGreyColor4 = Color(0xFFE5E6EE);
  static const purpleColor2 = Color(0xFF9747FF);
  static const blueLightColor = Color(0xFF0D99FF);
  static const tealColor = Color(0xFF0EA5E9);
  static const babyMusicColor = Color(0xFF7B867F);
  static const lightGreenColor = Color(0xFF2c2c2c);
  static const contractionColor = Color(0xFF7797C9);
  static const blackSubtitleColor = Color(0xFF323232);
  static const blueDark2Color = Color(0xFF171725);
  static const grey3Color = Color(0xFF66707A);
  static const lightColor = Color(0xFFE8F2FF);
  static const light2Color = Color(0xFF78828A);
  static const oxFF6A7AFA = Color(0xFF6A7AFA);
  static const oxFFDDDDDD = Color(0xFFDDDDDD);
  static const oxFFB0BBC9 = Color(0xFFB0BBC9);
  static const transparent = Colors.transparent;
}

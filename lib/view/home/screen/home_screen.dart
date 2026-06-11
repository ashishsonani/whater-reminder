import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sleek_circular_slider/sleek_circular_slider.dart';
import 'package:water_intake/gen/assets.gen.dart';
import 'package:water_intake/services/ad_service.dart';
import 'package:water_intake/theme/app_colors.dart';
import 'package:water_intake/theme/app_fonts.dart';
import 'package:water_intake/theme/app_shadows.dart';
import 'package:water_intake/theme/app_text_styles.dart';
import 'package:water_intake/theme/app_typography.dart';
import 'package:water_intake/utils/app_strings.dart';
import 'package:water_intake/view/home/controller/home_controller.dart';
import 'package:water_intake/view/home/widget/water_widgets.dart';

import '../../../models/water_record.dart' show WaterRecord;
import '../../../route/route.dart';
import '../../dashboard/controller/dashboard_controller.dart';

class CustomDrink {
  final String name;
  final double coefficient;

  CustomDrink({required this.name, required this.coefficient});

  Map<String, dynamic> toJson() => {'name': name, 'coefficient': coefficient};

  factory CustomDrink.fromJson(Map<String, dynamic> json) =>
      CustomDrink(name: json['name'] as String, coefficient: (json['coefficient'] as num).toDouble());
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(elevation: 0, surfaceTintColor: Colors.transparent, toolbarHeight: 0, backgroundColor: AppColors.paper),
      body: GetBuilder<HomeController>(
        builder: (controller) => SingleChildScrollView(
          child: Column(
            // crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_getGreeting().toUpperCase(), style: AppTypography.eyebrow),
                        SizedBox(height: 4.h),
                        Text(
                          DateFormat('EEEE, MMMM d', Get.locale?.toString() ?? 'en_US').format(DateTime.now()),
                          style: AppTypography.greetingTitle.copyWith(fontSize: 16.sp),
                        ),
                      ],
                    ),
                    StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      stream: controller.todaySummaryStream,
                      builder: (context, snapshot) {
                        int streak = controller.currentStreak.value;
                        if (snapshot.hasData && snapshot.data!.exists) {
                          streak = snapshot.data!.data()?['currentStreak']?.toInt() ?? streak;
                        }
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            border: Border.all(color: AppColors.cardEdge),
                            borderRadius: BorderRadius.circular(100),
                            boxShadow: AppShadows.level1,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.local_fire_department_rounded, size: 14, color: AppColors.accent),
                              const SizedBox(width: 6),
                              Text('$streak', style: AppTypography.streakNum),
                              const SizedBox(width: 4),
                              Text(AppString.days.tr.toUpperCase(), style: AppTypography.streakLabel),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10.h),
              Container(
                margin: EdgeInsets.symmetric(horizontal: 20.w),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: AppShadows.level2,
                  border: Border.all(color: AppColors.cardEdge),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Subtle background gradient glow at top-right
                    Positioned(
                      top: -40.h,
                      right: -40.w,
                      child: Container(
                        width: 160.w,
                        height: 160.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(colors: [AppColors.tealSoft.withOpacity(0.4), AppColors.tealSoft.withOpacity(0.0)]),
                        ),
                      ),
                    ),
                    Column(
                      children: [
                        // Card Header Row
                        Padding(
                          padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(AppString.todaysHydration.tr.toUpperCase(), style: AppTypography.heroLabel),
                              Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.good,
                                      boxShadow: [BoxShadow(color: AppColors.good.withOpacity(0.18), blurRadius: 0, spreadRadius: 3)],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(AppString.onTrack.tr, style: AppTypography.heroTime),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 16.h),
                        _buildCircularProgress(controller),
                        SizedBox(height: 24.h),
                        _buildActionButtons(context, controller),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 18.h),
              Obx(() => _buildStatsCard(controller)),
              // SizedBox(height: 18.h),
              SizedBox(height: 18.h),
              _buildCupTypeSelector(context, controller),
              SizedBox(height: 18.h),
              _buildHistorySection(controller),
              SizedBox(height: 18.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCupTypeSelector(BuildContext context, HomeController controller) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.cardEdge),

        color: AppColors.card,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: AppShadows.level1,
      ),
      child: Obx(() {
        // Construct the list of drinks: "plain_water" first, then other unique recent drinks
        final List<String> listToShow = ["plain_water"];
        for (final item in controller.recentDrinks) {
          if (item != "plain_water" && item.isNotEmpty) {
            listToShow.add(item);
          }
        }

        final activeDrinkAsset = controller.selectedDrinkAsset.value;
        final String activeFilename = _getFilenameFromAsset(activeDrinkAsset);

        return SizedBox(
          height: 36.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: listToShow.length,
            separatorBuilder: (_, __) => SizedBox(width: 8.w),
            itemBuilder: (context, index) {
              final String filename = listToShow[index];
              final String label = _getDrinkName(filename.toLowerCase());
              final bool isSelected = activeFilename == filename;

              Widget chipIcon;
              final AssetGenImage? assetGen = _getAssetGenImageForDrink(filename);
              if (assetGen != null) {
                chipIcon = SizedBox(width: 20.w, height: 20.h, child: assetGen.image());
              } else if (filename.startsWith("my_drink_")) {
                chipIcon = SizedBox(width: 20.w, height: 20.h, child: Assets.images.png.cupFill1.image());
              } else {
                chipIcon = const SizedBox.shrink();
              }

              return GestureDetector(
                onTap: () {
                  // Set selected drink type
                  if (assetGen != null) {
                    controller.selectedDrinkAsset.value = assetGen;
                  }
                  controller.customDrinkType.value = label;

                  // Set default cup for this drink type
                  final int defIdx = _getDefaultCupIndexForDrink(filename);
                  if (defIdx >= 0 && defIdx < controller.availableCups.length) {
                    final amount = controller.availableCups[defIdx];
                    final fillAsset = defIdx < controller.selectedCupList.length
                        ? controller.selectedCupList[defIdx]
                        : Assets.images.png.cup9;
                    controller.updateSelectedCup(amount, defIdx);
                    controller.selectedCupAsset.value = fillAsset;
                  }

                  // Move this drink to front of recents
                  controller.addRecentDrink(filename);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.tealSoft : Colors.white,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: isSelected ? AppColors.primary : AppColors.grey3, width: 1.w),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      chipIcon,
                      SizedBox(width: 4.w),
                      Text(
                        label,
                        style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: const Color(0xff212529)),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }

  Widget _buildCircularProgress(HomeController controller) {
    return Obx(() {
      int current = controller.currentIntake.value;
      int target = controller.targetIntake.value;

      double rawPercentage = target > 0 ? (current / target) : 0.0;
      double realPercentage = rawPercentage.clamp(0.0, 1.4);
      double targetPercentage = rawPercentage.clamp(0.0, 1.0);

      const double gaugeWidth = 240;
      const double strokeWidth = 12;

      return TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 1000),
        curve: Curves.easeInOutCubic,
        tween: Tween<double>(begin: 0.0, end: targetPercentage),
        builder: (context, animatedPercentage, child) {
          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              SizedBox(
                width: gaugeWidth.w,
                height: gaugeWidth.w,
                child: SleekCircularSlider(
                  min: 0,
                  max: 1.0,
                  initialValue: animatedPercentage,
                  appearance: CircularSliderAppearance(
                    animationEnabled: false,
                    size: gaugeWidth.w,
                    startAngle: 270,
                    angleRange: 360,
                    customWidths: CustomSliderWidths(
                      trackWidth: strokeWidth.w,
                      progressBarWidth: strokeWidth.w,
                      handlerSize: animatedPercentage > 0.001 ? 4 : 0,
                    ),
                    customColors: CustomSliderColors(
                      trackColor: AppColors.paperWarm,
                      progressBarColors: animatedPercentage > 0.001
                          ? const [AppColors.tealBright, AppColors.teal]
                          : [Colors.transparent, Colors.transparent],
                      hideShadow: true,
                      dotColor: Colors.white,
                    ),
                    infoProperties: InfoProperties(modifier: (double value) => ''),
                  ),
                ),
              ),
              Positioned(
                left: -15,
                bottom: 20.h,
                child: Container(
                  width: 30.w,
                  height: 30.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.paper,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4))],
                  ),
                  child: Center(
                    child: DynamicDropletWaveWidget(percentage: animatedPercentage, size: 16.w),
                  ),
                ),
              ),
              Positioned(
                right: -15,
                bottom: 20.h,
                child: Container(
                  width: 30.w,
                  height: 30.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.paper,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4))],
                  ),
                  child: Center(
                    child: DynamicHeartWaveWidget(percentage: animatedPercentage, size: 16.w),
                  ),
                ),
              ),

              // Inside content (static during animation)
              if (child != null) child,
            ],
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(NumberFormat('#,###', Get.locale?.toString() ?? 'en_US').format(current), style: AppTypography.amountCurrent),
                SizedBox(width: 4.w),
                Text(controller.isMl.value ? AppString.ml.tr : AppString.oz.tr, style: AppTypography.amountUnit),
              ],
            ),
            Container(
              width: 32.w,
              height: 1.h,
              color: AppColors.cardEdge,
              margin: EdgeInsets.symmetric(vertical: 8.h),
            ),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(text: '${AppString.goal.tr} • ', style: AppTypography.amountGoal),
                  TextSpan(
                    text:
                        '${NumberFormat('#,###', Get.locale?.toString() ?? 'en_US').format(target)} ${controller.isMl.value ? AppString.ml.tr : AppString.oz.tr}',
                    style: AppTypography.amountGoalStrong,
                  ),
                ],
              ),
            ),
            const DrinkAnimationWidget(),
            Container(
              margin: EdgeInsets.only(top: 8.h),
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 5.h),
              decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(100)),
              child: Text("${(realPercentage * 100).toInt()}% ${AppString.completeUpper.tr}", style: AppTypography.percentBadge),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildActionButtons(BuildContext context, HomeController controller) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 24.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _buildSecondaryActionButton(
              iconData: "assets/images/svg/droplet-half.svg",
              label: AppString.intakeGoalUpper.tr,
              onTap: () => _showAdjustIntakeGoalDialog(context, controller),
            ),
          ),
          10.w.horizontalSpace,
          _buildPrimaryLogButton(controller),
          10.w.horizontalSpace,
          Expanded(
            child: Obx(() {
              return _buildSecondaryActionButton(
                customIcon: controller.selectedDrinkAsset.value.image(scale: 6.5),
                showBadge: true,
                label: AppString.drinkType.tr,
                onTap: () => _showDrinkTypeBottomSheet(context, controller),
              );
            }),
          ),
        ],
      ),
    );
  }

  void _showDrinkListBottomSheet(BuildContext context) {
    final HomeController controller = Get.find<HomeController>();
    final isPremium = false;
    final List<String> categoriesToShow = controller.allType.keys
        .where((key) => key != AppString.categoryMore.tr && (key != AppString.myDrink.tr || isPremium))
        .toList();
    final ScrollController listScrollController = ScrollController();

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(color: const Color(0xffE9ECEF), borderRadius: BorderRadius.circular(2.r)),
            ),
            SizedBox(height: 10.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppString.drinkList.tr,
                  style: AppTextStyle.h1.copyWith(fontSize: 16.sp, color: AppColors.black1, fontWeight: FontWeight.w600),
                ),
                GestureDetector(
                  onTap: () => Get.back(),
                  child: Icon(Icons.close, color: AppColors.grey5, size: 20.sp),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            const Divider(color: Color(0xffF0F0F0)),
            SizedBox(height: 10.h),
            Flexible(
              child: Scrollbar(
                controller: listScrollController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: listScrollController,
                  child: Column(
                    children: categoriesToShow.map((categoryKey) {
                      final Widget categoryIcon = controller.allType[categoryKey]?.first ?? const SizedBox.shrink();

                      return Padding(
                        padding: EdgeInsets.only(bottom: 12.h),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 8.h),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: AppColors.grey3, width: 1),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(width: 28.w, height: 28.h, child: categoryIcon),
                                    SizedBox(width: 15.w),
                                    Expanded(
                                      child: Text(
                                        categoryKey,
                                        style: AppTextStyle.body.copyWith(
                                          fontSize: 14.sp,
                                          color: AppColors.black1,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(width: 15.w),
                            Assets.images.png.menuOrder.image(scale: 2.5),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
            SizedBox(height: 10.h),
            SizedBox(
              width: double.infinity,
              height: 50.h,
              child: ElevatedButton(
                onPressed: () {
                  Get.back(); // Close the bottom sheet
                  if (false) {
                    _showAddDrinkDialog(context);
                  } else {
                    Get.toNamed(AppRoutes.premium);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: false ? AppColors.primary : const Color(0xffB4BBC4),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25.r)),
                ),
                child: Text(
                  AppString.addMyDrink.tr,
                  style: AppTextStyle.button.copyWith(fontSize: 15.sp, color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            SizedBox(height: 10.h),
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  String _getFilenameFromAsset(AssetGenImage asset) {
    return asset.path.split('/').last.split('.').first;
  }

  int _getDefaultCupIndexForDrink(String filename) {
    final fn = filename.toLowerCase();
    if (fn.contains("tea")) {
      return 5; // Mug
    } else if (fn.contains("coff") || fn.contains("cappa")) {
      return 4; // Coffee Cup
    } else if (fn.contains("water") || fn.contains("drink")) {
      return 3; // Glass
    } else {
      return 1; // Cup
    }
  }

  String _getFilenameFromImage(Image imageWidget) {
    dynamic provider = imageWidget.image;

    // 1. Unwrap wrapping providers like ResizeImage dynamically
    while (provider != null) {
      try {
        if (provider.imageProvider != null) {
          provider = provider.imageProvider;
          continue;
        }
      } catch (_) {}
      break;
    }

    // 2. Try to get assetName dynamically if provider has it
    if (provider != null) {
      try {
        final String? assetName = provider.assetName;
        if (assetName != null && assetName.isNotEmpty) {
          final filenameWithExt = assetName.split('/').last;
          return filenameWithExt.split('.').first;
        }
      } catch (_) {}
    }

    // 3. Fallback: Parse from toString() using regular expression
    final str = imageWidget.image.toString();
    final match = RegExp(r'assets/images/png/([^/)"\\]+)\.[a-zA-Z0-9]+').firstMatch(str);
    if (match != null) {
      return match.group(1)!;
    }

    return "";
  }

  String _getDrinkName(String filename) {
    switch (filename) {
      case "plain_water":
        return AppString.plainWater.tr;
      case "sparkling_water":
        return AppString.sparklingWater.tr;
      case "mineral_water":
        return AppString.mineralWater.tr;
      case "sport_drink":
        return AppString.sportDrink.tr;
      case "zero_sport_drink":
        return AppString.zeroSportDrink.tr;
      case "rice_drink":
        return AppString.riceDrink.tr;
      case "barley_drink":
        return AppString.barleyDrink.tr;
      case "enrgy_drink":
        return AppString.energyDrink.tr;
      case "tea":
        return AppString.tea.tr;
      case "milk_tea":
        return AppString.milkTea.tr;
      case "black_tea":
        return AppString.blackTea.tr;
      case "green_tea":
        return AppString.greenTea.tr;
      case "cappacuino_coffie":
        return AppString.cappuccinoCoffee.tr;
      case "mocha_coffee":
        return AppString.mochaCoffee.tr;
      case "low_fat_milk":
        return AppString.lowFatMilk.tr;
      case "orange_juice":
        return AppString.orangeJuice.tr;
      case "lemon_juice":
        return AppString.lemonJuice.tr;
      case "pineapple_juice":
        return AppString.pineappleJuice.tr;
      case "watermelon_juice":
        return AppString.watermelonJuice.tr;
      case "peach_juice":
        return AppString.peachJuice.tr;
      case "strawberry_juice":
        return AppString.strawberryJuice.tr;
      case "coconut_juice":
        return AppString.coconutJuice.tr;
      case "apple_juice":
        return AppString.appleJuice.tr;
      case "carrot_juice":
        return AppString.carrotJuice.tr;
      default:
        if (filename.startsWith("my_drink_")) {
          return filename
              .substring(9)
              .split('_')
              .map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '')
              .join(' ');
        }
        return filename.split('_').map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '').join(' ');
    }
  }

  double _getDrinkFactor(String filename) {
    switch (filename) {
      case "plain_water":
      case "sparkling_water":
        return 1.0;
      case "mineral_water":
      case "sport_drink":
        return 0.95;
      case "zero_sport_drink":
        return 0.98;
      case "rice_drink":
        return 0.89;
      case "barley_drink":
        return 0.85;
      case "enrgy_drink":
        return 0.5;
      case "tea":
      case "milk_tea":
      case "black_tea":
      case "green_tea":
        return 0.9;
      case "cappacuino_coffie":
      case "mocha_coffee":
        return 0.9;
      case "low_fat_milk":
        return 0.88;
      case "orange_juice":
      case "lemon_juice":
      case "pineapple_juice":
      case "watermelon_juice":
      case "peach_juice":
      case "strawberry_juice":
      case "coconut_juice":
      case "apple_juice":
      case "carrot_juice":
        return 0.85;
      default:
        return 1.0;
    }
  }

  AssetGenImage? _getAssetGenImageForDrink(String filename) {
    final s = filename
        .replaceAllMapped(RegExp(r'([a-z0-9])([A-Z])'), (Match m) => '${m.group(1)}_${m.group(2)!.toLowerCase()}')
        .toLowerCase();

    final normalized = (s == "cappuccino_coffee" || s == "cappuccino_coffie")
        ? "cappacuino_coffie"
        : (s == "energy_drink" ? "enrgy_drink" : s);

    switch (normalized) {
      case "plain_water":
        return Assets.images.png.plainWater;
      case "mineral_water":
        return Assets.images.png.mineralWater;
      case "sport_drink":
        return Assets.images.png.sportDrink;
      case "enrgy_drink":
        return Assets.images.png.enrgyDrink;
      case "zero_sport_drink":
        return Assets.images.png.zeroSportDrink;
      case "rice_drink":
        return Assets.images.png.riceDrink;
      case "barley_drink":
        return Assets.images.png.barleyDrink;
      case "sparkling_water":
        return Assets.images.png.sparklingWater;
      case "tea":
        return Assets.images.png.tea;
      case "milk_tea":
        return Assets.images.png.milkTea;
      case "black_tea":
        return Assets.images.png.blackTea;
      case "green_tea":
        return Assets.images.png.greenTea;
      case "cappacuino_coffie":
        return Assets.images.png.cappacuinoCoffie;
      case "mocha_coffee":
        return Assets.images.png.mochaCoffee;
      case "low_fat_milk":
        return Assets.images.png.lowFatMilk;
      case "orange_juice":
        return Assets.images.png.orangeJuice;
      case "lemon_juice":
        return Assets.images.png.lemonJuice;
      case "pineapple_juice":
        return Assets.images.png.pineappleJuice;
      case "watermelon_juice":
        return Assets.images.png.watermelonJuice;
      case "peach_juice":
        return Assets.images.png.peachJuice;
      case "strawberry_juice":
        return Assets.images.png.strawberryJuice;
      case "coconut_juice":
        return Assets.images.png.coconutJuice;
      case "apple_juice":
        return Assets.images.png.appleJuice;
      case "carrot_juice":
        return Assets.images.png.carrotJuice;
      default:
        return null;
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return AppString.goodMorning.tr;
    } else if (hour < 17) {
      return AppString.goodAfternoon.tr;
    } else if (hour < 21) {
      return AppString.goodEvening.tr;
    } else {
      return AppString.goodNight.tr;
    }
  }

  Widget _buildTableCell(String text, {bool isHeader = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      child: Text(
        text,
        style: TextStyle(fontSize: 12.sp, fontWeight: isHeader ? FontWeight.w600 : FontWeight.normal, color: const Color(0xff8596AB)),
      ),
    );
  }

  void _showAddDrinkDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController coefController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
          child: StatefulBuilder(
            builder: (context, setState) {
              final String drinkName = nameController.text.isEmpty ? AppString.egLemonSoda.tr : nameController.text;
              final double coef = double.tryParse(coefController.text) ?? -1.3;
              final int absorbed = (200 * coef).round();

              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppString.addDrink.tr,
                        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600, color: const Color(0xff212529)),
                      ),
                      const Divider(color: Color(0xffE6E6E6)),
                      SizedBox(height: 14.h),
                      Text(
                        AppString.enterDrinkName.tr,
                        style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600, color: const Color(0xff212529)),
                      ),
                      SizedBox(height: 8.h),
                      TextField(
                        controller: nameController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: AppString.egLemonSoda.tr,
                          hintStyle: TextStyle(color: AppColors.grey6, fontSize: 14.sp),
                          border: OutlineInputBorder(
                            borderSide: const BorderSide(color: AppColors.grey3),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: AppColors.grey3),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: AppColors.grey3),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          contentPadding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        AppString.waterAbsorptionExplanation.tr,
                        style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600, color: AppColors.black1),
                      ),
                      SizedBox(height: 8.h),
                      TextField(
                        controller: coefController,
                        onChanged: (_) => setState(() {}),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                        decoration: InputDecoration(
                          hintText: AppString.egCoefficient.tr,
                          hintStyle: TextStyle(color: AppColors.grey6, fontSize: 14.sp),
                          border: OutlineInputBorder(
                            borderSide: const BorderSide(color: AppColors.grey3),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: AppColors.grey3),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: AppColors.grey3),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          contentPadding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        AppString.coefficientExplanationDetails.tr,
                        style: TextStyle(fontSize: 12.sp, color: const Color(0xff6C757D)),
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        AppString.example.tr,
                        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: AppColors.black1),
                      ),
                      SizedBox(height: 8.h),
                      Table(
                        border: TableBorder.all(color: const Color(0xffE9ECEF), width: 1),
                        children: [
                          TableRow(children: [_buildTableCell(AppString.drinkName.tr, isHeader: true), _buildTableCell(drinkName)]),
                          TableRow(
                            children: [_buildTableCell(AppString.amount.tr, isHeader: true), _buildTableCell("200 ${AppString.ml.tr}")],
                          ),
                          TableRow(
                            children: [
                              _buildTableCell(AppString.coefficient.tr, isHeader: true),
                              _buildTableCell(coefController.text.isEmpty ? "-1.3" : coefController.text),
                            ],
                          ),
                          TableRow(
                            children: [
                              _buildTableCell(AppString.amountOfAbsorbedWater.tr, isHeader: true),
                              _buildTableCell("$absorbed ${AppString.ml.tr}"),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 24.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Text(
                              AppString.cancel.tr.toUpperCase(),
                              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: const Color(0xff6C757D)),
                            ),
                          ),
                          SizedBox(width: 16.w),
                          GestureDetector(
                            onTap: () {
                              final String name = nameController.text.trim();
                              final double? coef = double.tryParse(coefController.text.trim());
                              if (name.isNotEmpty && coef != null) {
                                final HomeController controller = Get.find<HomeController>();
                                controller.addCustomDrink(name, coef);
                                Navigator.of(context).pop();
                              } else {
                                Get.snackbar(
                                  "Error",
                                  "Please enter a valid drink name and coefficient",
                                  snackPosition: SnackPosition.BOTTOM,
                                );
                              }
                            },
                            child: Text(
                              AppString.add.tr.toUpperCase(),
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                                color: nameController.text.trim().isNotEmpty && double.tryParse(coefController.text.trim()) != null
                                    ? AppColors.primary
                                    : Color(0xffB0BBC9),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showDrinkTypeBottomSheet(BuildContext context, HomeController controller) {
    final RxString selectedCategory = (controller.allType.keys.isNotEmpty ? controller.allType.keys.first : AppString.categoryWater.tr).obs;
    final TextEditingController searchController = TextEditingController();
    final RxString searchQuery = "".obs;
    final ScrollController gridScrollController = ScrollController();

    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin: EdgeInsets.symmetric(vertical: 8.h),
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(color: const Color(0xffE9ECEF), borderRadius: BorderRadius.circular(2.r)),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppString.drinkType.tr,
                    style: AppTextStyle.latoBoldPrimary16.copyWith(fontSize: 16.sp, color: const Color(0xff212529)),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.close, color: Color(0xff8596AB), size: 22),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.grey3),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 12.h),

                    // Search Bar
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: AppString.search.tr,
                        hintStyle: TextStyle(color: AppColors.grey6, fontSize: 14.sp),
                        prefixIcon: Assets.images.png.search.image(scale: 4),
                        border: OutlineInputBorder(
                          borderSide: const BorderSide(color: AppColors.grey3),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: AppColors.grey3),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: AppColors.primary),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        contentPadding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 8.w),
                      ),
                      onChanged: (val) {
                        searchQuery.value = val;
                      },
                    ),
                    SizedBox(height: 12.h),

                    // Categories horizontal list
                    SizedBox(
                      height: 64.h,
                      child: Obx(() {
                        final currentSelected = selectedCategory.value;
                        final List<String> categories = [];
                        if (controller.favoriteDrinks.isNotEmpty) {
                          categories.add(AppString.favorite.tr);
                        }
                        // final isPremium = IAPService.to.isPremium.value;
                        final isPremium = true;
                        for (final key in controller.allType.keys) {
                          if (key == "My Drink" && !isPremium) {
                            continue;
                          }
                          categories.add(key);
                        }

                        return ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: categories.length,
                          separatorBuilder: (context, index) => SizedBox(width: 12.w),
                          itemBuilder: (context, index) {
                            final categoryKey = categories[index];
                            bool isSelected = currentSelected == categoryKey;

                            Widget categoryIcon;
                            if (categoryKey == AppString.favorite.tr) {
                              categoryIcon = Image.asset("assets/images/png/fill_like.png", scale: 1.5);
                            } else {
                              categoryIcon = controller.allType[categoryKey]?.first ?? const SizedBox.shrink();
                            }

                            return GestureDetector(
                              onTap: () {
                                if (categoryKey == AppString.categoryMore.tr) {
                                  _showDrinkListBottomSheet(context);
                                } else {
                                  selectedCategory.value = categoryKey;
                                }
                              },
                              child: Container(
                                width: 64.w,
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.tealSoft : Colors.white,
                                  borderRadius: BorderRadius.circular(12.r),
                                  border: Border.all(color: isSelected ? AppColors.primary : AppColors.grey3, width: 1),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    SizedBox(height: 32.h, child: categoryIcon),
                                    SizedBox(height: 2.h),
                                    Text(
                                      categoryKey,
                                      textAlign: TextAlign.center,
                                      style: AppTextStyle.body.copyWith(
                                        fontSize: 11.sp,
                                        color: AppColors.black1,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      }),
                    ),
                    SizedBox(height: 16.h),

                    // Drinks Grid View for the selected category
                    Obx(() {
                      final category = selectedCategory.value;

                      if (category == AppString.favorite.tr && controller.favoriteDrinks.isEmpty) {
                        Future.microtask(() {
                          selectedCategory.value = (controller.allType.keys.isNotEmpty
                              ? controller.allType.keys.first
                              : AppString.categoryWater.tr);
                        });
                        return const SizedBox.shrink();
                      }

                      final List drinks;
                      if (category == AppString.favorite.tr) {
                        final List<dynamic> favImages = [];
                        for (final catKey in controller.allType.keys) {
                          if (catKey == AppString.categoryMore.tr || catKey == AppString.favorite.tr) continue;
                          final List? catDrinks = controller.allType[catKey];
                          if (catDrinks != null) {
                            for (final drink in catDrinks) {
                              if (drink is Image) {
                                final String filename = _getFilenameFromImage(drink);
                                final String displayName = _getDrinkName(filename.toLowerCase());
                                if (controller.favoriteDrinks.contains(displayName)) {
                                  if (!favImages.any((img) => img is Image && _getFilenameFromImage(img) == filename)) {
                                    favImages.add(drink);
                                  }
                                }
                              }
                            }
                          }
                        }
                        for (final customDrink in controller.customDrinks) {
                          if (controller.favoriteDrinks.contains(customDrink.name)) {
                            favImages.add(customDrink);
                          }
                        }
                        drinks = favImages;
                      } else if (category == AppString.myDrink.tr) {
                        drinks = controller.customDrinks;
                      } else {
                        drinks = controller.allType[category] ?? [];
                      }

                      if (drinks.isEmpty) {
                        return Expanded(
                          child: Center(
                            child: Text(
                              AppString.noDrinksFound.tr,
                              style: TextStyle(fontSize: 14.sp, color: AppColors.grey4),
                            ),
                          ),
                        );
                      }

                      final query = searchQuery.value.toLowerCase();
                      final List<int> filteredIndices = [];
                      if (category == AppString.myDrink.tr) {
                        for (int i = 0; i < controller.customDrinks.length; i++) {
                          final drink = controller.customDrinks[i];
                          if (query.isEmpty || drink.name.toLowerCase().contains(query)) {
                            filteredIndices.add(i);
                          }
                        }
                      } else {
                        for (int i = 0; i < drinks.length; i++) {
                          final item = drinks[i];
                          final String name;
                          if (item is CustomDrink) {
                            name = item.name;
                          } else {
                            final Image img = item as Image;
                            final fn = _getFilenameFromImage(img);
                            name = _getDrinkName(fn.toLowerCase());
                          }
                          if (query.isEmpty || name.toLowerCase().contains(query)) {
                            filteredIndices.add(i);
                          }
                        }
                      }

                      return Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category,
                              style: AppTextStyle.h1.copyWith(fontSize: 16.sp, color: AppColors.black1),
                            ),
                            SizedBox(height: 12.h),
                            Expanded(
                              child: Scrollbar(
                                controller: gridScrollController,
                                thumbVisibility: true,
                                child: GridView.builder(
                                  controller: gridScrollController,
                                  scrollDirection: Axis.vertical,
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    childAspectRatio: 0.75,
                                    crossAxisSpacing: 12.w,
                                    mainAxisSpacing: 12.h,
                                  ),
                                  itemCount: filteredIndices.length,
                                  itemBuilder: (context, gridIndex) {
                                    final int originalIndex = filteredIndices[gridIndex];

                                    final Widget drinkImage;
                                    final String filename;
                                    final String displayName;
                                    final double factor;
                                    final int currentAmount;
                                    final String volumeLabel;
                                    final bool isLocked;
                                    String originalCategory = category;
                                    int originalDrinkIndex = originalIndex;

                                    final bool isCustomDrinkItem =
                                        (category == AppString.myDrink.tr) ||
                                        (category == AppString.favorite.tr && drinks[originalIndex] is CustomDrink);

                                    if (isCustomDrinkItem) {
                                      final CustomDrink customDrink = (category == AppString.myDrink.tr)
                                          ? controller.customDrinks[originalIndex]
                                          : drinks[originalIndex] as CustomDrink;

                                      drinkImage = Assets.images.png.cupFill1.image(scale: 5.5);
                                      filename = "my_drink_${customDrink.name.replaceAll(' ', '_').toLowerCase()}";
                                      displayName = customDrink.name;
                                      factor = customDrink.coefficient;
                                      currentAmount = controller.getDrinkAmount(filename);
                                      volumeLabel = controller.isMl.value ? "$currentAmount ml" : "${(currentAmount / 29.5735).round()} oz";
                                      isLocked = false;
                                      originalCategory = "My Drink";
                                    } else {
                                      final Image img = drinks[originalIndex] as Image;
                                      drinkImage = img;
                                      filename = _getFilenameFromImage(img);
                                      displayName = _getDrinkName(filename.toLowerCase());
                                      factor = _getDrinkFactor(filename.toLowerCase());
                                      currentAmount = controller.getDrinkAmount(filename);
                                      volumeLabel = controller.isMl.value ? "$currentAmount ml" : "${(currentAmount / 29.5735).round()} oz";

                                      if (category == "Favorite") {
                                        for (final entry in controller.allType.entries) {
                                          if (entry.key != "More" && entry.key != "Favorite") {
                                            for (int i = 0; i < entry.value.length; i++) {
                                              final drink = entry.value[i];
                                              if (drink is Image && _getFilenameFromImage(drink) == filename) {
                                                originalCategory = entry.key;
                                                originalDrinkIndex = i;
                                                break;
                                              }
                                            }
                                          }
                                          if (originalCategory != category) break;
                                        }
                                      }
                                      isLocked = !false && originalDrinkIndex > 0;
                                    }

                                    Widget card = Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12.r),
                                        border: Border.all(color: AppColors.grey3, width: 1),
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.all(8.w),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  volumeLabel,
                                                  style: TextStyle(fontSize: 10.sp, color: AppColors.black1, fontWeight: FontWeight.w600),
                                                ),
                                                GestureDetector(
                                                  behavior: HitTestBehavior.opaque,
                                                  onTap: () {
                                                    if (isLocked) {
                                                      Get.toNamed(AppRoutes.premium);
                                                    } else {
                                                      controller.toggleFavoriteDrink(displayName);
                                                    }
                                                  },
                                                  child: Padding(
                                                    padding: EdgeInsets.all(4.w),
                                                    child: Obx(() {
                                                      final isFav = controller.favoriteDrinks.contains(displayName);
                                                      return Image.asset(
                                                        isFav ? "assets/images/png/fill_like.png" : "assets/images/png/like.png",
                                                        scale: 3.5,
                                                      );
                                                    }),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Expanded(
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  SizedBox(height: 50.h, child: drinkImage),
                                                  SizedBox(height: 4.h),
                                                  Text(
                                                    displayName,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(fontSize: 11.sp, color: AppColors.grey4, fontWeight: FontWeight.w500),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );

                                    if (isLocked) {
                                      card = Opacity(opacity: 0.35, child: card);
                                    }

                                    return GestureDetector(
                                      onTap: () {
                                        if (isLocked) {
                                          Get.toNamed(AppRoutes.premium);
                                        } else {
                                          _showCupIntakeAdjustDialog(
                                            context,
                                            controller,
                                            originalIndex,
                                            currentAmount,
                                            drinkImage,
                                            displayName,
                                            originalCategory,
                                            filename,
                                            factor,
                                          );
                                        }
                                      },
                                      child: card,
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  void _showCupIntakeAdjustDialog(
    BuildContext context,
    HomeController controller,
    int index,
    int initialAmount,
    Widget fillAsset,
    String displayName,
    String categoryKey,
    String filename,
    double factor,
  ) {
    final bool isMl = controller.isMl.value;
    final RxDouble currentAmountVal = (isMl ? initialAmount.toDouble() : (initialAmount / 29.5735)).obs;

    final String category = categoryKey.toLowerCase();
    List<String> descriptions = [];

    if (category == AppString.categoryWater.tr.toLowerCase()) {
      descriptions = [AppString.waterProvidesDesc1.tr, AppString.waterProvidesDesc2.tr];
    } else if (category == AppString.categoryTea.tr.toLowerCase()) {
      descriptions = [AppString.teaProvidesDesc1.tr, AppString.teaProvidesDesc2.tr];
    } else if (category == AppString.categoryCoffee.tr.toLowerCase()) {
      descriptions = [AppString.coffeeProvidesDesc1.tr, AppString.coffeeProvidesDesc2.tr];
    } else if (category == AppString.categoryMilk.tr.toLowerCase()) {
      descriptions = [AppString.milkProvidesDesc1.tr, AppString.milkProvidesDesc2.tr];
    } else if (category == AppString.categoryJuice.tr.toLowerCase()) {
      descriptions = [AppString.juiceProvidesDesc1.tr, AppString.juiceProvidesDesc2.tr];
    } else {
      descriptions = [AppString.defaultProvidesDesc1.tr, AppString.defaultProvidesDesc2.tr];
    }

    final List<double> quickSelectValues = isMl ? [50, 100, 150, 200, 250, 300, 350, 400, 450, 500] : [2, 4, 6, 8, 10, 12, 14, 16, 18, 20];

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44.w,
                      height: 44.w,
                      decoration: const BoxDecoration(color: Color(0xffEFF6FF), shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: SizedBox(width: 28.w, height: 28.w, child: fillAsset),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        displayName,
                        style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: const Color(0xff6C757D)),
                      ),
                    ),
                    Obx(() {
                      final isFav = controller.favoriteDrinks.contains(displayName);
                      return GestureDetector(
                        onTap: () {
                          controller.toggleFavoriteDrink(displayName);
                        },
                        child: Image.asset(isFav ? "assets/images/png/fill_like.png" : "assets/images/png/like.png", scale: 2.5),
                      );
                    }),
                  ],
                ),
                SizedBox(height: 12.h),
                ...descriptions.map(
                  (desc) => Padding(
                    padding: EdgeInsets.only(bottom: 6.h, left: 4.w),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: EdgeInsets.only(top: 3.h),
                          width: 5.w,
                          height: 5.w,
                          decoration: const BoxDecoration(color: Color(0xff6C757D), shape: BoxShape.circle),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            desc,
                            style: TextStyle(fontSize: 12.sp, color: const Color(0xff6C757D)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
                Center(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (isMl) {
                                if (currentAmountVal.value > 10) {
                                  currentAmountVal.value -= 10;
                                }
                              } else {
                                if (currentAmountVal.value > 0.5) {
                                  currentAmountVal.value -= 0.5;
                                }
                              }
                            },
                            child: Container(
                              width: 32.w,
                              height: 32.w,
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.primary, width: 1.5),
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              alignment: Alignment.center,
                              child: Icon(Icons.remove, color: AppColors.primary, size: 18.sp),
                            ),
                          ),
                          SizedBox(width: 16.w),
                          Column(
                            children: [
                              Obx(
                                () => Text(
                                  isMl ? currentAmountVal.value.round().toString() : currentAmountVal.value.toStringAsFixed(1),
                                  style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.bold, color: const Color(0xff212529)),
                                ),
                              ),
                              Container(width: 80.w, height: 1.5.h, color: const Color(0xffE6E6E6)),
                              Text(
                                isMl
                                    ? "${AppString.maxLimit.tr}: 3000 ${AppString.ml.tr}"
                                    : "${AppString.maxLimit.tr}: 100 ${AppString.oz.tr}",
                                style: TextStyle(fontSize: 11.sp, color: const Color(0xff8596AB)),
                              ),
                            ],
                          ),
                          SizedBox(width: 16.w),
                          GestureDetector(
                            onTap: () {
                              if (isMl) {
                                if (currentAmountVal.value < 3000) {
                                  currentAmountVal.value += 10;
                                }
                              } else {
                                if (currentAmountVal.value < 100) {
                                  currentAmountVal.value += 0.5;
                                }
                              }
                            },
                            child: Container(
                              width: 32.w,
                              height: 32.w,
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.primary, width: 1.5),
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              alignment: Alignment.center,
                              child: Icon(Icons.add, color: AppColors.primary, size: 18.sp),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            isMl ? "ml" : "oz",
                            style: TextStyle(fontSize: 14.sp, color: const Color(0xff6C757D), fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      SizedBox(height: 6.h),
                      SizedBox(height: 12.h),
                      Obx(() {
                        final double absorbed = currentAmountVal.value * factor;
                        return Text(
                          isMl
                              ? "(${AppString.amountOfAbsorbedWater.tr}: ${absorbed.round()} ${AppString.ml.tr})"
                              : "(${AppString.amountOfAbsorbedWater.tr}: ${absorbed.toStringAsFixed(1)} ${AppString.oz.tr})",
                          style: TextStyle(fontSize: 13.sp, color: const Color(0xff495057)),
                        );
                      }),
                    ],
                  ),
                ),
                SizedBox(height: 24.h),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    childAspectRatio: 1.4,
                    crossAxisSpacing: 8.w,
                    mainAxisSpacing: 8.h,
                  ),
                  itemCount: quickSelectValues.length,
                  itemBuilder: (context, gridIndex) {
                    final val = quickSelectValues[gridIndex];
                    return Obx(() {
                      final bool isSelected = isMl
                          ? (currentAmountVal.value.round() == val.round())
                          : ((currentAmountVal.value - val).abs() < 0.1);
                      return GestureDetector(
                        onTap: () {
                          currentAmountVal.value = val;
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.tealSoft : Colors.white,
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(color: isSelected ? AppColors.primary : const Color(0xffE6E6E6), width: 1),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            isMl ? val.round().toString() : val.toStringAsFixed(0),
                            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.normal, color: const Color(0xff495057)),
                          ),
                        ),
                      );
                    });
                  },
                ),
                SizedBox(height: 24.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        AppString.cancel.tr,
                        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: const Color(0xff6C757D)),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    TextButton(
                      onPressed: () {
                        final double val = currentAmountVal.value;
                        final int amountMl = isMl ? val.round() : (val * 29.5735).round();

                        // Save the customized amount for this specific drink type
                        controller.setDrinkAmount(filename, amountMl);

                        controller.customDrinkType.value = displayName;
                        controller.selectedCup.value = amountMl;
                        // Update the drink type asset (shown on the right action button)
                        final assetGen = _getAssetGenImageForDrink(filename);
                        if (assetGen != null) {
                          controller.selectedDrinkAsset.value = assetGen;
                        }
                        controller.selectedCupIndex.value = -2;

                        // Also update the selected cup asset based on the drink type's default cup size
                        final int defIdx = _getDefaultCupIndexForDrink(filename);
                        if (defIdx >= 0 && defIdx < controller.availableCups.length) {
                          final fillAsset = defIdx < controller.selectedCupList.length
                              ? controller.selectedCupList[defIdx]
                              : Assets.images.png.cup9;
                          controller.selectedCupAsset.value = fillAsset;
                          controller.selectedCupIndex.value = defIdx;
                        }

                        // Add to recent drinks list
                        controller.addRecentDrink(filename);

                        Navigator.of(context).pop();
                        Get.back();
                      },
                      child: Text(
                        AppString.ok.tr,
                        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCustomizeCupBottomSheet(BuildContext context, HomeController controller, {int? initialIndex, String? preselectedCategory}) {
    final TextEditingController textController = TextEditingController();
    final TextEditingController nameController = TextEditingController();

    int preselectedIconIndex = 7; // Default to the 8th icon (index 7)
    String initialDrinkType = "All";

    if (preselectedCategory != null) {
      initialDrinkType = preselectedCategory;
      if (preselectedCategory == "Water") {
        preselectedIconIndex = 3;
      } else if (preselectedCategory == "Tea") {
        preselectedIconIndex = 5;
      } else if (preselectedCategory == "Coffee") {
        preselectedIconIndex = 4;
      } else if (preselectedCategory == "Milk") {
        preselectedIconIndex = 3;
      } else if (preselectedCategory == "Juice") {
        preselectedIconIndex = 3;
      }
    }

    if (initialIndex != null && initialIndex > 6 && (initialIndex - 7) < controller.customCupAssetList.length) {
      AssetGenImage savedAsset = controller.customCupAssetList[initialIndex - 7];
      int foundIndex = controller.cupDesignAssets.indexOf(savedAsset);
      if (foundIndex != -1) {
        preselectedIconIndex = foundIndex;
      }
      // Set existing name if editing
      if (initialIndex < controller.availableCupTypes.length) {
        String existingName = controller.availableCupTypes[initialIndex].split('#').first;
        nameController.text = existingName.tr;
        if (["All", "Water", "Coffee", "Tea", "Milk", "Juice", "Beer"].contains(existingName)) {
          initialDrinkType = existingName;
        }
      }
    }

    final RxInt dialogSelectedIndex = preselectedIconIndex.obs;
    final RxString selectedDrinkType = initialDrinkType.obs;

    if (initialIndex != null && initialIndex < controller.availableCups.length) {
      textController.text = controller.availableCups[initialIndex].toString();
    }

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  margin: EdgeInsetsGeometry.symmetric(vertical: 8.h),
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(color: const Color(0xffE9ECEF), borderRadius: BorderRadius.circular(2.r)),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      "Customize your water cup",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle.latoBoldPrimary16.copyWith(fontSize: 18.sp, color: const Color(0xff394453)),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Obx(() {
                final currentType = selectedDrinkType.value;
                return SizedBox(
                  height: 30.h,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildDrinkTypeChip("All", currentType == "All", () {
                        selectedDrinkType.value = "All";
                        dialogSelectedIndex.value = 7; // Default cup icon
                      }),
                      SizedBox(width: 10.w),
                      _buildDrinkTypeChip("Water", currentType == "Water", () {
                        selectedDrinkType.value = "Water";
                        dialogSelectedIndex.value = 3; // Glass standard icon
                      }),
                      SizedBox(width: 10.w),
                      _buildDrinkTypeChip("Coffee", currentType == "Coffee", () {
                        selectedDrinkType.value = "Coffee";
                        dialogSelectedIndex.value = 4; // Coffee Cup icon
                      }),
                      SizedBox(width: 10.w),
                      _buildDrinkTypeChip("Tea", currentType == "Tea", () {
                        selectedDrinkType.value = "Tea";
                        dialogSelectedIndex.value = 5; // Mug icon
                      }),
                      SizedBox(width: 10.w),
                      _buildDrinkTypeChip("Milk", currentType == "Milk", () {
                        selectedDrinkType.value = "Milk";
                        dialogSelectedIndex.value = 3; // Glass standard icon
                      }),
                      SizedBox(width: 10.w),
                      _buildDrinkTypeChip("Juice", currentType == "Juice", () {
                        selectedDrinkType.value = "Juice";
                        dialogSelectedIndex.value = 3; // Glass standard icon
                      }),
                      SizedBox(width: 10.w),
                      _buildDrinkTypeChip("Beer", currentType == "Beer", () {
                        selectedDrinkType.value = "Beer";
                        dialogSelectedIndex.value = 6; // Bottle standard icon
                      }),
                    ],
                  ),
                );
              }),
              SizedBox(height: 12.h),
              Obx(() {
                dialogSelectedIndex.value; // Explicitly read to register Obx listener
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 0.95,
                    crossAxisSpacing: 2.w,
                    mainAxisSpacing: 0.h,
                  ),
                  itemCount: 9, // To match 3x3 layout
                  itemBuilder: (context, index) {
                    bool isInputField = index == 8;
                    bool isSelected = dialogSelectedIndex.value == index;
                    if (!isInputField) {
                      int? amount;
                      if (index < controller.availableCups.length) {
                        amount = controller.availableCups[index];
                      }

                      AssetGenImage itemAsset = index < controller.cupDesignAssets.length
                          ? controller.cupDesignAssets[index]
                          : Assets.images.png.cup;

                      AssetGenImage fillAsset = index < controller.selectedCupList.length
                          ? controller.selectedCupList[index]
                          : Assets.images.png.cup;

                      return GestureDetector(
                        onTap: () {
                          dialogSelectedIndex.value = index;
                        },
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              height: 70.h,
                              width: 80,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(child: (isSelected ? fillAsset : itemAsset).image(scale: 5)),
                                  SizedBox(height: 2.h),
                                  if (isSelected) Assets.images.png.shade.image(scale: 3.5),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    } else {
                      // The editable field
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: 20.h),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              SizedBox(
                                width: 40.w,
                                child: TextField(
                                  controller: textController,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  autofocus: false,
                                  inputFormatters: [LengthLimitingTextInputFormatter(6)],
                                  style: AppTextStyle.latoBoldPrimary16.copyWith(fontSize: 15.sp, color: AppColors.primary),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary.withOpacity(0.4))),
                                    focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
                                  ),
                                ),
                              ),
                              Text(
                                controller.isMl.value ? " ml" : " oz",
                                style: AppTextStyle.latoRegularBlack14.copyWith(
                                  fontSize: 13.sp,
                                  color: const Color(0xff394453),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    }
                  },
                );
              }),
              SizedBox(height: 10.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Obx(() {
                    dialogSelectedIndex.value; // Listen to force redraw
                    bool isExistingCustomCup = initialIndex != null && initialIndex > 6 && initialIndex < controller.availableCups.length;
                    bool isSelectedCup = initialIndex == controller.selectedCupIndex.value;

                    if (!isExistingCustomCup || isSelectedCup) return const SizedBox.shrink();

                    return GestureDetector(
                      onTap: () {
                        controller.removeCustomCupAtIndex(initialIndex, cupIndex: dialogSelectedIndex.value);
                        Get.back();
                        _showSwitchCupBottomSheet(context, controller);
                      },
                      child: Container(
                        decoration: BoxDecoration(color: const Color(0xffFEE2E2), borderRadius: BorderRadius.circular(48.r)),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                          child: Assets.images.png.delete1.image(scale: 3.5, color: const Color(0xffE41E3F)),
                        ),
                      ),
                    );
                  }),
                  Row(
                    children: [
                      TextButton(
                        style: TextButton.styleFrom(elevation: 0, shadowColor: Colors.transparent, backgroundColor: Colors.transparent),
                        onPressed: () {
                          Get.back();
                          _showSwitchCupBottomSheet(context, controller);
                        },
                        child: Text(
                          AppString.cancel.tr.toUpperCase(),
                          style: AppTextStyle.latoBoldPrimary16.copyWith(
                            fontSize: 14.sp,
                            color: const Color(0xff6C757D),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      TextButton(
                        style: TextButton.styleFrom(elevation: 0, shadowColor: Colors.transparent, backgroundColor: Colors.transparent),
                        onPressed: () {
                          int? customAmount = int.tryParse(textController.text);
                          String customName = selectedDrinkType.value;
                          if (customName.isEmpty) customName = AppString.customCup;

                          if (textController.text.isEmpty || customAmount == null || customAmount <= 0) {
                            Get.snackbar("Error", AppString.insZero.tr);
                            return;
                          }

                          AssetGenImage selectedAsset = dialogSelectedIndex.value != -1
                              ? controller.cupDesignAssets[dialogSelectedIndex.value]
                              : controller.cupDesignAssets[0];
                          AssetGenImage selectedFillAsset = dialogSelectedIndex.value != -1
                              ? controller.selectedCupList[dialogSelectedIndex.value]
                              : controller.selectedCupList[0];

                          if (initialIndex != null && initialIndex > 6 && initialIndex < controller.availableCups.length) {
                            controller.updateCustomCup(
                              initialIndex,
                              "$customName#${dialogSelectedIndex.value}",
                              customAmount,
                              selectedAsset,
                              selectedFillAsset,
                              Selectedcup: controller.selectedCupIndex.value,
                            );
                          } else {
                            controller.addCustomCup(
                              "$customName#${dialogSelectedIndex.value}",
                              customAmount,
                              selectedAsset,
                              selectedFillAsset,
                              Selectedcup: dialogSelectedIndex.value,
                            );
                          }
                          Get.back();
                          _showSwitchCupBottomSheet(context, controller);
                        },
                        child: Text(
                          AppString.ok.tr.toUpperCase(),
                          style: AppTextStyle.latoBoldPrimary16.copyWith(
                            fontSize: 14.sp,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  void _showSwitchCupBottomSheet(BuildContext context, HomeController controller) {
    final RxInt localSelectedIndex = controller.selectedCupIndex.value.obs;
    final RxString selectedDrinkType = "All".obs;

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin: EdgeInsetsGeometry.symmetric(vertical: 8.h),
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(color: const Color(0xffE9ECEF), borderRadius: BorderRadius.circular(2.r)),
              ),
            ),
            // SizedBox(height: 20.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Drink Type",
                  style: AppTextStyle.latoBoldPrimary16.copyWith(fontSize: 14.sp, color: const Color(0xff212529)),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.close, color: Color(0xff8596AB), size: 22),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Obx(() {
              final currentType = selectedDrinkType.value;
              return SizedBox(
                height: 30.h,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildDrinkTypeChip("All", currentType == "All", () => selectedDrinkType.value = "All"),
                    SizedBox(width: 10.w),
                    _buildDrinkTypeChip("Water", currentType == "Water", () => selectedDrinkType.value = "Water"),
                    SizedBox(width: 10.w),
                    _buildDrinkTypeChip("Coffee", currentType == "Coffee", () => selectedDrinkType.value = "Coffee"),
                    SizedBox(width: 10.w),
                    _buildDrinkTypeChip("Tea", currentType == "Tea", () => selectedDrinkType.value = "Tea"),
                    SizedBox(width: 10.w),
                    _buildDrinkTypeChip("Milk", currentType == "Milk", () => selectedDrinkType.value = "Milk"),
                    SizedBox(width: 10.w),
                    _buildDrinkTypeChip("Juice", currentType == "Juice", () => selectedDrinkType.value = "Juice"),
                    SizedBox(width: 10.w),
                    _buildDrinkTypeChip("Beer", currentType == "Beer", () => selectedDrinkType.value = "Beer"),
                  ],
                ),
              );
            }),
            SizedBox(height: 18.h),
            Obx(() {
              final selectedIndex = localSelectedIndex.value;
              return GridView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 0.9,
                  crossAxisSpacing: 10.w,
                  mainAxisSpacing: 10.h,
                ),
                itemCount: controller.availableCups.length + (controller.canAddCustomCup ? 1 : 0),
                itemBuilder: (context, index) {
                  bool isCustomizeSlot = index == controller.availableCups.length;

                  if (isCustomizeSlot) {
                    return _buildCupItemForBottomSheet(
                      label: AppString.customize.tr,
                      asset: Assets.images.png.cup9,
                      isSelected: false,
                      onTap: () {
                        Get.back();
                        _showCustomizeCupBottomSheet(context, controller);
                      },
                    );
                  }

                  int amount = controller.availableCups[index];
                  bool isCustomItem = index > 6;

                  AssetGenImage asset = isCustomItem && (index - 7) < controller.customCupAssetList.length
                      ? controller.customCupAssetList[index - 7]
                      : (index < controller.cupDesignAssets.length ? controller.cupDesignAssets[index] : Assets.images.png.cup9);
                  AssetGenImage fillAsset = isCustomItem && (index - 7) < controller.customCupFillAssetList.length
                      ? controller.customCupFillAssetList[index - 7]
                      : (index < controller.selectedCupList.length ? controller.selectedCupList[index] : Assets.images.png.cup9);

                  bool isSelected = selectedIndex == index;

                  return _buildCupItemForBottomSheet(
                    label: "$amount ${controller.isMl.value ? AppString.ml.tr : AppString.oz.tr}",
                    asset: asset,
                    fillAsset: fillAsset,
                    isSelected: isSelected,
                    showDelete: isCustomItem && index != controller.selectedCupIndex.value,
                    onDeleteTap: () {
                      Get.back();
                      _showCustomizeCupBottomSheet(context, controller, initialIndex: index);
                    },
                    onTap: () {
                      localSelectedIndex.value = index;
                    },
                  );
                },
              );
            }),
            SizedBox(height: 20.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 100.w,
                  height: 38.h,
                  child: ElevatedButton(
                    onPressed: () => Get.back(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xffEFF6FF),
                      foregroundColor: AppColors.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.r)),
                    ),
                    child: Text(
                      AppString.cancel.tr,
                      style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
                ),
                SizedBox(width: 20.w),
                SizedBox(
                  width: 100.w,

                  height: 38.h,
                  child: ElevatedButton(
                    onPressed: () {
                      int selected = localSelectedIndex.value;
                      if (selected < controller.availableCups.length) {
                        int amount = controller.availableCups[selected];
                        AssetGenImage fill = selected > 6 && (selected - 7) < controller.customCupFillAssetList.length
                            ? controller.customCupFillAssetList[selected - 7]
                            : (selected < controller.selectedCupList.length
                                  ? controller.selectedCupList[selected]
                                  : Assets.images.png.cup9);

                        controller.updateSelectedCup(amount, selected);
                        controller.selectedCupAsset.value = fill;
                      }
                      Get.back();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.r)),
                    ),
                    child: Text(
                      AppString.ok.tr,
                      style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Widget _buildCupItemForBottomSheet({
    required String label,
    required AssetGenImage asset,
    required VoidCallback onTap,
    bool isSelected = false,
    AssetGenImage? fillAsset,
    bool showDelete = false,
    VoidCallback? onDeleteTap,
  }) {
    Color color = isSelected ? AppColors.primary : const Color(0xff6C757D);
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              (isSelected && fillAsset != null ? fillAsset : asset).image(color: isSelected ? null : color, scale: 4.5),

              // SizedBox(height: 6.h),
              if (isSelected) Assets.images.png.shade.image(scale: 3.5),
              if (!isSelected) SizedBox(height: 6.h), // Placeholder
              // SizedBox(height: 5.h),
              Text(
                label,
                style: AppTextStyle.latoRegularBlack14.copyWith(fontSize: 11.sp, color: color, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        if (showDelete && onDeleteTap != null)
          Positioned(
            top: -2.h,
            right: 0.w,
            child: GestureDetector(
              onTap: onDeleteTap,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: EdgeInsets.all(8.w), // Increase hit area
                child: Assets.images.png.close.image(scale: 5, color: AppColors.grey4),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSecondaryActionButton({
    String? iconData,
    Widget? customIcon,
    bool showBadge = false,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 48.w,
                height: 48.w,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFF1F5F9)),
                child: Center(
                  child:
                      customIcon ??
                      (iconData != null
                          ? SvgPicture.asset(
                              iconData,
                              width: iconData.contains('glass') ? 30.w : 20.w,
                              height: iconData.contains('glass') ? 30.w : 20.w,
                            )
                          : const SizedBox()),
                ),
              ),
              if (showBadge)
                Positioned(
                  bottom: -2,
                  right: -4,
                  child: Container(
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: AppColors.cardEdge, width: 1.5),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
                    ),
                    child: Center(child: Assets.images.png.exchange.image(scale: 4.5, color: AppColors.teal)),
                  ),
                ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(label, style: AppTypography.actionLabel),
        ],
      ),
    );
  }

  Widget _buildPrimaryLogButton(HomeController controller) {
    return Obx(() {
      final int current = controller.currentIntake.value;
      final int target = controller.targetIntake.value;
      final bool isGoalAchieved = target > 0 && current >= target;

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: isGoalAchieved
            ? () {
                Get.snackbar(
                  AppString.goalAchieved.tr,
                  AppString.goalAchievedDesc.tr,
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: AppColors.tealDeep.withOpacity(0.95),
                  colorText: Colors.white,
                  margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
                  borderRadius: 16.r,
                  duration: const Duration(seconds: 3),
                );
              }
            : () {
                int amount = controller.selectedCup.value;
                final int remaining = target - current;
                bool isCapped = false;
                int originalAmount = amount;

                if (amount > remaining) {
                  amount = remaining;
                  isCapped = true;
                }

                String type = "Cup";
                if (controller.selectedCupIndex.value < controller.availableCupTypes.length) {
                  type = controller.availableCupTypes[controller.selectedCupIndex.value];

                  if (!type.contains('#')) {
                    type = "$type#${controller.selectedCupIndex.value}";
                  }
                }
                String drinkType = _getFilenameFromAsset(controller.selectedDrinkAsset.value);
                controller.addWater(amount, type, drinkType: drinkType);

                if (isCapped) {
                  final String unit = controller.isMl.value ? 'ml' : 'oz';
                  Get.snackbar(
                    AppString.amountCapped.tr,
                    AppString.amountCappedDesc.tr
                        .replaceAll('@originalAmount', originalAmount.toString())
                        .replaceAll('@unit', unit)
                        .replaceAll('@amount', amount.toString()),
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: AppColors.tealDeep.withOpacity(0.95),
                    colorText: Colors.white,
                    margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
                    borderRadius: 16.r,
                    duration: const Duration(seconds: 4),
                  );
                }
              },
        child: AnimatedScale(
          scale: 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: Alignment(-0.4, -0.4),
                radius: 0.95,
                colors: [AppColors.tealBright, AppColors.teal, AppColors.tealDeep],
                stops: [0.0, 0.6, 1.0],
              ),
              boxShadow: isGoalAchieved ? [] : AppShadows.drinkButton,
              border: Border.all(color: Colors.white.withOpacity(0.18), width: 1),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (!isGoalAchieved)
                  Positioned.fill(
                    child: CustomPaint(painter: _DashedRingPainter(color: AppColors.teal.withOpacity(0.25), inset: -8)),
                  ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(isGoalAchieved ? Icons.check_circle_outline_rounded : Icons.add_rounded, color: Colors.white, size: 22),
                    const SizedBox(height: 3),
                    Text(isGoalAchieved ? AppString.completedUpper.tr : AppString.logDrink.tr, style: AppTypography.drinkBtnLabel),
                    if (!isGoalAchieved) ...[
                      const SizedBox(height: 2),
                      Text('+${controller.selectedCup.value} ${controller.isMl.value ? "ml" : "oz"}', style: AppTypography.drinkBtnMl),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  String getVesselLabel(int amount, int index, bool isMl) {
    if (!isMl) {
      switch (amount) {
        case 3:
          return AppString.small.tr;
        case 4:
          return AppString.glass.tr;
        case 5:
          return AppString.mug.tr;
        case 6:
          return AppString.large.tr;
        case 7:
          return AppString.bottle.tr;
        case 10:
          return AppString.bigBottle.tr;
        default:
          return AppString.custom.tr;
      }
    } else {
      switch (amount) {
        case 100:
        case 125:
        case 150:
          return AppString.small.tr;
        case 175:
        case 200:
        case 250:
          return AppString.glass.tr;
        case 300:
        case 350:
          return AppString.mug.tr;
        case 500:
          return AppString.large.tr;
        case 750:
          return AppString.bottle.tr;
        case 1000:
          return AppString.bigBottle.tr;
        default:
          return AppString.custom.tr;
      }
    }
  }

  Widget _buildDrinkTypeChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0EA5E9) : Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: isSelected ? const Color(0xFF0EA5E9) : const Color(0xFFE2E8F0)),
          boxShadow: isSelected
              ? [BoxShadow(color: const Color(0xFF0EA5E9).withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2))]
              : [],
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.interTight(
              fontSize: 13.sp,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSmallButton({required Widget asset, required String label, required VoidCallback onTap, required bool isLeft}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 50.w,
                width: 50.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: const Color(0xffE6E6E6)),
                  boxShadow: [BoxShadow(color: const Color(0xff212529).withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Center(child: asset),
              ),
              Positioned(
                bottom: -10,
                left: isLeft ? null : 28.w,
                right: isLeft ? 28.w : null,
                child: GestureDetector(
                  child: Container(
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: AppColors.grey3, width: 2),
                      boxShadow: [BoxShadow(color: const Color(0xff212529).withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
                    ),
                    child: Center(child: Assets.images.png.exchange.image(scale: 3.5, color: AppColors.primary)),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 11.h),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyle.h1.copyWith(fontSize: 10.sp, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildLargeDrinkButton(HomeController controller) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            int amount = controller.selectedCup.value;
            String type = "Cup";
            if (controller.selectedCupIndex.value < controller.availableCupTypes.length) {
              type = controller.availableCupTypes[controller.selectedCupIndex.value];
              if (!type.contains('#')) {
                type = "$type#${controller.selectedCupIndex.value}";
              }
            }
            String drinkType = _getFilenameFromAsset(controller.selectedDrinkAsset.value);
            controller.addWater(amount, type, drinkType: drinkType);
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 70.w,
                height: 70.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xff212529).withOpacity(0.15),
                      blurRadius: 15,
                      spreadRadius: 2,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
              ),
              Container(
                width: 60.w,
                height: 60.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xffE6E6E6), width: 1),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, color: Colors.white, size: 24.sp),
                  Text(
                    AppString.drinkText.tr,
                    style: AppTextStyle.body.copyWith(fontSize: 10.sp, color: AppColors.white),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 9.h),
        Text(
          AppString.tapToDrink.tr,
          style: AppTextStyle.h2.copyWith(fontSize: 10.sp, fontWeight: FontWeight.bold, color: AppColors.primary),
        ),
        Obx(
          () => Text(
            "${controller.selectedCup.value} ${controller.isMl.value ? AppString.ml.tr : AppString.oz.tr}",
            style: AppTextStyle.body.copyWith(fontSize: 10.sp, color: AppColors.primary, fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({bool hasPadding = true}) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: hasPadding ? 20.w : 0),
      padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 15.w),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        // mainAxisSize: MainAxisSize.min,
        children: [
          Assets.images.png.dropletHalf.image(scale: 2, color: AppColors.grey4),
          SizedBox(height: 10.h),
          Text(
            AppString.noRecords.tr,
            style: AppTextStyle.button.copyWith(fontSize: 15.sp, color: AppColors.black2, fontWeight: FontWeight.w600),
          ),
          // SizedBox(height: 5.h),
          Text(
            AppString.startTrackingDesc.tr,
            textAlign: TextAlign.center,
            style: AppTextStyle.body.copyWith(fontSize: 13.sp, color: AppColors.grey4),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection(HomeController controller) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppString.history.tr, style: AppTypography.sectionTitle),
              GestureDetector(
                onTap: () => Get.find<DashboardController>().changeIndex(1),
                child: Text(AppString.viewAll.tr.toUpperCase(), style: AppTypography.viewAll),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          StreamBuilder<List<WaterRecord>>(
            stream: controller.todayRecordsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                return const Center(child: CupertinoActivityIndicator());
              }
              final records = snapshot.data ?? [];
              return Column(
                children: [
                  if (records.isEmpty)
                    _buildEmptyState(hasPadding: false)
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: records.length,
                      separatorBuilder: (context, index) => SizedBox(height: 10.h),
                      itemBuilder: (context, index) {
                        final record = records[index];
                        return _buildHistoryItem(record, controller);
                      },
                    ),
                  SizedBox(height: 15.h),
                  const CommonBannerAd(),
                  SizedBox(height: 20.h),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  String _getVesselName(String type, int amount) {
    final rawName = type.split('#').first.trim();
    if (rawName.isEmpty) {
      return amount >= 500 ? AppString.bottle.tr : AppString.cup.tr;
    }
    return rawName.tr;
  }
  //
  // String _getDrinkName(String? drinkType) {
  //   if (drinkType == null || drinkType.isEmpty) return AppString.plainWater.tr;
  //   if (drinkType.startsWith('my_drink_')) return drinkType.replaceAll('my_drink_', '');
  //
  //   switch (drinkType) {
  //     case 'plainWater': return AppString.plainWater.tr;
  //     case 'sparklingWater': return AppString.sparklingWater.tr;
  //     case 'mineralWater': return AppString.mineralWater.tr;
  //     case 'sportDrink': return AppString.sportDrink.tr;
  //     case 'zeroSportDrink': return AppString.zeroSportDrink.tr;
  //     case 'riceDrink': return AppString.riceDrink.tr;
  //     case 'barleyDrink': return AppString.barleyDrink.tr;
  //     case 'energyDrink': return AppString.energyDrink.tr;
  //     case 'tea': return AppString.tea.tr;
  //     case 'milkTea': return AppString.milkTea.tr;
  //     case 'blackTea': return AppString.blackTea.tr;
  //     case 'greenTea': return AppString.greenTea.tr;
  //     case 'coffee': return AppString.coffee.tr;
  //     case 'cappuccinoCoffee': return AppString.cappuccinoCoffee.tr;
  //     case 'mochaCoffee': return AppString.mochaCoffee.tr;
  //     case 'milk': return AppString.categoryMilk.tr;
  //     case 'lowFatMilk': return AppString.lowFatMilk.tr;
  //     case 'juice': return AppString.categoryJuice.tr;
  //     case 'orangeJuice': return AppString.orangeJuice.tr;
  //     case 'lemonJuice': return AppString.lemonJuice.tr;
  //     case 'pineappleJuice': return AppString.pineappleJuice.tr;
  //     case 'watermelonJuice': return AppString.watermelonJuice.tr;
  //     case 'peachJuice': return AppString.peachJuice.tr;
  //     case 'strawberryJuice': return AppString.strawberryJuice.tr;
  //     case 'coconutJuice': return AppString.coconutJuice.tr;
  //     case 'appleJuice': return AppString.appleJuice.tr;
  //     case 'carrotJuice': return AppString.carrotJuice.tr;
  //     case 'wine': return 'Wine'.tr;
  //     case 'beer': return 'Beer'.tr;
  //     case 'cocktail': return 'Cocktail'.tr;
  //     case 'champagne': return 'Champagne'.tr;
  //     case 'yogurt': return 'Yogurt'.tr;
  //     case 'smoothie': return 'Smoothie'.tr;
  //     case 'milkshake': return 'Milkshake'.tr;
  //     default: return AppString.plainWater.tr;
  //   }
  // }

  String _getLiquidName(String type, int amount, String? drinkType) {
    if (drinkType != null && drinkType.isNotEmpty) {
      return _getDrinkName(drinkType);
    }
    final rawName = type.split('#').first.trim().toLowerCase();
    if (rawName.contains('coffee') || rawName.contains('kahve')) {
      return AppString.coffee.tr;
    } else if (rawName.contains('tea') || rawName.contains('çay') || rawName.contains('mug') || rawName.contains('kupa')) {
      return AppString.tea.tr;
    } else if (rawName.contains('bottle') || rawName.contains('şişe') || rawName.contains('jug') || rawName.contains('sürahi')) {
      return AppString.mineralWater.tr;
    } else {
      return AppString.plainWater.tr;
    }
  }

  Widget _buildHistoryItem(WaterRecord record, HomeController controller) {
    final rawTypeName = record.type.split('#').first;
    final typeName = rawTypeName.toLowerCase();

    final vessel = _getVesselName(record.type, record.amount);
    final liquid = _getLiquidName(record.type, record.amount, record.drinkType);

    Color tileFg;
    Color tileBg;

    if (typeName == 'bottle' || typeName == 'custom cup') {
      tileFg = AppColors.accent;
      tileBg = AppColors.accentSoft;
    } else if (typeName == 'mug' || typeName == 'glass' || typeName == 'coffee cup') {
      tileFg = AppColors.gold;
      tileBg = AppColors.goldSoft;
    } else {
      tileFg = AppColors.teal;
      tileBg = AppColors.tealSoft;
    }

    Widget iconWidget;
    if (record.drinkType != null && record.drinkType!.isNotEmpty) {
      final assetGen = _getAssetGenImageForDrink(record.drinkType!);
      if (assetGen != null) {
        iconWidget = assetGen.image(height: 28.w, width: 28.w, fit: BoxFit.contain);
      } else if (record.drinkType!.startsWith('my_drink_')) {
        iconWidget = Assets.images.png.cupFill1.image(height: 28.w, width: 28.w, fit: BoxFit.contain, color: tileFg);
      } else {
        iconWidget = controller.getIconForType(record.type).image(height: 28.w, width: 28.w, fit: BoxFit.contain, color: tileFg);
      }
    } else {
      iconWidget = controller.getIconForType(record.type).image(height: 28.w, width: 28.w, fit: BoxFit.contain, color: tileFg);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.cardEdge),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            height: 38.w,
            width: 38.w,
            decoration: BoxDecoration(color: tileBg, borderRadius: BorderRadius.circular(12)),
            alignment: Alignment.center,
            child: iconWidget,
          ),
          SizedBox(width: 15.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    style: AppTypography.historyAmount,
                    children: [
                      TextSpan(text: '${record.amount}'),
                      TextSpan(text: ' ${controller.isMl.value ? AppString.ml.tr : AppString.oz.tr}', style: AppTypography.historyUnit),
                    ],
                  ),
                ),
                Text('$vessel • $liquid', style: AppTypography.historyType),
              ],
            ),
          ),

          Text(DateFormat('hh:mm a', Get.locale?.toString() ?? 'en_US').format(record.createdAt), style: AppTypography.historyTime),

          SizedBox(width: 11.w),

          GestureDetector(
            onTap: () => controller.deleteRecord(record),
            child: Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(color: AppColors.paperWarm, shape: BoxShape.circle),
              child: const Icon(Icons.delete_outline_rounded, size: 14, color: AppColors.inkMute),
            ),
          ),
        ],
      ),
    );
  }

  void _showAdjustIntakeGoalDialog(BuildContext context, HomeController controller) {
    final RxInt tempGoal = controller.targetIntake.value.obs;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          padding: EdgeInsets.only(left: 24.w, right: 24.w, top: 10.h, bottom: MediaQuery.of(context).viewInsets.bottom + 24.h),
          child: Obx(() {
            final double minVal = controller.isMl.value ? 500 : 17;
            final double maxVal = controller.isMl.value ? 5000 : 170;
            final double val = tempGoal.value.toDouble().clamp(minVal, maxVal);

            // Calculate cups and equivalent text
            final int cups = (tempGoal.value / (controller.isMl.value ? 250 : 8)).round();
            final String equivText = controller.isMl.value
                ? "${(tempGoal.value / 1000.0).toStringAsFixed(1)}L"
                : "${(tempGoal.value * 0.0078125).toStringAsFixed(1)} gal";

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 35.w,
                    height: 4.h,
                    decoration: BoxDecoration(color: const Color(0xFFE2DDD5), borderRadius: BorderRadius.circular(2.r)),
                  ),
                ),
                SizedBox(height: 16.h),

                // Title & Info Icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppString.intakeGoalUpper.tr,
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xff8596AB),
                            letterSpacing: 1.2,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text.rich(
                          TextSpan(
                            style: AppTypography.eyebrow,
                            children: [
                              TextSpan(text: AppString.setHydrationPrefix.tr, style: AppTypography.sectionTitle),
                              TextSpan(text: AppString.setHydrationTarget.tr, style: AppTypography.sectionTitleItalic),
                              if (AppString.setHydrationSuffix.tr.isNotEmpty)
                                TextSpan(text: AppString.setHydrationSuffix.tr, style: AppTypography.sectionTitle),
                            ],
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        Get.back();
                        Get.toNamed(AppRoutes.intakeGoalInfo);
                      },
                      child: Assets.images.png.profileInfo.image(scale: 4.5, color: const Color(0xff8596AB)),
                    ),
                  ],
                ),
                SizedBox(height: 24.h),

                // Card display with plus/minus buttons
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.cardEdge),
                    boxShadow: AppShadows.level1,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Minus Button
                      GestureDetector(
                        onTap: () {
                          int step = controller.isMl.value ? 50 : 2;
                          tempGoal.value = (tempGoal.value - step).clamp(minVal.toInt(), maxVal.toInt());
                        },
                        child: Container(
                          width: 44.w,
                          height: 44.w,
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFEAF5F7)),
                          child: Icon(Icons.remove, color: AppColors.teal, size: 20.sp),
                        ),
                      ),

                      // Center Display Value
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                NumberFormat('#,###', Get.locale?.toString() ?? 'en_US').format(tempGoal.value),
                                style: TextStyle(
                                  fontSize: 32.sp,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xff212529),
                                  fontFamily: AppFonts.lato,
                                ),
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                controller.isMl.value ? AppString.ml.tr : AppString.oz.tr,
                                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: const Color(0xff969593)),
                              ),
                            ],
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            "≈ $cups ${AppString.cups.tr} • $equivText",
                            style: TextStyle(fontSize: 12.sp, color: const Color(0xff718096), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),

                      // Plus Button
                      GestureDetector(
                        onTap: () {
                          int step = controller.isMl.value ? 50 : 2;
                          tempGoal.value = (tempGoal.value + step).clamp(minVal.toInt(), maxVal.toInt());
                        },
                        child: Container(
                          width: 44.w,
                          height: 44.w,
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFEAF5F7)),
                          child: Icon(Icons.add, color: AppColors.teal, size: 20.sp),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24.h),

                // Slider
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 6,
                    activeTrackColor: AppColors.teal,
                    inactiveTrackColor: AppColors.paperWarm,
                    thumbColor: AppColors.tealBright,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 11),
                    overlayColor: AppColors.tealSoft,
                    trackShape: const RoundedRectSliderTrackShape(),
                    showValueIndicator: ShowValueIndicator.never,
                  ),
                  child: Slider(
                    value: val,
                    min: minVal,
                    max: maxVal,
                    onChanged: (value) {
                      if (controller.isMl.value) {
                        tempGoal.value = (value / 50).round() * 50;
                      } else {
                        tempGoal.value = value.round();
                      }
                      tempGoal.value = tempGoal.value.clamp(minVal.toInt(), maxVal.toInt());
                    },
                  ),
                ),
                SizedBox(height: 4.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      controller.isMl.value ? "0.5 L" : "17 oz",
                      style: TextStyle(fontSize: 11.sp, color: const Color(0xff8A939F), fontWeight: FontWeight.w500),
                    ),
                    Text(
                      controller.isMl.value ? "5 L" : "170 oz",
                      style: TextStyle(fontSize: 11.sp, color: const Color(0xff8A939F), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                SizedBox(height: 24.h),

                // Quick Presets
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: (() {
                    final List<int> presets = controller.isMl.value ? [1500, 2000, 2500, 3000, 3500] : [50, 70, 85, 100, 120];
                    final List<String> labels = controller.isMl.value
                        ? ["1.5 L", "2 L", "2.5 L", "3 L", "3.5 L"]
                        : ["50 oz", "70 oz", "85 oz", "100 oz", "120 oz"];

                    return List.generate(presets.length, (index) {
                      final bool isSelected = tempGoal.value == presets[index];
                      return GestureDetector(
                        onTap: () {
                          tempGoal.value = presets[index];
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF073F4D) : Colors.white,
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: isSelected ? const Color(0xFF073F4D) : const Color(0xFFE2E8F0)),
                          ),
                          child: Text(
                            labels[index],
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : const Color(0xFF4A5568),
                            ),
                          ),
                        ),
                      );
                    });
                  })(),
                ),
                SizedBox(height: 32.h),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: AppColors.card,
                            foregroundColor: AppColors.ink,
                            side: const BorderSide(color: AppColors.cardEdge),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            padding: EdgeInsets.zero,
                          ),
                          child: Text(AppString.cancel.tr, style: AppTypography.actionLabel.copyWith(fontSize: 15, letterSpacing: 0.3)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppColors.tealBright, AppColors.tealDeep],
                          ),
                          boxShadow: [BoxShadow(color: AppColors.teal.withOpacity(0.32), blurRadius: 18, offset: const Offset(0, 8))],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () {
                              controller.updateGoal(tempGoal.value);
                              Get.back();
                            },
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check_rounded, color: Colors.white, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    AppString.saveGoal.tr,
                                    style: AppTypography.actionLabel.copyWith(color: Colors.white, fontSize: 15, letterSpacing: 0.3),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          }),
        );
      },
    );
  }

  Widget _buildStatsCard(HomeController controller) {
    // 1. Cups Calculation
    int currentCups = controller.waterRecords.length;
    int targetCups = (controller.targetIntake.value / (controller.isMl.value ? 250 : 8)).round();
    if (targetCups == 0) targetCups = 8;

    // 2. Since Last Drink Calculation
    String sinceLastText = "--";
    if (controller.waterRecords.isNotEmpty) {
      final lastDrinkTime = controller.waterRecords.first.createdAt;
      final difference = DateTime.now().difference(lastDrinkTime);
      final hours = difference.inMinutes / 60.0;
      sinceLastText = hours.toStringAsFixed(1);
    }

    // 3. Weekly Average Calculation
    double weeklyAvg = 0.0;
    if (controller.statsData.value != null &&
        controller.statsData.value!.data != null &&
        controller.statsData.value!.data!.chartData.isNotEmpty) {
      final last7Days = controller.statsData.value!.data!.chartData.take(7);
      double sum = last7Days.fold<double>(0.0, (prev, element) => prev + (element.completionPct ?? 0.0));
      weeklyAvg = sum / last7Days.length;
    } else {
      weeklyAvg = 0.0; // visual default placeholder
    }
    if (weeklyAvg > 100.0) weeklyAvg = 100.0;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cardEdge),
        boxShadow: AppShadows.level1,
      ),
      child: Row(
        children: [
          // Cups Column
          Expanded(
            child: Column(
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(text: "$currentCups", style: AppTypography.statValue),
                      TextSpan(text: " / $targetCups", style: AppTypography.statSmall),
                    ],
                  ),
                ),
                SizedBox(height: 4.h),
                Text(AppString.cupsUpper.tr, style: AppTypography.statLabel),
              ],
            ),
          ),

          // Divider
          Container(width: 1.w, height: 32.h, color: AppColors.cardEdge),

          // Since Last Column
          Expanded(
            child: Column(
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(text: sinceLastText, style: AppTypography.statValue),
                      TextSpan(text: " ${AppString.hoursUnit.tr}", style: AppTypography.statSmall),
                    ],
                  ),
                ),
                SizedBox(height: 4.h),
                Text(AppString.sinceLast.tr, style: AppTypography.statLabel),
              ],
            ),
          ),

          // Divider
          Container(width: 1.w, height: 32.h, color: AppColors.cardEdge),

          // Weekly Column
          Expanded(
            child: Column(
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(text: "${weeklyAvg.toInt()}", style: AppTypography.statValue),
                      TextSpan(text: " %", style: AppTypography.statSmall),
                    ],
                  ),
                ),
                SizedBox(height: 4.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(AppString.weekly.tr.toUpperCase(), style: AppTypography.statLabel),
                    SizedBox(width: 4.w),
                    Icon(Icons.trending_up_rounded, size: 11.sp, color: AppColors.good),
                    Text(" +4%", style: AppTypography.statTrend),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedRingPainter extends CustomPainter {
  final Color color;
  final double inset;
  _DashedRingPainter({required this.color, required this.inset});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = color;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height).inflate(inset);
    final radius = rect.width / 2;
    final center = rect.center;
    const dashCount = 40;
    const dashArc = 3.5;
    const gapArc = (360 / dashCount) - dashArc;

    double start = -90;
    for (int i = 0; i < dashCount; i++) {
      final sweep = dashArc * 3.1415926 / 180;
      final startRad = start * 3.1415926 / 180;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startRad, sweep, false, paint);
      start += dashArc + gapArc;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRingPainter old) => old.color != color || old.inset != inset;
}

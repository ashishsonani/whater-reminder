import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:water_intake/models/chart_datum.dart';
import 'package:water_intake/models/water_record.dart';
import 'package:water_intake/models/weekly_completion.dart';
import 'package:water_intake/theme/app_colors.dart';
import 'package:water_intake/theme/app_shadows.dart';
import 'package:water_intake/theme/app_typography.dart';
import 'package:water_intake/view/dashboard/controller/dashboard_controller.dart';
import 'package:water_intake/view/home/controller/home_controller.dart' hide ChartMode;

import '../../../../../services/ad_service.dart' show CommonBannerAd;
import '../../../../../utils/app_strings.dart';

class StatisticScreen extends StatefulWidget {
  const StatisticScreen({super.key});

  @override
  State<StatisticScreen> createState() => _StatisticScreenState();
}

class _StatisticScreenState extends State<StatisticScreen> {
  final playAnimation = false.obs;
  late final Worker _worker;

  @override
  void initState() {
    super.initState();
    final dashboardController = Get.find<DashboardController>();
    playAnimation.value = dashboardController.selectedIndex.value == 2;

    _worker = ever(dashboardController.selectedIndex, (index) {
      if (index == 2) {
        playAnimation.value = true;
      } else {
        playAnimation.value = false;
      }
    });
  }

  @override
  void dispose() {
    _worker.dispose();
    super.dispose();
  }

  String formatRange(DateTime start, DateTime end) {
    final startMonth = DateFormat('MMM', Get.locale?.languageCode ?? 'en').format(start);
    final endMonth = DateFormat('MMM', Get.locale?.languageCode ?? 'en').format(end);
    final year = start.year;
    if (startMonth == endMonth) {
      return "$startMonth ${start.day} – ${end.day}, $year";
    } else {
      return "$startMonth ${start.day} – $endMonth ${end.day}, $year";
    }
  }

  static const _options = <(StatsPeriod, String)>[
    (StatsPeriod.weekly, AppString.weekly),
    (StatsPeriod.monthly, AppString.monthly),
    (StatsPeriod.yearly, AppString.yearly),
  ];
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: StreamBuilder<List<WaterRecord>>(
        stream: controller.allRecordsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CupertinoActivityIndicator());
          }
          return SafeArea(
            child: SingleChildScrollView(
              child: Obx(() {
                final period = controller.period;
                final activeIndex = _options.indexWhere((o) => o.$1 == period);
                final percent = controller.targetIntake.value > 0
                    ? (controller.currentIntake.value / controller.targetIntake.value * 100).toInt()
                    : 0;

                final focused = controller.statsFocusedDay.value;
                String label = "";
                if (controller.statisticsTabPeriod.value == 0) {
                  final startOfWeek = focused.subtract(Duration(days: focused.weekday - 1));
                  final endOfWeek = startOfWeek.add(const Duration(days: 6));
                  label = formatRange(startOfWeek, endOfWeek);
                } else if (controller.statisticsTabPeriod.value == 1) {
                  label = DateFormat('MMMM yyyy', Get.locale?.languageCode ?? 'en').format(focused);
                } else {
                  label = DateFormat('yyyy', Get.locale?.languageCode ?? 'en').format(focused);
                }
                return Column(
                  children: [
                    SizedBox(height: 16.h),
                    FadeSlideUpTransition(
                      play: playAnimation.value,
                      delay: Duration.zero,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(AppString.overview.tr.toUpperCase(), style: AppTypography.eyebrow),
                                  const SizedBox(height: 6),

                                  Text.rich(
                                    TextSpan(
                                      style: AppTypography.greetingTitle,
                                      children: [
                                        TextSpan(text: AppString.yourStatisticsPrefix.tr),
                                        TextSpan(text: AppString.yourStatisticsItalic.tr, style: AppTypography.greetingTitleItalic),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _TodayPill(percent: percent),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),
                    FadeSlideUpTransition(
                      play: playAnimation.value,
                      delay: const Duration(milliseconds: 80),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          border: Border.all(color: AppColors.cardEdge),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: AppShadows.level1,
                        ),
                        child: LayoutBuilder(
                          builder: (_, c) {
                            final segWidth = (c.maxWidth) / _options.length;
                            return SizedBox(
                              height: 40,
                              child: Stack(
                                children: [
                                  AnimatedPositioned(
                                    duration: const Duration(milliseconds: 280),
                                    curve: Curves.easeOutCubic,
                                    left: segWidth * activeIndex,
                                    top: 0,
                                    bottom: 0,
                                    width: segWidth,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [AppColors.tealBright, AppColors.teal],
                                        ),
                                        borderRadius: BorderRadius.circular(14),
                                        boxShadow: [
                                          BoxShadow(color: AppColors.teal.withOpacity(0.24), blurRadius: 12, offset: const Offset(0, 4)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Row(
                                    children: _options.map((o) {
                                      final active = o.$1 == period;
                                      return Expanded(
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(14),
                                          onTap: () {
                                            HapticFeedback.selectionClick();
                                            controller.setPeriod(o.$1);
                                          },
                                          child: Center(
                                            child: AnimatedDefaultTextStyle(
                                              duration: const Duration(milliseconds: 240),
                                              curve: Curves.easeOut,
                                              style: AppTypography.actionLabel.copyWith(
                                                color: active ? Colors.white : AppColors.inkMute,
                                                fontSize: 12,
                                                letterSpacing: 0.6,
                                                fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                                              ),
                                              child: Text(o.$2.tr),
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    FadeSlideUpTransition(
                      play: playAnimation.value,
                      delay: const Duration(milliseconds: 160),
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          border: Border.all(color: AppColors.cardEdge),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: AppShadows.level1,
                        ),
                        child: Row(
                          children: [
                            _NavBtn(
                              icon: Icons.chevron_left_rounded,
                              onTap: () {
                                if (controller.statisticsTabPeriod.value == 2) {
                                  controller.updateStatsYear(-1);
                                } else {
                                  controller.updateStatsMonth(-1);
                                }
                              },
                            ),
                            Expanded(
                              child: Center(
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 260),
                                  transitionBuilder: (child, anim) {
                                    return FadeTransition(
                                      opacity: anim,
                                      child: SlideTransition(
                                        position: Tween<Offset>(
                                          begin: const Offset(0, 0.35),
                                          end: Offset.zero,
                                        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: Text(label, key: ValueKey(label), style: AppTypography.streakNum.copyWith(fontSize: 14)),
                                ),
                              ),
                            ),
                            _NavBtn(
                              icon: Icons.chevron_right_rounded,
                              onTap: () {
                                if (controller.statisticsTabPeriod.value == 2) {
                                  controller.updateStatsYear(1);
                                } else {
                                  controller.updateStatsMonth(1);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),
                    FadeSlideUpTransition(
                      play: playAnimation.value,
                      delay: const Duration(milliseconds: 240),
                      child: _buildDrinkCompletionCard(controller),
                    ),
                    SizedBox(height: 10.h),
                    const CommonBannerAd(),

                    SizedBox(height: 10.h),

                    // Hydrate Card
                    FadeSlideUpTransition(
                      play: playAnimation.value,
                      delay: const Duration(milliseconds: 320),
                      child: _buildHydrateCard(controller),
                    ),

                    SizedBox(height: 16.h),

                    // "This week" horizontal calendar and streaks
                    FadeSlideUpTransition(
                      play: playAnimation.value,
                      delay: const Duration(milliseconds: 400),
                      child: _buildWeeklyCompletionSection(controller),
                    ),

                    SizedBox(height: 40.h),
                  ],
                );
              }),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDrinkCompletionCard(HomeController controller) {
    return Obx(() {
      final allData = controller.statsData.value?.data?.chartData ?? [];
      List<_ChartData> bars = _getProcessedBars(controller, allData, controller.statisticsTabPeriod.value, true);
      return _buildChartCard(
        controller,
        title: AppString.drinkCompletion.tr,
        bars: bars,
        chartType: controller.drinkChartType.value,
        onToggle: (idx) => controller.drinkChartType.value = idx,
        selectedIndex: controller.selectedDrinkChartIndex,
        isPercentage: true,
        play: playAnimation.value,
      );
    });
  }

  Widget _buildHydrateCard(HomeController controller) {
    return Obx(() {
      final allData = controller.statsData.value?.data?.chartData ?? [];
      List<_ChartData> bars = _getProcessedBars(controller, allData, controller.statisticsTabPeriod.value, false);
      return _buildChartCard(
        controller,
        title: AppString.hydrate.tr,
        bars: bars,
        chartType: controller.hydrateChartType.value,
        onToggle: (idx) => controller.hydrateChartType.value = idx,
        selectedIndex: controller.selectedHydrateChartIndex,
        isPercentage: false,
        play: playAnimation.value,
      );
    });
  }

  Widget _buildToggleSwitch({required int activeIndex, required ValueChanged<int> onChange}) {
    return Container(
      width: 70.w,
      height: 30.h,
      padding: EdgeInsets.all(3.r),
      decoration: BoxDecoration(color: AppColors.paperWarm, borderRadius: BorderRadius.circular(10.r)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final itemWidth = width / 2;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                left: activeIndex * itemWidth,
                top: 0,
                bottom: 0,
                width: itemWidth,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.tealBright, AppColors.teal],
                    ),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onChange(0);
                      },
                      child: Center(
                        child: Icon(Icons.bar_chart_rounded, size: 16.sp, color: activeIndex == 0 ? Colors.white : AppColors.inkMute),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onChange(1);
                      },
                      child: Center(
                        child: Icon(Icons.show_chart_rounded, size: 16.sp, color: activeIndex == 1 ? Colors.white : AppColors.inkMute),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildChartCard(
    HomeController controller, {
    required String title,
    required List<_ChartData> bars,
    required int chartType, // 0: Bar, 1: Line
    required ValueChanged<int> onToggle,
    required RxInt selectedIndex,
    bool isPercentage = true,
    required bool play,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.cardEdge),
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.level1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppTypography.sectionTitle.copyWith(fontSize: 16)),
              _buildToggleSwitch(activeIndex: chartType, onChange: onToggle),
            ],
          ),
          SizedBox(height: 5.h),
          Divider(color: AppColors.cardEdge, height: 1),
          SizedBox(height: 10.h),
          SizedBox(
            height: 160.h,
            child: Obx(() {
              selectedIndex.value; // register reactive dependency
              return SfCartesianChart(
                key: ValueKey("${title}_${chartType}_$play"),
                margin: EdgeInsets.only(top: 2.h, left: 5.w, right: 5.w, bottom: 5.h),
                plotAreaBorderWidth: 0,
                zoomPanBehavior: ZoomPanBehavior(enablePanning: true, enablePinching: true, zoomMode: ZoomMode.x),
                primaryXAxis: CategoryAxis(
                  majorGridLines: const MajorGridLines(width: 0),
                  axisLine: const AxisLine(width: 0),
                  majorTickLines: const MajorTickLines(size: 0),
                  autoScrollingDelta: controller.statisticsTabPeriod.value == 0 ? 7 : (controller.statisticsTabPeriod.value == 1 ? 4 : 6),
                  autoScrollingMode: AutoScrollingMode.start,
                  labelStyle: GoogleFonts.interTight(color: AppColors.inkMute, fontSize: 10.sp, fontWeight: FontWeight.w500),
                ),
                primaryYAxis: NumericAxis(
                  minimum: 0,
                  maximum: isPercentage ? 100 : (controller.isMl.value ? 5.0 : 170.0),
                  interval: isPercentage ? 20 : (controller.isMl.value ? 1 : 34),
                  numberFormat: isPercentage ? null : (controller.isMl.value ? NumberFormat('0.0') : null),
                  labelFormat: isPercentage ? '{value}%' : (controller.isMl.value ? '{value}L' : '{value}oz'),
                  axisLine: const AxisLine(width: 0),
                  majorTickLines: const MajorTickLines(size: 0),
                  majorGridLines: const MajorGridLines(width: 1, color: AppColors.cardEdge, dashArray: [4, 4]),
                  labelStyle: GoogleFonts.interTight(color: AppColors.inkMute, fontSize: 10.sp, fontWeight: FontWeight.w500),
                ),
                series: chartType == 0
                    ? <CartesianSeries<_ChartData, String>>[
                        ColumnSeries<_ChartData, String>(
                          dataSource: bars,
                          animationDuration: 1200,
                          xValueMapper: (_ChartData data, _) => data.date,
                          yValueMapper: (_ChartData data, _) =>
                              isPercentage ? (data.height * 100) : (controller.isMl.value ? (data.height * 5) : (data.height * 170)),
                          onPointTap: (ChartPointDetails details) {
                            if (selectedIndex.value == details.pointIndex) {
                              selectedIndex.value = -1;
                            } else {
                              selectedIndex.value = details.pointIndex ?? -1;
                            }
                          },
                          color: AppColors.teal,
                          width: controller.statisticsTabPeriod.value == 0
                              ? 0.35
                              : (controller.statisticsTabPeriod.value == 1 ? 0.45 : 0.4),
                          borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
                          dataLabelSettings: DataLabelSettings(
                            isVisible: true,
                            labelAlignment: ChartDataLabelAlignment.top,
                            overflowMode: OverflowMode.none,
                            builder: (dynamic data, dynamic point, dynamic series, int pointIndex, int seriesIndex) {
                              final chartData = data as _ChartData;
                              final bool isSelected = selectedIndex.value == pointIndex;
                              final bool shouldShowTooltip = isSelected;
                              final percentage = double.tryParse(chartData.tooltip!.replaceAll('%', '').replaceAll('up', '').trim()) ?? 0;
                              if (shouldShowTooltip && chartData.tooltip != null) {
                                return Transform.translate(
                                  offset: Offset(0, -22.h),
                                  child: Padding(
                                    padding: percentage >= 100 ? EdgeInsets.only(top: 10.h) : EdgeInsets.zero,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                          decoration: BoxDecoration(
                                            color: AppColors.tealDeep,
                                            borderRadius: BorderRadius.circular(24.r),
                                            boxShadow: [
                                              BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 4, offset: const Offset(0, 2)),
                                            ],
                                          ),
                                          child: Text(
                                            chartData.tooltip!,
                                            style: GoogleFonts.interTight(fontSize: 8.sp, color: Colors.white, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        CustomPaint(
                                          size: Size(8.w, 4.h),
                                          painter: _TooltipArrowPainter(color: AppColors.tealDeep),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      ]
                    : <CartesianSeries<_ChartData, String>>[
                        SplineAreaSeries<_ChartData, String>(
                          dataSource: bars,
                          animationDuration: 1200,
                          xValueMapper: (_ChartData data, _) => data.date,
                          yValueMapper: (_ChartData data, _) =>
                              isPercentage ? (data.height * 100) : (controller.isMl.value ? (data.height * 5) : (data.height * 170)),
                          onPointTap: (ChartPointDetails details) {
                            if (selectedIndex.value == details.pointIndex) {
                              selectedIndex.value = -1;
                            } else {
                              selectedIndex.value = details.pointIndex ?? -1;
                            }
                          },
                          color: AppColors.teal.withOpacity(0.1),
                          borderColor: AppColors.teal,
                          borderWidth: 2,
                          markerSettings: const MarkerSettings(
                            isVisible: true,
                            height: 8,
                            width: 8,
                            shape: DataMarkerType.circle,
                            color: AppColors.teal,
                            borderColor: Colors.white,
                            borderWidth: 2,
                          ),
                          dataLabelSettings: DataLabelSettings(
                            isVisible: true,
                            labelAlignment: ChartDataLabelAlignment.middle,
                            overflowMode: OverflowMode.none,
                            builder: (dynamic data, dynamic point, dynamic series, int pointIndex, int seriesIndex) {
                              final chartData = data as _ChartData;
                              final bool isSelected = selectedIndex.value == pointIndex;
                              final bool shouldShowTooltip = isSelected;
                              final percentage = double.tryParse(chartData.tooltip!.replaceAll('%', '').replaceAll('up', '').trim()) ?? 0;
                              if (shouldShowTooltip && chartData.tooltip != null) {
                                return Transform.translate(
                                  offset: Offset(0, -18.h),
                                  child: Padding(
                                    padding: percentage >= 100 ? EdgeInsets.only(top: 12.h) : EdgeInsets.zero,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                          decoration: BoxDecoration(
                                            color: AppColors.tealDeep,
                                            borderRadius: BorderRadius.circular(24.r),
                                            boxShadow: [
                                              BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 4, offset: const Offset(0, 2)),
                                            ],
                                          ),
                                          child: Text(
                                            chartData.tooltip!,
                                            style: GoogleFonts.interTight(fontSize: 8.sp, color: Colors.white, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        CustomPaint(
                                          size: Size(8.w, 4.h),
                                          painter: _TooltipArrowPainter(color: AppColors.tealDeep),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyCompletionSection(HomeController controller) {
    final focused = controller.statsFocusedDay.value;
    final startOfWeek = focused.subtract(Duration(days: focused.weekday - 1));

    List<WeeklyCompletion> weeklyCompletion = [];
    DateTime today = DateTime.now();

    final allData = controller.statsData.value?.data?.chartData ?? [];

    for (int i = 0; i < 7; i++) {
      DateTime d = startOfWeek.add(Duration(days: i));
      String dateKey = DateFormat('yyyy-MM-dd').format(d);

      bool isToday = d.year == today.year && d.month == today.month && d.day == today.day;
      bool goalMet = false;

      if (isToday) {
        // Today's completion is read directly from reactive variables for instant UI updates!
        goalMet = controller.targetIntake.value > 0 && controller.currentIntake.value >= controller.targetIntake.value;
      } else {
        // Look up in statsData summaries
        ChartDatum? dayData;
        for (var e in allData) {
          if (e.date == dateKey) {
            dayData = e;
            break;
          }
        }
        int dayGoal = controller.targetIntake.value > 0 ? controller.targetIntake.value : 2000;

        if (dayData != null) {
          goalMet = (dayData.completionPct ?? 0) >= 100 || (dayData.totalMl ?? 0) >= dayGoal;
        } else {
          // Fallback to allHistoryLogs using local timezone correction
          final dayLogs = controller.allHistoryLogs.where((log) {
            if (log.date == null) return false;
            final localDate = log.date!.toLocal();
            return localDate.year == d.year && localDate.month == d.month && localDate.day == d.day;
          }).toList();

          int totalAmount = dayLogs.fold(0, (sum, val) => sum + val.amount);
          goalMet = totalAmount >= dayGoal;
        }
      }

      weeklyCompletion.add(WeeklyCompletion(date: d, dayNumber: d.day, goalMet: goalMet, isToday: isToday));
    }

    final currentStreak = controller.currentStreak.value;
    final longestStreak = controller.longestStreak.value;

    return Column(
      children: [
        // "This week" Calendar Card
        Container(
          margin: EdgeInsets.symmetric(horizontal: 24.w),
          padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 20.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(color: AppColors.cardEdge),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppString.thisWeek.tr,
                style: GoogleFonts.fraunces(fontSize: 18.sp, fontWeight: FontWeight.w600, color: AppColors.ink),
              ),
              SizedBox(height: 20.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (index) {
                  final day = weeklyCompletion[index];
                  final dayName = DateFormat('E', Get.locale?.languageCode ?? 'en').format(day.date!);
                  final dayNumber = day.dayNumber.toString();

                  Widget circle;
                  if (day.isToday == true) {
                    circle = SizedBox(
                      width: 36.w,
                      height: 36.w,
                      child: RotatingDottedCircle(
                        color: AppColors.teal,
                        child: Center(
                          child: Text(
                            dayNumber,
                            style: GoogleFonts.fraunces(color: AppColors.ink, fontSize: 12.sp, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    );
                  } else if (day.goalMet == true) {
                    circle = Container(
                      width: 36.w,
                      height: 36.w,
                      decoration: const BoxDecoration(color: AppColors.teal, shape: BoxShape.circle),
                      child: Center(
                        child: Text(
                          dayNumber,
                          style: GoogleFonts.fraunces(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  } else {
                    circle = Container(
                      width: 36.w,
                      height: 36.w,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.cardEdge.withOpacity(0.6), width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          dayNumber,
                          style: GoogleFonts.fraunces(color: AppColors.inkFaint, fontSize: 12.sp, fontWeight: FontWeight.w500),
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      Text(
                        dayName,
                        style: GoogleFonts.interTight(fontSize: 11.sp, fontWeight: FontWeight.w500, color: AppColors.inkMute),
                      ),
                      SizedBox(height: 10.h),
                      circle,
                    ],
                  );
                }),
              ),
            ],
          ),
        ),

        SizedBox(height: 16.h),

        // Streaks cards side-by-side
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Row(
            children: [
              Expanded(
                child: _buildStreakBox(
                  title: AppString.currentStreak.tr,
                  value: "$currentStreak",
                  icon: const Icon(Icons.water_drop_rounded, color: AppColors.tealBright, size: 20),
                  label: AppString.days.tr.toLowerCase(),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: _buildStreakBox(
                  title: AppString.longestStreak.tr,
                  value: "$longestStreak",
                  icon: const Icon(Icons.emoji_events_rounded, color: AppColors.gold, size: 20),
                  label: AppString.days.tr.toLowerCase(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStreakBox({required String title, required String value, required Widget icon, required String label}) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.cardEdge),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title.toUpperCase(),
            style: GoogleFonts.interTight(fontSize: 10.sp, fontWeight: FontWeight.w600, letterSpacing: 1.2, color: AppColors.inkMute),
          ),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              icon,
              SizedBox(width: 6.w),
              Text(
                value,
                style: GoogleFonts.fraunces(fontSize: 28.sp, fontWeight: FontWeight.bold, color: AppColors.teal),
              ),
              SizedBox(width: 4.w),
              Text(
                label,
                style: GoogleFonts.interTight(fontSize: 12.sp, fontWeight: FontWeight.w500, color: AppColors.inkMute),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<_ChartData> _getProcessedBars(HomeController controller, List<ChartDatum> allData, int period, bool isCompletion) {
    if (period == 0) {
      // Weekly: Show the specific 7 days of the selected week (Mon to Sun)
      List<_ChartData> weeklyData = [];
      final focusedDate = controller.statsFocusedDay.value;
      final startOfWeek = focusedDate.subtract(Duration(days: focusedDate.weekday - 1));

      for (int i = 0; i < 7; i++) {
        DateTime d = startOfWeek.add(Duration(days: i));
        String dateKey = DateFormat('yyyy-MM-dd').format(d);
        String label = DateFormat.E(Get.locale?.toString() ?? 'en_US').format(d);

        final dayData = allData.firstWhere((e) => e.date == dateKey, orElse: () => ChartDatum(date: dateKey, completionPct: 0, totalMl: 0));

        double value = isCompletion ? (dayData.completionPct ?? 0) : (dayData.totalMl ?? 0).toDouble();
        double cappedValue = value;
        if (isCompletion) {
          cappedValue = value.clamp(0.0, 100.0);
        } else {
          cappedValue = value.clamp(0.0, controller.isMl.value ? 5000.0 : 170.0);
        }

        weeklyData.add(
          _ChartData(
            height: isCompletion
                ? (cappedValue / 100).clamp(0.0, 1.0)
                : (controller.isMl.value ? (cappedValue / 5000).clamp(0.0, 1.0) : (cappedValue / 170).clamp(0.0, 1.0)),
            date: label,
            tooltip: isCompletion
                ? "${cappedValue.toInt()}%"
                : (controller.isMl.value ? "${(cappedValue / 1000).toStringAsFixed(1)}L" : "${cappedValue.toInt()} oz"),
          ),
        );
      }
      return weeklyData;
    } else if (period == 1) {
      // Monthly: Group by 4-5 weeks of the month
      List<_ChartData> grouped = [];
      final focused = controller.statsFocusedDay.value;
      final totalDays = DateTime(focused.year, focused.month + 1, 0).day;

      for (int i = 0; i < (totalDays / 7).ceil(); i++) {
        int startDay = i * 7 + 1;
        int endDay = math.min((i + 1) * 7, totalDays);

        final weekData = allData.where((e) {
          if (e.date == null) return false;
          try {
            DateTime d = DateTime.parse(e.date!);
            return d.year == focused.year && d.month == focused.month && d.day >= startDay && d.day <= endDay;
          } catch (_) {
            return false;
          }
        }).toList();

        double avgValue = 0;
        if (weekData.isNotEmpty) {
          double sum = weekData.fold(0.0, (prev, element) => prev + (isCompletion ? (element.completionPct ?? 0) : (element.totalMl ?? 0)));
          avgValue = sum / weekData.length;
        }

        double cappedAvg = avgValue;
        if (isCompletion) {
          cappedAvg = avgValue.clamp(0.0, 100.0);
        } else {
          cappedAvg = avgValue.clamp(0.0, controller.isMl.value ? 5000.0 : 170.0);
        }

        grouped.add(
          _ChartData(
            height: isCompletion
                ? (cappedAvg / 100).clamp(0.0, 1.0)
                : (controller.isMl.value ? (cappedAvg / 5000).clamp(0.0, 1.0) : (cappedAvg / 170).clamp(0.0, 1.0)),
            date: "${AppString.weekAbbr.tr}${i + 1}",
            tooltip: isCompletion
                ? "${cappedAvg.toInt()}%"
                : (controller.isMl.value ? "${(cappedAvg / 1000).toStringAsFixed(1)}L" : "${cappedAvg.toInt()} oz"),
          ),
        );
      }
      return grouped;
    } else {
      // Yearly: 12 months of the focused year
      DateTime focused = controller.statsFocusedDay.value;
      List<_ChartData> yearlyBars = [];

      for (int i = 1; i <= 12; i++) {
        final monthData = allData.where((e) {
          if (e.date == null) return false;
          try {
            DateTime d = DateTime.parse(e.date!);
            return d.year == focused.year && d.month == i;
          } catch (_) {
            return false;
          }
        }).toList();

        double avgValue = 0;
        if (monthData.isNotEmpty) {
          double sum = monthData.fold(
            0.0,
            (prev, element) => prev + (isCompletion ? (element.completionPct ?? 0) : (element.totalMl ?? 0)),
          );
          avgValue = sum / monthData.length;
        }

        double cappedAvg = avgValue;
        if (isCompletion) {
          cappedAvg = avgValue.clamp(0.0, 100.0);
        } else {
          cappedAvg = avgValue.clamp(0.0, controller.isMl.value ? 5000.0 : 170.0);
        }

        DateTime tm = DateTime(focused.year, i, 1);
        String label = DateFormat('MMM', Get.locale?.languageCode ?? 'en').format(tm);

        yearlyBars.add(
          _ChartData(
            height: isCompletion
                ? (cappedAvg / 100).clamp(0.0, 1.0)
                : (controller.isMl.value ? (cappedAvg / 5000).clamp(0.0, 1.0) : (cappedAvg / 170).clamp(0.0, 1.0)),
            date: label,
            tooltip: isCompletion
                ? "${cappedAvg.toInt()}%"
                : (controller.isMl.value ? "${(cappedAvg / 1000).toStringAsFixed(1)}L" : "${cappedAvg.toInt()} oz"),
          ),
        );
      }
      return yearlyBars;
    }
  }
}

class DottedCirclePainter extends CustomPainter {
  final Color color;
  DottedCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const double dashWidth = 3;
    const double dashSpace = 3;
    final double radius = size.width / 2;
    final Offset center = Offset(size.width / 2, size.height / 2);

    double currentAngle = 0;
    while (currentAngle < 2 * math.pi) {
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), currentAngle, dashWidth / radius, false, paint);
      currentAngle += (dashWidth + dashSpace) / radius;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _ChartData {
  final double height;
  final String date;
  final String? tooltip;
  _ChartData({required this.height, required this.date, this.tooltip});
}

class _TodayPill extends StatelessWidget {
  final int percent;
  const _TodayPill({required this.percent});

  @override
  Widget build(BuildContext context) {
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
          const Icon(Icons.water_drop_rounded, size: 14, color: AppColors.tealBright),
          const SizedBox(width: 6),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: percent.toDouble()),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => Text('${v.round()}%', style: AppTypography.streakNum),
          ),
          const SizedBox(width: 4),
          Text(AppString.today.tr.toUpperCase(), style: AppTypography.streakLabel),
        ],
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.paperWarm,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: 28, height: 28, child: Icon(icon, size: 16, color: AppColors.teal)),
      ),
    );
  }
}

class RotatingDottedCircle extends StatefulWidget {
  final Widget child;
  final Color color;

  const RotatingDottedCircle({super.key, required this.child, required this.color});

  @override
  State<RotatingDottedCircle> createState() => _RotatingDottedCircleState();
}

class _RotatingDottedCircleState extends State<RotatingDottedCircle> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: CustomPaint(
        painter: DottedCirclePainter(color: widget.color),
        child: RotationTransition(turns: ReverseAnimation(_controller), child: widget.child),
      ),
    );
  }
}

class _TooltipArrowPainter extends CustomPainter {
  final Color color;
  _TooltipArrowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class FadeSlideUpTransition extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final bool play;

  const FadeSlideUpTransition({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 600),
    required this.play,
  });

  @override
  State<FadeSlideUpTransition> createState() => _FadeSlideUpTransitionState();
}

class _FadeSlideUpTransitionState extends State<FadeSlideUpTransition> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;
  bool _hasStarted = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0.0, 0.15), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    if (widget.play) {
      _startAnimation();
    }
  }

  @override
  void didUpdateWidget(covariant FadeSlideUpTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.play && !oldWidget.play) {
      _startAnimation();
    } else if (!widget.play && oldWidget.play) {
      _controller.reset();
      _hasStarted = false;
    }
  }

  void _startAnimation() {
    if (_hasStarted) return;
    _hasStarted = true;
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted && widget.play) {
          _controller.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: FractionalTranslation(translation: _slideAnimation.value, child: child),
        );
      },
      child: widget.child,
    );
  }
}

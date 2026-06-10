import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:water_intake/theme/app_colors.dart';
import 'package:water_intake/theme/app_shadows.dart';
import 'package:water_intake/theme/app_text_styles.dart';
import 'package:water_intake/theme/app_typography.dart';

import '../../../../common/common_button.dart';
import '../../../../gen/assets.gen.dart';
import '../../../../models/water_record.dart';
import '../../../../services/ad_service.dart';
import '../../../../utils/app_strings.dart';
import '../../../dashboard/controller/dashboard_controller.dart' show DashboardController;
import '../../controller/home_controller.dart';

class WaterIntakeHistoryView extends StatefulWidget {
  const WaterIntakeHistoryView({super.key});

  @override
  State<WaterIntakeHistoryView> createState() => _WaterIntakeHistoryViewState();
}

class _WaterIntakeHistoryViewState extends State<WaterIntakeHistoryView> {
  final controller = Get.find<HomeController>();

  @override
  void initState() {
    super.initState();
    controller.selectedDay.value = DateTime.now();
    controller.focusedDay.value = DateTime.now();
    controller.fetchFullHistory();

    // Delay to allow data to load from Firestore
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted && Get.find<DashboardController>().selectedIndex.value == 1) {
        controller.checkAndUnlockAwards(showSheet: true);
      }
    });

    // Also listen for data updates while the screen is open
    ever(controller.allHistoryLogs, (_) {
      if (mounted && Get.find<DashboardController>().selectedIndex.value == 1) {
        controller.checkAndUnlockAwards(showSheet: true);
      }
    });

    ever(controller.longestStreak, (_) {
      if (mounted && Get.find<DashboardController>().selectedIndex.value == 1) {
        controller.checkAndUnlockAwards(showSheet: true);
      }
    });

    // Also trigger when switching to this tab
    ever(Get.find<DashboardController>().selectedIndex, (index) {
      if (mounted && index == 1) {
        controller.selectedDay.value = DateTime.now();
        controller.focusedDay.value = DateTime.now();
        controller.checkAndUnlockAwards(showSheet: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {});
    return GetBuilder<HomeController>(
      builder: (controller) => Scaffold(
        backgroundColor: AppColors.paper,

        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 10.h),
                  Obx(() {
                    final viewed = controller.focusedDay.value;
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(AppString.journal.tr.toUpperCase(), style: AppTypography.eyebrow),
                              const SizedBox(height: 6),
                              Text.rich(
                                TextSpan(
                                  style: AppTypography.greetingTitle,
                                  children: [
                                    TextSpan(text: AppString.yourHydrationPrefix.tr),
                                    TextSpan(text: AppString.yourHydrationItalic.tr, style: AppTypography.greetingTitleItalic),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        _MonthPill(month: viewed),
                      ],
                    );
                  }),
                  SizedBox(height: 20.h),
                  _buildStreakCard(controller),
                  SizedBox(height: 20.h),
                  const CommonNativeAd(),
                  _buildAwardsSection(controller),
                  SizedBox(height: 24.h),
                  _buildHydrationCalendar(controller),
                  SizedBox(height: 24.h),
                  _buildRecentActivitySection(controller),

                  SizedBox(height: 30.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(HomeController controller) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 24.h),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.cardEdge),
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.level1,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Assets.images.png.content.image(scale: 3, color: AppColors.grey4),
          SizedBox(height: 10.h),
          Text(
            AppString.noHistoryYet.tr, // Or a separate past-date string if available
            style: AppTextStyle.button.copyWith(fontSize: 15.sp, color: AppColors.black2, fontWeight: FontWeight.w600),
          ),
          Text(
            AppString.historyNotFound.tr,
            style: AppTextStyle.body.copyWith(fontSize: 13.sp, color: AppColors.grey4),
          ),
        ],
      ),
    );
  }

  int _getGoalDaysCount(HomeController controller) {
    if (controller.historyData.value == null || controller.historyData.value!.data == null) {
      return 0;
    }
    return controller.historyData.value!.data!.values.where((status) => status.goalMet).length;
  }

  Widget _buildStreakCard(HomeController controller) {
    return Obx(() {
      final currentVal = controller.currentStreak.value;
      final longestVal = controller.longestStreak.value;
      final allLogsVal = controller.allHistoryLogs.length;
      final goalDaysVal = _getGoalDaysCount(controller);

      String getDaysText(int count) {
        return count == 1 ? AppString.day.tr.toLowerCase() : AppString.days.tr.toLowerCase();
      }

      String getCupsText(int count) {
        return count == 1 ? AppString.cup.tr.toLowerCase() : AppString.cups.tr.toLowerCase();
      }

      final goalDaysText = AppString.goalDaysCount.trParams({
        'count': '$goalDaysVal',
        'unit': goalDaysVal == 1 ? AppString.day.tr.toLowerCase() : AppString.days.tr.toLowerCase(),
      });

      final currentStreakLabel = AppString.currentStreak.tr.toUpperCase();
      final personalBestLabel = AppString.personalBest.tr.toUpperCase();
      final allTimeLabel = AppString.allTime.tr.toUpperCase();

      return Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.cardEdge),
          boxShadow: AppShadows.level2,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24.r),
          child: Stack(
            children: [
              // Subtle ambient glow in the top-left background
              Positioned(
                left: -30.w,
                top: -30.h,
                child: Container(
                  width: 150.w,
                  height: 150.h,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xffFF8D4D).withOpacity(0.08), // very soft orange/peach
                        Colors.transparent,
                      ],
                      center: Alignment.topLeft,
                      radius: 0.8,
                    ),
                  ),
                ),
              ),

              // Card Content
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Section: Title & Pill
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            currentStreakLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.fraunces(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              color: const Color(0xFF0EA5E9), // brand teal
                            ),
                          ),
                        ),
                        // Goal Days Pill
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: const Color(0xff4A7C59).withOpacity(0.08), // sage-teal tint
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(color: const Color(0xff4A7C59).withOpacity(0.15)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded, color: const Color(0xff4A7C59), size: 12.sp),
                              SizedBox(width: 4.w),
                              Text(
                                goalDaysText,
                                style: GoogleFonts.interTight(fontSize: 10.sp, fontWeight: FontWeight.w600, color: const Color(0xff4A7C59)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),

                    // Middle Section: Flame Icon & Large Number
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Flame icon with custom radial peach glow
                        Container(
                          width: 44.w,
                          height: 44.h,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xffFDECE2), // soft peach
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.local_fire_department_rounded,
                            color: Color(0xffE36B4C), // coral-red flame
                            size: 24,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Baseline(
                          baselineType: TextBaseline.alphabetic,
                          baseline: 38.h, // alignments based on baseline
                          child: Text(
                            "$currentVal",
                            style: GoogleFonts.fraunces(
                              fontSize: 48.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A), // ink
                            ),
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Baseline(
                          baselineType: TextBaseline.alphabetic,
                          baseline: 38.h,
                          child: Text(
                            getDaysText(currentVal),
                            style: GoogleFonts.fraunces(fontSize: 15.sp, fontWeight: FontWeight.w500, color: const Color(0xFF0F172A)),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 14.h),

                    // Thin Divider line
                    Container(height: 1, width: double.infinity, color: const Color(0xFFF1F5F9).withOpacity(0.7)),
                    SizedBox(height: 14.h),

                    // Bottom Section: PB & All-Time Stats
                    Row(
                      children: [
                        // Column 1: Personal Best
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.emoji_events_rounded,
                                    color: Color(0xFFC8A04A), // gold
                                    size: 16,
                                  ),
                                  SizedBox(width: 6.w),
                                  Text(
                                    "$longestVal",
                                    style: GoogleFonts.fraunces(
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(
                                    getDaysText(longestVal),
                                    style: GoogleFonts.fraunces(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                personalBestLabel,
                                style: GoogleFonts.interTight(
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Vertical Divider
                        Container(width: 1, height: 32.h, color: const Color(0xFFF1F5F9).withOpacity(0.7)),

                        // Column 2: All Time
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(left: 20.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.local_drink_rounded,
                                      color: Color(0xFF0EA5E9), // brand teal
                                      size: 16,
                                    ),
                                    SizedBox(width: 6.w),
                                    Text(
                                      "$allLogsVal",
                                      style: GoogleFonts.fraunces(
                                        fontSize: 18.sp,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                    SizedBox(width: 4.w),
                                    Text(
                                      getCupsText(allLogsVal),
                                      style: GoogleFonts.fraunces(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  allTimeLabel,
                                  style: GoogleFonts.interTight(
                                    fontSize: 9.sp,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildAwardCard(
    HomeController controller, {
    required String id,
    required String label,
    required String desc,
    required IconData unlockedIcon,
  }) {
    return Obx(() {
      bool isUnlocked = controller.unlockedAwards.contains(id);

      Color cardColor = Colors.white;
      Color titleColor = isUnlocked ? const Color(0xFF0F172A) : const Color(0xff969593);
      Color descColor = isUnlocked ? const Color(0xFF64748B) : const Color(0xff969593).withOpacity(0.7);

      return Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border.all(color: AppColors.cardEdge),
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppShadows.level1,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Circular icon
            Container(
              width: 44.w,
              height: 44.h,
              decoration: isUnlocked
                  ? BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        center: Alignment(-0.3, -0.3),
                        radius: 0.95,
                        colors: [AppColors.tealBright, AppColors.teal, AppColors.tealDeep],
                        stops: [0.0, 0.65, 1.0],
                      ),
                      boxShadow: [BoxShadow(color: AppColors.teal.withOpacity(0.30), blurRadius: 14, offset: const Offset(0, 5))],
                      border: Border.all(color: Colors.white.withOpacity(0.22)),
                    )
                  : BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFF1F5F9), // soft beige/grey
                    ),
              alignment: Alignment.center,
              child: isUnlocked
                  ? Icon(unlockedIcon, color: Colors.white, size: 20.sp)
                  : Icon(Icons.lock_outline_rounded, color: const Color(0xff969593), size: 18.sp),
            ),
            SizedBox(height: 8.h),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.fraunces(fontSize: 10.sp, fontWeight: FontWeight.bold, color: titleColor),
            ),
            Text(
              desc,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.interTight(fontSize: 8.sp, fontWeight: FontWeight.w500, color: descColor),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildAwardsSection(HomeController controller) {
    return Obx(() {
      final unlockedCount = controller.unlockedAwards.length;

      // Dynamic Turkish layout for "Your badges"
      Widget buildHeaderTitle() {
        return RichText(
          text: TextSpan(
            style: GoogleFonts.fraunces(fontSize: 18.sp, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
            children: [
              TextSpan(text: AppString.yourBadgesPrefix.tr),
              TextSpan(
                text: AppString.yourBadgesItalic.tr,
                style: GoogleFonts.fraunces(fontStyle: FontStyle.italic, fontWeight: FontWeight.normal),
              ),
            ],
          ),
        );
      }

      // Dynamic Badges Localization
      final Map<String, Map<String, String>> badgeDetails = {
        'first_cup': {'title': AppString.firstCupBadgeTitle.tr, 'desc': AppString.firstCupBadgeDesc.tr},
        'first_day': {'title': AppString.firstDayBadgeTitle.tr, 'desc': AppString.firstDayBadgeDesc.tr},
        'one_week': {'title': AppString.oneWeekBadgeTitle.tr, 'desc': AppString.oneWeekBadgeDesc.tr},
        'thirty_days': {'title': AppString.thirtyDaysBadgeTitle.tr, 'desc': AppString.thirtyDaysBadgeDesc.tr},
        'hundred_days': {'title': AppString.hundredDaysBadgeTitle.tr, 'desc': AppString.hundredDaysBadgeDesc.tr},
        'three_sixty_five_days': {'title': AppString.yearOfWaterBadgeTitle.tr, 'desc': AppString.yearOfWaterBadgeDesc.tr},
      };

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badges Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              buildHeaderTitle(),
              // Badges pill
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE), // soft teal
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  "$unlockedCount / 6",
                  style: GoogleFonts.fraunces(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0EA5E9), // brand teal
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // 3-Column Badges Grid (showing all 6 badges directly)
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 12.h,
            crossAxisSpacing: 10.w,
            childAspectRatio: 0.82, // perfectly balanced aspect ratio for individual card content
            children: [
              _buildAwardCard(
                controller,
                id: "first_cup",
                label: badgeDetails['first_cup']!['title']!,
                desc: badgeDetails['first_cup']!['desc']!,
                unlockedIcon: Icons.water_drop_rounded,
              ),
              _buildAwardCard(
                controller,
                id: "first_day",
                label: badgeDetails['first_day']!['title']!,
                desc: badgeDetails['first_day']!['desc']!,
                unlockedIcon: Icons.light_mode_rounded,
              ),
              _buildAwardCard(
                controller,
                id: "one_week",
                label: badgeDetails['one_week']!['title']!,
                desc: badgeDetails['one_week']!['desc']!,
                unlockedIcon: Icons.local_fire_department_rounded,
              ),
              _buildAwardCard(
                controller,
                id: "thirty_days",
                label: badgeDetails['thirty_days']!['title']!,
                desc: badgeDetails['thirty_days']!['desc']!,
                unlockedIcon: Icons.calendar_month_rounded,
              ),
              _buildAwardCard(
                controller,
                id: "hundred_days",
                label: badgeDetails['hundred_days']!['title']!,
                desc: badgeDetails['hundred_days']!['desc']!,
                unlockedIcon: Icons.emoji_events_rounded,
              ),
              _buildAwardCard(
                controller,
                id: "three_sixty_five_days",
                label: badgeDetails['three_sixty_five_days']!['title']!,
                desc: badgeDetails['three_sixty_five_days']!['desc']!,
                unlockedIcon: Icons.star_rounded,
              ),
            ],
          ),
        ],
      );
    });
  }

  bool _hasIntake(HomeController controller, DateTime day) {
    return controller.allHistoryLogs.any((record) {
      final localDate = record.createdAt.toLocal();
      return localDate.year == day.year && localDate.month == day.month && localDate.day == day.day;
    });
  }

  Widget _buildCalendarDayNode(HomeController controller, DateTime day, {bool isSelected = false}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final compareDay = DateTime(day.year, day.month, day.day);

    bool isFuture = compareDay.isAfter(today);
    bool hasData = _hasIntake(controller, day);

    Widget child;

    if (isFuture) {
      child = Center(
        child: Text(
          '${day.day}',
          style: GoogleFonts.fraunces(fontSize: 14.sp, fontWeight: FontWeight.normal, color: const Color(0xffCED4DA)),
        ),
      );
    } else if (hasData) {
      final bool isToday = compareDay == today;
      child = Container(
        width: 34.w,
        height: 34.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(shape: BoxShape.circle, color: isToday ? const Color(0xFF0EA5E9) : const Color(0xFFE0F2FE)),
        child: Text(
          '${day.day}',
          style: GoogleFonts.fraunces(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: isToday ? Colors.white : const Color(0xFF0EA5E9),
          ),
        ),
      );
    } else {
      child = Center(
        child: Text(
          '${day.day}',
          style: GoogleFonts.fraunces(fontSize: 14.sp, fontWeight: FontWeight.normal, color: const Color(0xFF64748B)),
        ),
      );
    }

    if (isSelected) {
      return Container(
        width: 40.w,
        height: 40.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF0EA5E9), width: 1.5),
        ),
        child: child,
      );
    }

    return Center(child: child);
  }

  Widget _buildHydrationCalendar(HomeController controller) {
    return Obx(() {
      Widget buildCalendarHeaderTitle() {
        return RichText(
          text: TextSpan(
            style: GoogleFonts.fraunces(fontSize: 18.sp, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
            children: [
              TextSpan(text: AppString.hydrationCalendarPrefix.tr),
              TextSpan(
                text: AppString.hydrationCalendarItalic.tr,
                style: GoogleFonts.fraunces(fontStyle: FontStyle.italic, fontWeight: FontWeight.normal),
              ),
            ],
          ),
        );
      }

      Widget legendItem(Color color, String text) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8.w,
              height: 8.h,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
            SizedBox(width: 6.w),
            Text(
              text,
              style: GoogleFonts.interTight(fontSize: 11.sp, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
            ),
          ],
        );
      }

      final goalHitLabel = AppString.goalHit.tr;
      final partialLabel = AppString.partial.tr;
      final missedLabel = AppString.missed.tr;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              buildCalendarHeaderTitle(),
              Row(
                children: [
                  GestureDetector(
                    child: Container(
                      decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFF1F5F9)),
                      child: const Icon(Icons.chevron_left, color: Color(0xFF64748B)),
                    ),
                    onTap: () {
                      final current = controller.focusedDay.value;
                      controller.focusedDay.value = DateTime(current.year, current.month - 1, 1);
                    },
                  ),
                  5.w.horizontalSpace,
                  Text(
                    DateFormat('MMMM yyyy', Get.locale?.toString() ?? 'en_US').format(controller.focusedDay.value),
                    style: GoogleFonts.fraunces(fontSize: 10.sp, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                  ),
                  5.w.horizontalSpace,
                  GestureDetector(
                    child: Container(
                      decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFF1F5F9)),
                      child: const Icon(Icons.chevron_right, color: Color(0xFF64748B)),
                    ),
                    onTap: () {
                      final current = controller.focusedDay.value;
                      controller.focusedDay.value = DateTime(current.year, current.month + 1, 1);
                    },
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppShadows.level1,
              border: Border.all(color: AppColors.cardEdge),
            ),
            child: Column(
              children: [
                TableCalendar(
                  locale: Get.locale?.toString() ?? 'en_US',
                  firstDay: DateTime.now().subtract(const Duration(days: 365)),
                  lastDay: DateTime(2028, 1, 1),
                  focusedDay: controller.focusedDay.value,
                  selectedDayPredicate: (day) => isSameDay(controller.selectedDay.value, day),
                  calendarFormat: CalendarFormat.month,
                  availableGestures: AvailableGestures.horizontalSwipe,
                  headerVisible: false,
                  startingDayOfWeek: StartingDayOfWeek.sunday,
                  daysOfWeekHeight: 24.sp,
                  rowHeight: 44.sp,
                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: GoogleFonts.interTight(fontSize: 11.sp, fontWeight: FontWeight.w600, color: const Color(0xff969593)),
                    weekendStyle: GoogleFonts.interTight(fontSize: 11.sp, fontWeight: FontWeight.w600, color: const Color(0xff969593)),
                  ),
                  calendarBuilders: CalendarBuilders(
                    dowBuilder: (context, day) {
                      final text = DateFormat('E', Get.locale?.toString() ?? 'en_US').format(day);
                      final firstLetter = text.substring(0, 1).toUpperCase();
                      return Center(
                        child: Text(
                          firstLetter,
                          style: GoogleFonts.interTight(fontSize: 11.sp, fontWeight: FontWeight.w600, color: const Color(0xff969593)),
                        ),
                      );
                    },
                    defaultBuilder: (context, day, focusedDay) {
                      return _buildCalendarDayNode(controller, day);
                    },
                    todayBuilder: (context, day, focusedDay) {
                      return _buildCalendarDayNode(controller, day, isSelected: isSameDay(day, controller.selectedDay.value));
                    },
                    outsideBuilder: (context, day, focusedDay) {
                      return const SizedBox.shrink(); // Hide outside days to keep month boundary clean
                    },
                    disabledBuilder: (context, day, focusedDay) {
                      return const SizedBox.shrink();
                    },
                    selectedBuilder: (context, day, focusedDay) {
                      return _buildCalendarDayNode(controller, day, isSelected: true);
                    },
                  ),
                  onDaySelected: (selectedDay, focusedDay) {
                    controller.onDaySelected(selectedDay, focusedDay);
                  },
                  onPageChanged: (focusedDay) {
                    controller.focusedDay.value = focusedDay;
                  },
                ),
                SizedBox(height: 20.h),
                Container(height: 1, width: double.infinity, color: const Color(0xFFF1F5F9).withOpacity(0.7)),
                SizedBox(height: 16.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    legendItem(const Color(0xFF0EA5E9), goalHitLabel),
                    legendItem(const Color(0xFFE0F2FE), partialLabel),
                    legendItem(const Color(0xFFF1F5F9), missedLabel),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  String _getDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final compareDate = DateTime(date.year, date.month, date.day);

    if (compareDate == today) {
      return AppString.today.tr.toUpperCase();
    } else if (compareDate == yesterday) {
      return AppString.yesterday.tr.toUpperCase();
    } else {
      return DateFormat.MMMMd(Get.locale?.toString() ?? 'en_US').format(date).toUpperCase();
    }
  }

  String _getVesselName(String type, int amount) {
    final rawName = type.split('#').first.trim();
    if (rawName.isEmpty) {
      return amount >= 500 ? AppString.bottle.tr : AppString.cup.tr;
    }
    return rawName.tr;
  }

  String _getDrinkName(String? drinkType) {
    if (drinkType == null || drinkType.isEmpty) return AppString.plainWater.tr;
    if (drinkType.startsWith('my_drink_')) return drinkType.replaceAll('my_drink_', '');

    switch (drinkType) {
      case 'plainWater':
        return AppString.plainWater.tr;
      case 'sparklingWater':
        return AppString.sparklingWater.tr;
      case 'mineralWater':
        return AppString.mineralWater.tr;
      case 'sportDrink':
        return AppString.sportDrink.tr;
      case 'zeroSportDrink':
        return AppString.zeroSportDrink.tr;
      case 'riceDrink':
        return AppString.riceDrink.tr;
      case 'barleyDrink':
        return AppString.barleyDrink.tr;
      case 'energyDrink':
        return AppString.energyDrink.tr;
      case 'tea':
        return AppString.tea.tr;
      case 'milkTea':
        return AppString.milkTea.tr;
      case 'blackTea':
        return AppString.blackTea.tr;
      case 'greenTea':
        return AppString.greenTea.tr;
      case 'coffee':
        return AppString.coffee.tr;
      case 'cappuccinoCoffee':
        return AppString.cappuccinoCoffee.tr;
      case 'mochaCoffee':
        return AppString.mochaCoffee.tr;
      case 'milk':
        return AppString.categoryMilk.tr;
      case 'lowFatMilk':
        return AppString.lowFatMilk.tr;
      case 'juice':
        return AppString.categoryJuice.tr;
      case 'orangeJuice':
        return AppString.orangeJuice.tr;
      case 'lemonJuice':
        return AppString.lemonJuice.tr;
      case 'pineappleJuice':
        return AppString.pineappleJuice.tr;
      case 'watermelonJuice':
        return AppString.watermelonJuice.tr;
      case 'peachJuice':
        return AppString.peachJuice.tr;
      case 'strawberryJuice':
        return AppString.strawberryJuice.tr;
      case 'coconutJuice':
        return AppString.coconutJuice.tr;
      case 'appleJuice':
        return AppString.appleJuice.tr;
      case 'carrotJuice':
        return AppString.carrotJuice.tr;
      case 'wine':
        return 'Wine'.tr;
      case 'beer':
        return 'Beer'.tr;
      case 'cocktail':
        return 'Cocktail'.tr;
      case 'champagne':
        return 'Champagne'.tr;
      case 'yogurt':
        return 'Yogurt'.tr;
      case 'smoothie':
        return 'Smoothie'.tr;
      case 'milkshake':
        return 'Milkshake'.tr;
      default:
        return AppString.plainWater.tr;
    }
  }

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

  Widget _buildDateHeader(String dateLabel, int dailyTotal, HomeController controller) {
    return Padding(
      padding: EdgeInsets.only(top: 8.h, bottom: 12.h),
      child: Row(
        children: [
          Text(dateLabel, style: AppTypography.eyebrow.copyWith(letterSpacing: 1.4, color: AppColors.teal)),
          SizedBox(width: 12.w),
          Expanded(child: Container(height: 1, color: AppColors.cardEdge)),
          SizedBox(width: 12.w),
          Text.rich(
            TextSpan(
              style: GoogleFonts.fraunces(fontSize: 14.sp, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
              children: [
                TextSpan(
                  text: '$dailyTotal',
                  style: AppTypography.historyAmount.copyWith(fontSize: 13, color: AppColors.inkMute),
                ),
                const TextSpan(text: ' '),
                TextSpan(
                  text: controller.isMl.value ? AppString.ml.tr : AppString.oz.tr,
                  style: GoogleFonts.interTight(fontSize: 10.sp, fontWeight: FontWeight.w500, color: const Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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

  Widget _buildRecentActivityItem(WaterRecord record, HomeController controller) {
    final vessel = _getVesselName(record.type, record.amount);
    final liquid = _getLiquidName(record.type, record.amount, record.drinkType);

    final typeName = record.type.split('#').first.toLowerCase();

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

    final timeStr = DateFormat('h:mm a', Get.locale?.toString() ?? 'en_US').format(record.createdAt.toLocal());

    Widget iconWidget;
    if (record.drinkType != null && record.drinkType!.isNotEmpty) {
      final assetGen = _getAssetGenImageForDrink(record.drinkType!);
      if (assetGen != null) {
        iconWidget = assetGen.image(height: 28.h, width: 28.w, fit: BoxFit.contain);
      } else if (record.drinkType!.startsWith('my_drink_')) {
        iconWidget = Assets.images.png.cupFill1.image(height: 28.h, width: 28.w, fit: BoxFit.contain, color: tileFg);
      } else {
        iconWidget = controller.getIconForType(record.type).image(height: 28.h, width: 28.w, fit: BoxFit.contain, color: tileFg);
      }
    } else {
      iconWidget = controller.getIconForType(record.type).image(height: 28.h, width: 28.w, fit: BoxFit.contain, color: tileFg);
    }

    return Dismissible(
      key: Key(record.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20.w),
        decoration: BoxDecoration(color: Colors.red.shade400, borderRadius: BorderRadius.circular(20.r)),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
      ),
      onDismissed: (direction) {
        controller.deleteRecord(record);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border.all(color: AppColors.cardEdge),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 38.w,
              height: 38.h,
              decoration: BoxDecoration(color: tileBg, borderRadius: BorderRadius.circular(12.r)),
              alignment: Alignment.center,
              child: iconWidget,
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      style: AppTypography.historyAmount,
                      children: [
                        TextSpan(text: '${record.amount}'),
                        const TextSpan(text: ' '),
                        TextSpan(
                          text: controller.isMl.value ? AppString.ml.tr : AppString.oz.tr,
                          style: GoogleFonts.interTight(fontSize: 11.sp, fontWeight: FontWeight.normal, color: const Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text('$vessel • $liquid', style: AppTypography.historyType),
                ],
              ),
            ),
            Text(timeStr, style: AppTypography.historyTime),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection(HomeController controller) {
    return Obx(() {
      if (controller.isHistoryLoading.value) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 40.h),
          child: const Center(child: CupertinoActivityIndicator()),
        );
      }

      final selectedDate = controller.selectedDay.value;
      final bool isTodaySelected = isSameDay(selectedDate, DateTime.now());
      final filteredLogs = isTodaySelected
          ? controller.allHistoryLogs
          : controller.allHistoryLogs.where((record) {
              final localDate = record.createdAt.toLocal();
              return localDate.year == selectedDate.year && localDate.month == selectedDate.month && localDate.day == selectedDate.day;
            }).toList();

      if (filteredLogs.isEmpty) {
        return Padding(
          padding: EdgeInsets.only(bottom: 30.h),
          child: _buildEmptyState(controller),
        );
      }

      final Map<String, List<WaterRecord>> groupedLogs = {};
      for (var record in filteredLogs) {
        final dateStr = DateFormat('yyyy-MM-dd').format(record.createdAt.toLocal());
        if (!groupedLogs.containsKey(dateStr)) {
          groupedLogs[dateStr] = [];
        }
        groupedLogs[dateStr]!.add(record);
      }

      final sortedKeys = groupedLogs.keys.toList()..sort((a, b) => b.compareTo(a));

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: GoogleFonts.fraunces(fontSize: 16.sp, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
              children: [
                TextSpan(text: '${AppString.recentActivity.tr.split(' ').first} '),
                TextSpan(
                  text: AppString.recentActivity.tr.split(' ').skip(1).join(' '),
                  style: GoogleFonts.fraunces(fontStyle: FontStyle.italic, fontWeight: FontWeight.normal),
                ),
              ],
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sortedKeys.length,
            itemBuilder: (context, groupIndex) {
              final dateStr = sortedKeys[groupIndex];
              final records = groupedLogs[dateStr]!;
              final parsedDate = DateTime.parse(dateStr);
              final dateLabel = _getDateLabel(parsedDate);
              final dailyTotal = records.fold<int>(0, (sum, record) => sum + record.amount);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDateHeader(dateLabel, dailyTotal, controller),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: records.length,
                    separatorBuilder: (context, index) => SizedBox(height: 12.h),
                    itemBuilder: (context, index) {
                      final record = records[index];
                      return _buildRecentActivityItem(record, controller);
                    },
                  ),
                  SizedBox(height: 10.h),
                ],
              );
            },
          ),
        ],
      );
    });
  }
}

class AwardBottomSheet extends StatelessWidget {
  final String title;
  final String description;
  final AssetGenImage icon;

  const AwardBottomSheet({super.key, required this.title, required this.description, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(32.r), topRight: Radius.circular(32.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 20.h),
          Text(
            AppString.congratulations.tr,
            style: AppTextStyle.latoBoldPrimary16.copyWith(fontSize: 18.sp, fontWeight: FontWeight.w600, color: const Color(0xff212529)),
          ),
          SizedBox(height: 8.h),
          Text(
            AppString.youGotAnAward.tr,
            style: AppTextStyle.latoRegularBlack14.copyWith(fontSize: 14.sp, color: const Color(0xff6C757D)),
          ),
          SizedBox(height: 22.h),
          icon.image(scale: 1.2, height: 120.h),
          SizedBox(height: 22.h),
          Text(
            title,
            style: AppTextStyle.latoBoldPrimary16.copyWith(fontSize: 16.sp, color: const Color(0xff212529), fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 12.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Text(
              description,
              textAlign: TextAlign.center,
              style: AppTextStyle.latoRegularBlack14.copyWith(fontSize: 14.sp, color: const Color(0xff6C757D)),
            ),
          ),
          SizedBox(height: 20.h),

          // SizedBox(
          //   width: double.infinity,
          //   child: ElevatedButton(
          //     onPressed: () => Get.back(),
          //     style: ElevatedButton.styleFrom(
          //       backgroundColor: AppColors.primary,
          //       padding: EdgeInsets.symmetric(vertical: 14.h),
          //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          //       elevation: 0,
          //     ),
          //     child: Text(
          //       AppString.continueText,
          //       style: AppTextStyle.latoBoldPrimary16.copyWith(fontSize: 16.sp, color: Colors.white),
          //     ),
          //   ),
          // ),
          CommonButton(
            text: AppString.continueText.tr,
            onPressed: () => Get.back(),
            backgroundColor: AppColors.teal,
            textColor: AppColors.white,
            textStyle: AppTextStyle.latoBoldPrimary16.copyWith(fontSize: 16.sp),
          ),
          // SizedBox(height: 1/**/6.h),
        ],
      ),
    );
  }
}

class DottedCirclePainter extends CustomPainter {
  final Color color;
  DottedCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final double radius = (math.min(size.width, size.height) / 2) - (paint.strokeWidth / 2);
    final center = Offset(size.width / 2, size.height / 2);

    const double dashWidth = 3;
    const double dashSpace = 3;

    final double circumference = 2 * math.pi * radius;
    final int dashCount = (circumference / (dashWidth + dashSpace)).floor();

    for (int i = 0; i < dashCount; i++) {
      final double startAngle = (i * (dashWidth + dashSpace)) / radius;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, dashWidth / radius, false, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _MonthPill extends StatelessWidget {
  final DateTime month;
  const _MonthPill({required this.month});

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
          const Icon(Icons.event_note_rounded, size: 14, color: AppColors.teal),
          const SizedBox(width: 6),
          Text(
            '${DateFormat('MMM', Get.locale?.toString() ?? 'en_US').format(month)} ${month.year}',
            style: AppTypography.streakNum.copyWith(fontSize: 13),
          ),
        ],
      ),
    );
  }
}

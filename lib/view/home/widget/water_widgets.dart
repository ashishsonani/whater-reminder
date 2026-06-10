import 'dart:developer';
import 'dart:io';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:water_intake/theme/app_colors.dart';
import 'package:water_intake/theme/app_text_styles.dart';
import 'package:water_intake/utils/app_strings.dart';
import 'package:water_intake/utils/local_storage.dart';
import 'package:water_intake/view/account/screen/feedback/feedback_detail_screen.dart';

import '../../../common/common_button.dart';
import '../../../gen/assets.gen.dart';
import '../../../services/firebase_service.dart';
import '../controller/home_controller.dart';

class DottedCirclePainter extends CustomPainter {
  final Color color;
  DottedCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final double radius = size.width / 2;
    const double dashWidth = 3;
    const double dashSpace = 3;
    double startAngle = 0;

    final double circumference = 2 * math.pi * radius;
    final int dashCount = (circumference / (dashWidth + dashSpace)).floor();

    for (int i = 0; i < dashCount; i++) {
      canvas.drawArc(Rect.fromCircle(center: Offset(radius, radius), radius: radius), startAngle, dashWidth / radius, false, paint);
      startAngle += (dashWidth + dashSpace) / radius;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class ArcProgressPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;
  final double strokeWidth;
  final double startAngle;
  final double sweepAngle;

  ArcProgressPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
    required this.strokeWidth,
    required this.startAngle,
    required this.sweepAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle, false, bgPaint);

    final progressPaint = Paint()
      ..color = progressColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle * progress, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant ArcProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class PremiumProgressPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final List<Color> gradientColors;
  final double strokeWidth;

  PremiumProgressPainter({required this.progress, required this.backgroundColor, required this.gradientColors, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background track (full circle)
    final bgPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    if (progress > 0) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      final startAngle = -math.pi / 2; // 12 o'clock
      final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);

      // Gradient shader for progress arc
      final progressPaint = Paint()
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      progressPaint.shader = SweepGradient(
        colors: gradientColors,
        startAngle: 0.0,
        endAngle: 2 * math.pi,
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(rect);

      canvas.drawArc(rect, startAngle, sweepAngle, false, progressPaint);

      // Draw the knob at the end of progress
      final endAngle = startAngle + sweepAngle;
      final knobOffset = Offset(center.dx + radius * math.cos(endAngle), center.dy + radius * math.sin(endAngle));

      final knobPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      // Add a subtle shadow to the knob to make it premium
      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(knobOffset, strokeWidth / 2 - 1, shadowPaint);
      canvas.drawCircle(knobOffset, strokeWidth / 2 - 2, knobPaint);
    }
  }

  @override
  bool shouldRepaint(covariant PremiumProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class LiquidWaveClipper extends CustomClipper<Path> {
  final double percentage;
  final double phase;

  LiquidWaveClipper({required this.percentage, required this.phase});

  @override
  Path getClip(Size size) {
    var path = Path();
    double h = size.height;
    double w = size.width;
    double fillHeight = h * percentage;
    double yPos = h - fillHeight;

    path.moveTo(0, yPos);

    double waveHeight = 12.w;
    double waveCount = 1.2;

    for (double i = 0; i <= w; i++) {
      double iPercentage = i / w;
      double dy =
          yPos + (percentage > 0 && percentage < 1.0 ? (math.sin((iPercentage * waveCount * 2 * math.pi) + phase) * waveHeight) : 0);
      path.lineTo(i, dy);
    }

    path.lineTo(w, h);
    path.lineTo(0, h);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant LiquidWaveClipper oldClipper) {
    return oldClipper.percentage != percentage || oldClipper.phase != phase;
  }
}

class WaterWaveWidget extends StatefulWidget {
  final double percentage;
  final Color color;

  const WaterWaveWidget({super.key, required this.percentage, required this.color});

  @override
  State<WaterWaveWidget> createState() => _WaterWaveWidgetState();
}

class _WaterWaveWidgetState extends State<WaterWaveWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
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
        return Stack(
          children: [
            ClipPath(
              clipper: LiquidWaveClipper(percentage: widget.percentage, phase: _controller.value * 2 * math.pi),
              child: Container(color: widget.color.withOpacity(0.4)),
            ),
            ClipPath(
              clipper: LiquidWaveClipper(percentage: widget.percentage, phase: -_controller.value * 2 * math.pi),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [widget.color, widget.color.withOpacity(0.8)],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class DrinkAnimationWidget extends StatefulWidget {
  const DrinkAnimationWidget({Key? key}) : super(key: key);

  @override
  DrinkAnimationState createState() => DrinkAnimationState();
}

class DrinkAnimationState extends State<DrinkAnimationWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _position;
  late Worker _worker;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _opacity = Tween<double>(begin: 1.0, end: 0.0).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.5, 1.0)));
    _position = Tween<Offset>(
      begin: const Offset(0, 0.0),
      end: const Offset(0, -2.5),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    final controller = Get.find<HomeController>();
    _worker = ever(controller.animationTrigger, (trigger) {
      if (trigger > 0) {
        _controller.forward(from: 0.0);
      }
    });
  }

  @override
  void dispose() {
    _worker.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    return SizedBox(
      height: 15.h,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          if (!_controller.isAnimating && _controller.isDismissed) return const SizedBox.shrink();
          return FractionalTranslation(
            translation: _position.value,
            child: Opacity(
              opacity: _opacity.value,
              child: Obx(
                () => Text(
                  "+${controller.animationAmount.value} ${controller.isMl.value ? AppString.ml.tr : AppString.oz.tr} ${AppString.wellDone.tr}!",
                  style: AppTextStyle.latoBoldPrimary16.copyWith(fontSize: 12.sp, color: AppColors.primary, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class FeedbackBottomSheet extends StatelessWidget {
  final bool isRating;
  const FeedbackBottomSheet({super.key, this.isRating = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 21.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24.r), topRight: Radius.circular(24.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(color: const Color(0xffB0BBC9), borderRadius: BorderRadius.circular(10.r)),
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            AppString.wouldSendFeedback.tr,
            textAlign: TextAlign.start,
            style: AppTextStyle.latoBoldBlack16.copyWith(fontWeight: FontWeight.w600, color: const Color(0xff212529)),
          ),
          SizedBox(height: 5.h),
          Text(
            AppString.wouldSendFeedbackDesc.tr,
            textAlign: TextAlign.start,
            style: AppTextStyle.latoRegularBlack14.copyWith(fontSize: 14.sp, color: const Color(0xff6C757D)),
          ),
          SizedBox(height: 10.h),
          _popupAction(title: AppString.remindLater.tr, onTap: () => Get.back()),
          _popupAction(
            title: AppString.noThanks.tr,
            onTap: () async {
              Get.back();
            },
          ),
          _popupAction(
            title: AppString.feedback.tr,
            isBold: true,
            onTap: () {
              Get.back();
              Get.dialog(const StarRatingDialog(), barrierColor: Colors.black.withOpacity(0.5), barrierDismissible: false);
            },
          ),
          SizedBox(height: 5),
        ],
      ),
    );
  }

  Widget _popupAction({required String title, required VoidCallback onTap, bool isBold = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 7.h),
        child: Center(
          child: Text(
            title,
            style: AppTextStyle.latoRegularBlack14.copyWith(fontSize: 16.sp, fontWeight: FontWeight.w600, color: const Color(0xff333B47)),
          ),
        ),
      ),
    );
  }
}

enum RatingPhase { rating, redirect, feedback }

class StarRatingDialog extends StatefulWidget {
  const StarRatingDialog({super.key});
  @override
  State<StarRatingDialog> createState() => _StarRatingDialogState();
}

class _StarRatingDialogState extends State<StarRatingDialog> {
  int _selectedStar = 0;
  RatingPhase _phase = RatingPhase.rating;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  void _handleStarSelection(int stars) {
    setState(() {
      if (_selectedStar == stars) {
        _selectedStar = 0;
      } else {
        _selectedStar = stars;
      }
    });
  }

  void _onRateClicked() {
    if (_selectedStar == 0) return;

    if (_selectedStar == 5) {
      _redirectToStore();
    } else {
      Get.back(); // Close dialog
      Get.to(() => const FeedbackDetailScreen());
    }
  }

  void _redirectToStore() async {
    log("Analytics: Store Redirect Triggered for 5-star rating");

    String url = "";
    if (GetPlatform.isAndroid) {
      url = "https://play.google.com/store/apps/details?id=com.codelineinfotech.waterintake";
    } else {
      url = "https://apps.apple.com/us/app/drink-water-remainder/id6766213522";
    }

    await LocalStorage.setFeedbackGiven(true);
    await LocalStorage.setLastFeedbackTimestamp(DateTime.now().millisecondsSinceEpoch);
    final packageInfo = await PackageInfo.fromPlatform();
    await LocalStorage.setLastFeedbackVersion(packageInfo.version);

    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    Get.back();
  }

  void _submitFeedback() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      final uid = await FirebaseService().getUserId();
      final packageInfo = await PackageInfo.fromPlatform();
      final openCount = await LocalStorage.getAppOpenCount();

      await FirebaseService().firestore.collection('feedback').add({
        'uid': uid ?? 'anonymous',
        'session_count': openCount,
        'rating': _selectedStar,
        'comment': _commentController.text.trim(),
        'app_version': packageInfo.version,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await LocalStorage.setFeedbackGiven(true);
      await LocalStorage.setLastFeedbackTimestamp(DateTime.now().millisecondsSinceEpoch);
      await LocalStorage.setLastFeedbackVersion(packageInfo.version);

      Get.back();
      Get.snackbar(AppString.thankYou.tr, AppString.feedbackSent.tr, backgroundColor: Colors.white, colorText: Colors.black);
    } catch (e) {
      Get.snackbar(AppString.error.tr, AppString.failedToSendFeedback.tr, backgroundColor: Colors.white, colorText: Colors.black);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            margin: EdgeInsets.only(top: 45.h),
            decoration: BoxDecoration(color: AppColors.paper, borderRadius: BorderRadius.circular(30.r)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 35),
                if (_phase == RatingPhase.rating) _buildRatingPhase(),
                if (_phase == RatingPhase.redirect) _buildRedirectPhase(),
                if (_phase == RatingPhase.feedback) _buildFeedbackPhase(),
              ],
            ),
          ),
          Positioned(top: -80, child: _buildHeader()),
          Positioned(
            top: 50.h,
            right: 15.w,
            child: IconButton(
              icon: Assets.images.png.exit.image(scale: 2.5, color: AppColors.grey6),
              onPressed: () => Get.back(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    AssetGenImage? emojiAsset;
    switch (_selectedStar) {
      case 1:
        emojiAsset = Assets.images.png.oneEmoji;
        break;
      case 2:
        emojiAsset = Assets.images.png.twoEmoji;
        break;
      case 3:
        emojiAsset = Assets.images.png.threeEmoji;
        break;
      case 4:
        emojiAsset = Assets.images.png.fourEmoij;
        break;
      case 5:
        emojiAsset = Assets.images.png.five;
        break;
    }

    return emojiAsset != null ? emojiAsset.image(scale: 4) : const SizedBox.shrink();
  }

  Widget _buildRatingPhase() {
    bool isSelected = _selectedStar > 0;
    String title = isSelected ? AppString.greatThanksForRating.tr : AppString.enjoyingOurApp.tr;
    String subtitle = "";
    if (isSelected) {
      if (GetPlatform.isAndroid) {
        subtitle = AppString.supportBySharingAndroid.tr;
      } else {
        subtitle = AppString.supportBySharingIOS.tr;
      }
    } else {
      subtitle = AppString.rateUsSupport.tr;
    }

    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppTextStyle.latoBoldBlack16.copyWith(fontSize: 16.sp, fontWeight: FontWeight.bold, color: AppColors.black1),
        ),
        // SizedBox(height: 3.h),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: AppTextStyle.latoRegularBlack14.copyWith(fontSize: 14.sp, color: const Color(0xff6C757D)),
        ),
        SizedBox(height: 24.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            return GestureDetector(
              onTap: () => _handleStarSelection(index + 1),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                child: !(index < _selectedStar) ? Assets.images.png.starNew.image(scale: 4) : Assets.images.png.starFillNew.image(scale: 4),
              ),
            );
          }),
        ),
        SizedBox(height: 24.h),
        CommonButton(
          text: _selectedStar == 5 ? (Platform.isIOS ? AppString.rateUsAppStore.tr : AppString.rateUsGooglePlay.tr) : AppString.rate.tr,
          onPressed: isSelected ? _onRateClicked : null,
          backgroundColor: isSelected ? AppColors.teal : const Color(0xffADB5BD).withOpacity(0.5),
          textColor: Colors.white,
        ),
      ],
    );
  }

  Widget _buildRedirectPhase() {
    return Column(
      children: [
        Text(
          AppString.thankYouSupport.tr,
          style: AppTextStyle.latoBoldBlack16.copyWith(fontSize: 18.sp, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 16.h),
        Text(
          AppString.gladEnjoyingApp.tr,
          textAlign: TextAlign.center,
          style: AppTextStyle.latoRegularBlack14.copyWith(fontSize: 14.sp, color: const Color(0xff6C757D)),
        ),
        SizedBox(height: 24.h),
        CommonButton(
          text: AppString.shareLoveOnStore.tr,
          backgroundColor: AppColors.primary,
          textColor: Colors.white,
          onPressed: _redirectToStore,
        ),
        SizedBox(height: 12.h),
        _buildCancelButton(),
      ],
    );
  }

  Widget _buildFeedbackPhase() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppString.loveToImprove.tr,
          style: AppTextStyle.latoBoldBlack16.copyWith(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8.h),
        Text(
          AppString.whatCanWeDoBetter.tr,
          style: AppTextStyle.latoRegularBlack14.copyWith(fontSize: 14.sp, color: const Color(0xff6C757D)),
        ),
        SizedBox(height: 16.h),
        TextField(
          controller: _commentController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: AppString.enterYourFeedback.tr,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: Color(0xff4B9CFF)),
            ),
          ),
        ),
        SizedBox(height: 20.h),
        Row(
          children: [
            Expanded(child: _buildCancelButton()),
            SizedBox(width: 16.w),
            Expanded(
              child: CommonButton(
                text: AppString.sendFeedback.tr,
                backgroundColor: AppColors.primary,
                textColor: Colors.white,
                onPressed: _isSubmitting ? null : _submitFeedback,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCancelButton() {
    return GestureDetector(
      onTap: () => Get.back(),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 14.h),
        decoration: BoxDecoration(color: const Color(0xffEAF2FB), borderRadius: BorderRadius.circular(24.r)),
        child: Center(
          child: Text(
            AppString.notNow.tr,
            style: AppTextStyle.latoBoldPrimary16.copyWith(fontSize: 16.sp, color: const Color(0xff212529), fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

// FeedbackCommentDialog integrated into StarRatingDialog flow

class DailyTipBottomSheet extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback onContinue;

  const DailyTipBottomSheet({super.key, required this.title, required this.description, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24.r), topRight: Radius.circular(24.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 24.h),
          Text(
            AppString.tips.tr,
            style: AppTextStyle.latoBoldBlack16.copyWith(fontSize: 18.sp, fontWeight: FontWeight.w600, color: const Color(0xff212529)),
          ),
          SizedBox(height: 10.h),
          Text(
            AppString.dailyTips.tr,
            style: AppTextStyle.latoRegularBlack14.copyWith(fontSize: 15.sp, color: const Color(0xff6C757D)),
          ),
          SizedBox(height: 30.h),
          Assets.images.png.firstAward.image(scale: 2),
          SizedBox(height: 25.h),
          Text(
            title,
            style: AppTextStyle.latoBoldBlack16.copyWith(fontSize: 16.sp, fontWeight: FontWeight.w600, color: const Color(0xff212529)),
          ),
          SizedBox(height: 10.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            child: Text(
              description,
              textAlign: TextAlign.center,
              style: AppTextStyle.latoRegularBlack14.copyWith(fontSize: 14.sp, color: const Color(0xff6C757D), height: 1.5),
            ),
          ),
          SizedBox(height: 35.h),

          CommonButton(
            text: AppString.continueText.tr,
            onPressed: onContinue,
            backgroundColor: AppColors.primary,
            textColor: AppColors.white,
            textStyle: AppTextStyle.skipButton,
          ),
          SizedBox(height: 10.h),
        ],
      ),
    );
  }
}

class DropletWaveClipper extends CustomClipper<Path> {
  final double percentage;
  final double phase;

  DropletWaveClipper({required this.percentage, required this.phase});

  @override
  Path getClip(Size size) {
    var path = Path();
    double h = size.height;
    double w = size.width;
    double fillHeight = h * percentage;
    double yPos = h - fillHeight;

    path.moveTo(0, yPos);

    // Make wave height and wave count appropriate for the small droplet size
    double waveHeight = h * 0.08;
    double waveCount = 1.0;

    for (double i = 0; i <= w; i++) {
      double iPercentage = i / w;
      double dy =
          yPos + (percentage > 0 && percentage < 1.0 ? (math.sin((iPercentage * waveCount * 2 * math.pi) + phase) * waveHeight) : 0);
      path.lineTo(i, dy);
    }

    path.lineTo(w, h);
    path.lineTo(0, h);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant DropletWaveClipper oldClipper) {
    return oldClipper.percentage != percentage || oldClipper.phase != phase;
  }
}

class InnerDropletClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final double s = size.width / 24.0;
    final Path path = Path();
    path.moveTo(11.4351 * s, 2.73192 * s);
    path.cubicTo(10.6507 * s, 3.58221 * s, 9.66954 * s, 4.70628 * s, 8.69137 * s, 5.98493 * s);
    path.cubicTo(7.60131 * s, 7.40985 * s, 6.53737 * s, 8.99775 * s, 5.75134 * s, 10.5904 * s);
    path.cubicTo(4.95721 * s, 12.1994 * s, 4.5 * s, 13.7071 * s, 4.5 * s, 15 * s);

    // Bottom-left quarter circle (R=7.5)
    path.cubicTo(4.5 * s, 19.1421 * s, 7.8579 * s, 22.5 * s, 12 * s, 22.5 * s);

    // Bottom-right quarter circle (R=7.5)
    path.cubicTo(16.1421 * s, 22.5 * s, 19.5 * s, 19.1421 * s, 19.5 * s, 15 * s);

    path.cubicTo(19.5 * s, 13.1981 * s, 18.3064 * s, 11.7643 * s, 16.228 * s, 9.45105 * s);
    path.lineTo(16.1837 * s, 9.4018 * s);
    path.cubicTo(14.6233 * s, 7.66519 * s, 12.7493 * s, 5.5796 * s, 11.4351 * s, 2.73192 * s);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class DropletOutlinePainter extends CustomPainter {
  final Color color;

  DropletOutlinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Compound path for droplet outline (even-odd fill rule to cut out the inside)
    final path = Path()..fillType = PathFillType.evenOdd;
    final double s = size.width / 24.0;

    // Outer path
    path.moveTo(10.8138 * s, 1.20049 * s);
    path.cubicTo(11.5339 * s, 0.441767 * s, 12 * s, 0 * s, 12 * s, 0 * s);
    path.cubicTo(12.1633 * s, 0.544381 * s, 12.3503 * s, 1.06257 * s, 12.5568 * s, 1.55741 * s);
    path.cubicTo(13.7741 * s, 4.47563 * s, 15.6664 * s, 6.58168 * s, 17.3512 * s, 8.45686 * s);
    path.cubicTo(19.3168 * s, 10.6445 * s, 21 * s, 12.5179 * s, 21 * s, 15 * s);
    path.cubicTo(21 * s, 19.9706 * s, 16.9706 * s, 24 * s, 12 * s, 24 * s);
    path.cubicTo(7.02944 * s, 24 * s, 3 * s, 19.9706 * s, 3 * s, 15 * s);
    path.cubicTo(3 * s, 10.002 * s, 8.36969 * s, 3.77564 * s, 10.8138 * s, 1.20049 * s);
    path.close();

    // Inner cutout path
    path.moveTo(11.4351 * s, 2.73192 * s);
    path.cubicTo(10.6507 * s, 3.58221 * s, 9.66954 * s, 4.70628 * s, 8.69137 * s, 5.98493 * s);
    path.cubicTo(7.60131 * s, 7.40985 * s, 6.53737 * s, 8.99775 * s, 5.75134 * s, 10.5904 * s);
    path.cubicTo(4.95721 * s, 12.1994 * s, 4.5 * s, 13.7071 * s, 4.5 * s, 15 * s);

    // Bottom-left quarter circle (R=7.5)
    path.cubicTo(4.5 * s, 19.1421 * s, 7.8579 * s, 22.5 * s, 12 * s, 22.5 * s);

    // Bottom-right quarter circle (R=7.5)
    path.cubicTo(16.1421 * s, 22.5 * s, 19.5 * s, 19.1421 * s, 19.5 * s, 15 * s);

    path.cubicTo(19.5 * s, 13.1981 * s, 18.3064 * s, 11.7643 * s, 16.228 * s, 9.45105 * s);
    path.lineTo(16.1837 * s, 9.4018 * s);
    path.cubicTo(14.6233 * s, 7.66519 * s, 12.7493 * s, 5.5796 * s, 11.4351 * s, 2.73192 * s);
    path.close();

    canvas.drawPath(path, paint);

    // Reflection highlight crescent
    final reflectionPath = Path();
    reflectionPath.moveTo(6.82918 * s, 11.6646 * s);
    reflectionPath.cubicTo(8.06032 * s, 9.20231 * s, 9.40539 * s, 7.53395 * s, 9.96967 * s, 6.96967 * s);
    reflectionPath.lineTo(11.0303 * s, 8.03033 * s);
    reflectionPath.cubicTo(10.5946 * s, 8.46605 * s, 9.33968 * s, 9.99769 * s, 8.17082 * s, 12.3354 * s);
    reflectionPath.lineTo(6.82918 * s, 11.6646 * s);
    reflectionPath.close();

    canvas.drawPath(reflectionPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DropletWaterWaveWidget extends StatefulWidget {
  final double percentage;
  final Color color;

  const DropletWaterWaveWidget({super.key, required this.percentage, required this.color});

  @override
  State<DropletWaterWaveWidget> createState() => _DropletWaterWaveWidgetState();
}

class _DropletWaterWaveWidgetState extends State<DropletWaterWaveWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.percentage <= 0.0) {
      return const SizedBox.shrink();
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          children: [
            // Background wave (low opacity)
            ClipPath(
              clipper: DropletWaveClipper(percentage: widget.percentage, phase: _controller.value * 2 * math.pi),
              child: Container(color: widget.color.withOpacity(0.35)),
            ),
            // Foreground wave (gradient)
            ClipPath(
              clipper: DropletWaveClipper(percentage: widget.percentage, phase: -_controller.value * 2 * math.pi),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [widget.color, widget.color.withOpacity(0.85)],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class DynamicDropletWaveWidget extends StatelessWidget {
  final double percentage;
  final double size;

  const DynamicDropletWaveWidget({super.key, required this.percentage, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // 1. Water wave inside inner droplet shape
          ClipPath(
            clipper: InnerDropletClipper(),
            child: DropletWaterWaveWidget(percentage: percentage, color: AppColors.teal),
          ),
          // 2. High-res vector outline & glare reflections on top
          CustomPaint(
            size: Size(size, size),
            painter: DropletOutlinePainter(color: AppColors.teal),
          ),
        ],
      ),
    );
  }
}

class InnerHeartClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final double s = size.width / 24.0;
    final Path path = Path();
    path.moveTo(12 * s, 21.35 * s);
    path.lineTo(10.55 * s, 20.03 * s);
    path.cubicTo(5.4 * s, 15.36 * s, 2 * s, 12.28 * s, 2 * s, 8.5 * s);
    path.cubicTo(2 * s, 5.42 * s, 4.42 * s, 3 * s, 7.5 * s, 3 * s);
    path.cubicTo(9.24 * s, 3 * s, 10.91 * s, 3.81 * s, 12 * s, 5.09 * s);
    path.cubicTo(13.09 * s, 3.81 * s, 14.76 * s, 3 * s, 16.5 * s, 3 * s);
    path.cubicTo(19.58 * s, 3 * s, 22 * s, 5.42 * s, 22 * s, 8.5 * s);
    path.cubicTo(22 * s, 12.28 * s, 18.6 * s, 15.36 * s, 13.45 * s, 20.04 * s);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class HeartOutlinePainter extends CustomPainter {
  final Color color;

  HeartOutlinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width / 24.0;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final Path path = Path();
    path.moveTo(12 * s, 21.35 * s);
    path.lineTo(10.55 * s, 20.03 * s);
    path.cubicTo(5.4 * s, 15.36 * s, 2 * s, 12.28 * s, 2 * s, 8.5 * s);
    path.cubicTo(2 * s, 5.42 * s, 4.42 * s, 3 * s, 7.5 * s, 3 * s);
    path.cubicTo(9.24 * s, 3 * s, 10.91 * s, 3.81 * s, 12 * s, 5.09 * s);
    path.cubicTo(13.09 * s, 3.81 * s, 14.76 * s, 3 * s, 16.5 * s, 3 * s);
    path.cubicTo(19.58 * s, 3 * s, 22 * s, 5.42 * s, 22 * s, 8.5 * s);
    path.cubicTo(22 * s, 12.28 * s, 18.6 * s, 15.36 * s, 13.45 * s, 20.04 * s);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DynamicHeartWaveWidget extends StatelessWidget {
  final double percentage;
  final double size;

  const DynamicHeartWaveWidget({super.key, required this.percentage, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // 1. Water wave inside inner heart shape
          ClipPath(
            clipper: InnerHeartClipper(),
            child: DropletWaterWaveWidget(percentage: percentage, color: AppColors.accent),
          ),
          // 2. High-res vector outline on top
          CustomPaint(
            size: Size(size, size),
            painter: HeartOutlinePainter(color: AppColors.accent),
          ),
        ],
      ),
    );
  }
}

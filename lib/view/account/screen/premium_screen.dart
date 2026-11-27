import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:water_intake/gen/assets.gen.dart';
import 'package:water_intake/theme/app_text_styles.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:water_intake/route/route.dart';
import 'package:water_intake/services/iap_service.dart';
import 'package:water_intake/theme/app_colors.dart';
import 'package:water_intake/utils/app_strings.dart';
import 'package:water_intake/view/account/widget/hydration_plus_dashboard.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  final _billing = IAPService.instance;
  int? _months;

  @override
  void initState() {
    super.initState();
    if (IAPService.enabled && !_billing.isPremium) _billing.loadPlans();
  }

  String _duration(int months) => months == 1
      ? AppString.plusOneMonth.tr
      : AppString.plusMonths.trParams({'months': months.toString()});

  String _notice(BillingNotice notice) => switch (notice) {
    BillingNotice.unavailable => AppString.plusUnavailable.tr,
    BillingNotice.pending => 'Your purchase is awaiting store approval.'.tr,
    BillingNotice.purchaseFailed =>
      'Could not start the purchase. Try again.'.tr,
    BillingNotice.restored => 'Your subscription was restored.'.tr,
    BillingNotice.noSubscription =>
      'No active subscription was found on this store account.'.tr,
    BillingNotice.verificationUnavailable =>
      'Could not verify your purchase. Try Restore purchases again when online.'
          .tr,
  };

  Future<void> _manage() async {
    final url = Uri.parse(
      GetPlatform.isIOS
          ? 'https://apps.apple.com/account/subscriptions'
          : 'https://play.google.com/store/account/subscriptions?package=com.sarang.waterreminder',
    );
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
          child: Column(
            children: [
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: IconButton(
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  icon: Icon(
                    Icons.close,
                    color: const Color(0xff8596AB),
                    size: 24.sp,
                  ),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
              Expanded(
                child: AnimatedBuilder(
                  animation: _billing,
                  builder: (context, _) => SingleChildScrollView(
                    child: _billing.isPremium
                        ? _activeSubscription()
                        : _paywall(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _activeSubscription() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'Hydration Plus',
        style: AppTextStyle.latoBoldBlack16.copyWith(fontSize: 22.sp),
      ),
      ListTile(
        leading: const Icon(Icons.verified_outlined, color: AppColors.teal),
        title: Text(AppString.plusActive.tr),
        trailing: TextButton(
          onPressed: _manage,
          child: Text(AppString.plusManage.tr),
        ),
      ),
      const Divider(),
      const HydrationPlusDashboard(),
      _legalLinks(),
    ],
  );

  Widget _paywall() {
    final plans = {for (final plan in _billing.plans) plan.months: plan};
    final selected = plans[_months] ?? _billing.plans.firstOrNull;
    final hasTrial = selected?.hasSevenDayTrial ?? false;
    final notice = _billing.notice;
    final canPurchase =
        selected != null &&
        !_billing.busy &&
        !_billing.pending &&
        !_billing.loading;
    final disclosure = selected == null
        ? null
        : (hasTrial ? AppString.plusTrialRenewal : AppString.plusRenewal)
              .trParams({
                'price': selected.price,
                'period': _duration(selected.months),
              });

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(5.w),
          decoration: BoxDecoration(
            color: AppColors.teal.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Assets.images.png.king.image(scale: 14 / 1.sp),
        ),
        SizedBox(height: 16.h),
        Text(
          AppString.upgradeToPremium.tr,
          textAlign: TextAlign.center,
          style: AppTextStyle.latoBoldBlack16.copyWith(
            fontSize: 22.sp,
            color: AppColors.black1,
            fontWeight: FontWeight.w700,
            height: 1.3,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          AppString.premiumSubtitle.tr,
          textAlign: TextAlign.center,
          style: AppTextStyle.latoRegularBlack14.copyWith(
            fontSize: 13.sp,
            color: AppColors.grey4,
            height: 1.4,
          ),
        ),
        SizedBox(height: 24.h),
        _buildPremiumFeature(
          Assets.images.png.bottle.image(scale: 3.5, color: AppColors.teal),
          'Hydration trends'.tr,
          'See how weekdays and weekends compare.'.tr,
        ),
        _buildPremiumFeature(
          Assets.images.png.exit.image(scale: 3.5, color: AppColors.teal),
          AppString.noAds.tr,
          AppString.noAdsDesc.tr,
        ),
        _buildPremiumFeature(
          Assets.images.png.time.image(scale: 4, color: AppColors.teal),
          AppString.smartReminders.tr,
          'Get suggestions based on your logging history.'.tr,
        ),
        _buildPremiumFeature(
          Assets.images.png.primiu.image(scale: 4, color: AppColors.teal),
          AppString.premiumInsights.tr,
          'Review your 30- and 90-day hydration reports.'.tr,
        ),
        SizedBox(height: 30.h),
        Text(
          hasTrial ? AppString.startYourFreeTrial.tr : 'Choose a plan'.tr,
          style: AppTextStyle.latoBoldBlack16.copyWith(
            fontSize: 20.sp,
            color: AppColors.black1,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 24.h),
        if (_billing.loading) ...[
          const LinearProgressIndicator(),
          SizedBox(height: 16.h),
        ],
        for (final months in [1, 3, 6]) ...[
          _buildPlanCard(
            months: months,
            plan: plans[months],
            isSelected: selected?.months == months,
          ),
          SizedBox(height: 16.h),
        ],
        SizedBox(height: 14.h),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            key: const Key('premium-checkout'),
            onPressed: canPurchase ? () => _billing.purchase(selected) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.teal,
              foregroundColor: Colors.white,
              minimumSize: Size(0, 45.h),
              padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 14.w),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.r),
              ),
              elevation: 0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  (hasTrial
                          ? AppString.plusStartTrial
                          : AppString.plusSubscribe)
                      .tr,
                  textAlign: TextAlign.center,
                  style: AppTextStyle.latoBoldWhite16.copyWith(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: canPurchase ? Colors.white : AppColors.grey4,
                  ),
                ),
                if (disclosure != null)
                  Text(
                    disclosure,
                    textAlign: TextAlign.center,
                    style: AppTextStyle.latoRegularBlack14.copyWith(
                      fontSize: 11.sp,
                      color: canPurchase
                          ? Colors.white.withValues(alpha: 0.9)
                          : AppColors.grey4,
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (selected != null) ...[
          SizedBox(height: 12.h),
          Text(
            AppString.plusCancel.tr,
            textAlign: TextAlign.center,
            style: AppTextStyle.latoRegularBlack14.copyWith(
              fontSize: 11.sp,
              color: AppColors.teal,
            ),
          ),
        ],
        if (notice != null) ...[
          SizedBox(height: 12.h),
          Text(_notice(notice), textAlign: TextAlign.center),
        ],
        if (_billing.busy) const LinearProgressIndicator(),
        if (IAPService.enabled)
          Wrap(
            alignment: WrapAlignment.center,
            children: [
              if (plans.isEmpty && !_billing.loading)
                TextButton(
                  onPressed: _billing.busy ? null : _billing.loadPlans,
                  child: Text('Retry'.tr),
                ),
              TextButton(
                onPressed: _billing.busy ? null : _billing.restore,
                child: Text(AppString.plusRestore.tr),
              ),
            ],
          ),
        _legalLinks(),
        SizedBox(height: 15.h),
      ],
    );
  }

  Widget _legalLinks() => Wrap(
    alignment: WrapAlignment.center,
    children: [
      TextButton(
        onPressed: () => Get.toNamed(AppRoutes.termsAndConditions),
        child: Text(AppString.termsAndConditions.tr),
      ),
      TextButton(
        onPressed: () => Get.toNamed(AppRoutes.privacyPolicy),
        child: Text(AppString.privacyPolicy.tr),
      ),
    ],
  );

  Widget _buildPremiumFeature(Widget iconWidget, String title, String desc) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: iconWidget,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyle.latoRegularBlack14.copyWith(
                    fontSize: 14.sp,
                    color: AppColors.black1,
                  ),
                ),
                Text(
                  desc,
                  style: AppTextStyle.latoRegularBlack14.copyWith(
                    fontSize: 12.sp,
                    color: AppColors.grey5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required int months,
    required SubscriptionPlan? plan,
    required bool isSelected,
  }) {
    final title = _duration(months);
    final badge = isSelected && plan?.hasSevenDayTrial == true;
    final selectable = plan != null && !_billing.loading && !_billing.busy;
    return Semantics(
      button: true,
      selected: isSelected,
      enabled: selectable,
      child: GestureDetector(
        onTap: selectable ? () => setState(() => _months = months) : null,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: isSelected ? AppColors.teal : Colors.grey.shade200,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? AppColors.teal.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.02),
                    blurRadius: isSelected ? 10 : 4,
                    offset: Offset(0, isSelected ? 4 : 0),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: isSelected
                        ? AppColors.teal
                        : const Color(0xffADB5BD),
                    size: 24.sp,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTextStyle.latoRegularBlack14.copyWith(
                            fontSize: 14.sp,
                            color: AppColors.black1,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          plan == null
                              ? (_billing.loading
                                    ? 'Loading price…'.tr
                                    : 'Price unavailable'.tr)
                              : AppString.plusBillingPeriod.trParams({
                                  'period': title,
                                }),
                          style: AppTextStyle.latoRegularBlack14.copyWith(
                            fontSize: 12.sp,
                            color: AppColors.grey4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (plan != null)
                    Flexible(
                      child: Text(
                        plan.price,
                        textAlign: TextAlign.end,
                        style: AppTextStyle.latoBoldBlack16.copyWith(
                          fontSize: 16.sp,
                          color: AppColors.black1,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (badge)
              PositionedDirectional(
                top: -10.h,
                end: 20.w,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xffFEE2E2),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    AppString.plusFreeWeek.tr,
                    style: AppTextStyle.latoBoldWhite16.copyWith(
                      fontSize: 10.sp,
                      color: const Color(0xffFF3B30),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

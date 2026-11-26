import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:water_intake/services/ad_service.dart';
import 'package:water_intake/theme/app_colors.dart';
import 'package:water_intake/theme/rewarded_theme.dart';
import 'package:water_intake/utils/app_strings.dart';
import 'package:water_intake/view/dashboard/controller/dashboard_controller.dart';

class RewardedThemeCard extends StatefulWidget {
  const RewardedThemeCard({super.key});

  @override
  State<RewardedThemeCard> createState() => _RewardedThemeCardState();
}

class _RewardedThemeCardState extends State<RewardedThemeCard> {
  final _reward = ThemeReward.instance;
  late final _updates = Listenable.merge([
    _reward,
    AdService.placementRevision,
  ]);
  bool _requestingAd = false;

  bool _isAccountVisible() =>
      mounted &&
      ModalRoute.of(context)?.isCurrent == true &&
      Get.find<DashboardController>().selectedIndex.value == 3;

  Future<void> _watchAd() async {
    setState(() => _requestingAd = true);
    final shown = await AdService.watchThemeReward(
      canPresent: _isAccountVisible,
    );
    if (!mounted) return;
    setState(() => _requestingAd = false);
    if (!shown && _isAccountVisible()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppString.rewardedAdUnavailable.tr)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _updates,
      builder: (context, _) {
        final expiry = _reward.value;
        if (expiry == null && !AdService.canOfferThemeReward) {
          return const SizedBox.shrink();
        }
        final localizations = MaterialLocalizations.of(context);
        final textTheme = Theme.of(context).textTheme;
        final description = expiry == null
            ? AppString.rewardedThemeOffer.tr
            : AppString.rewardedThemeActiveUntil.trParams({
                'date': localizations.formatShortDate(expiry),
                'time': localizations.formatTimeOfDay(
                  TimeOfDay.fromDateTime(expiry),
                ),
              });
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F4FF),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFDCD4FB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.palette_outlined, color: Color(0xFF5542AC)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ocean Dusk',
                      style: textTheme.titleSmall?.copyWith(
                        color: AppColors.black1,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: textTheme.bodySmall?.copyWith(color: AppColors.black2),
              ),
              if (expiry == null) ...[
                const SizedBox(height: 8),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: HydrationPalette.oceanDusk.accent,
                  ),
                  onPressed: _requestingAd ? null : _watchAd,
                  icon: _requestingAd
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_circle_outline),
                  label: Text(AppString.watchAdForTheme.tr),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:water_intake/theme/app_colors.dart';
import 'package:water_intake/theme/rewarded_theme.dart';
import 'package:water_intake/utils/app_strings.dart';
import 'package:water_intake/view/home/controller/home_controller.dart';

class MilestoneThemeCard extends StatelessWidget {
  const MilestoneThemeCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = MilestoneTheme.instance;
    final home = Get.find<HomeController>();
    return ListenableBuilder(
      listenable: theme,
      builder: (context, _) {
        return Card(
          margin: const EdgeInsets.only(bottom: 20),
          color: AppColors.card,
          child: theme.unlocked
              ? SwitchListTile(
                  secondary: const Icon(
                    Icons.palette_outlined,
                    color: Color(0xFF28643D),
                  ),
                  title: const Text('Forest Spring'),
                  subtitle: Text(AppString.milestoneThemeUnlocked.tr),
                  value: theme.selected,
                  onChanged: theme.select,
                )
              : ListTile(
                  leading: const Icon(
                    Icons.lock_outline,
                    color: Color(0xFF28643D),
                  ),
                  title: const Text('Forest Spring'),
                  subtitle: Obx(
                    () => Text(
                      AppString.milestoneThemeProgress.trParams({
                        'days': home.currentStreak.value
                            .clamp(0, MilestoneTheme.requiredStreak)
                            .toString(),
                      }),
                    ),
                  ),
                ),
        );
      },
    );
  }
}

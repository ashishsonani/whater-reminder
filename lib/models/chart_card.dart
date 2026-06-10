import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'chart_point.dart';
import 'animated_bar_chart.dart';
import 'animated_line_chart.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_shadows.dart';
import '../../../theme/app_typography.dart';


/// Reusable card containing a chart title, bar/line mode toggle, and the
/// chart itself. When mode or data changes, the chart cross-fades to the
/// new state so the transition stays smooth.
class ChartCard extends StatelessWidget {
  final String title;
  final List<ChartPoint> points;
  final double maxY;
  final String Function(double v) yLabel;
  final String Function(double v) valueLabel;
  final ChartMode mode;
  final ValueChanged<ChartMode> onModeChange;

  const ChartCard({
    super.key,
    required this.title,
    required this.points,
    required this.maxY,
    required this.yLabel,
    required this.valueLabel,
    required this.mode,
    required this.onModeChange,
  });

  @override
  Widget build(BuildContext context) {
    // Key combining mode + first-point reference so AnimatedSwitcher
    // re-runs whenever either changes.
    final chartKey = ValueKey('${mode.name}-${points.length}-${points.first.label}-${points.first.value}');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.cardEdge),
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.level1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.sectionTitle.copyWith(fontSize: 16),
                ),
              ),
              _ModeToggle(mode: mode, onChange: onModeChange),
            ],
          ),
          const SizedBox(height: 6),
          Container(height: 1, color: AppColors.cardEdge),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, anim) {
              return FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.04),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              );
            },
            child: mode == ChartMode.bar
                ? AnimatedBarChart(
              key: chartKey,
              points: points,
              maxY: maxY,
              yLabel: yLabel,
              valueLabel: valueLabel,
            )
                : AnimatedLineChart(
              key: chartKey,
              points: points,
              maxY: maxY,
              yLabel: yLabel,
              valueLabel: valueLabel,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  final ChartMode mode;
  final ValueChanged<ChartMode> onChange;
  const _ModeToggle({required this.mode, required this.onChange});

  @override
  Widget build(BuildContext context) {
    const double w = 36;
    const double h = 28;
    final isBar = mode == ChartMode.bar;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.paperWarm,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment:
            isBar ? Alignment.centerLeft : Alignment.centerRight,
            child: Container(
              width: w,
              height: h,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.tealBright, AppColors.teal],
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.teal.withOpacity(0.22),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              _IconSlot(
                width: w,
                height: h,
                icon: Icons.bar_chart_rounded,
                selected: isBar,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onChange(ChartMode.bar);
                },
              ),
              _IconSlot(
                width: w,
                height: h,
                icon: Icons.show_chart_rounded,
                selected: !isBar,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onChange(ChartMode.line);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IconSlot extends StatelessWidget {
  final double width;
  final double height;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _IconSlot({
    required this.width,
    required this.height,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: SizedBox(
        width: width,
        height: height,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            icon,
            key: ValueKey(selected),
            size: 16,
            color: selected ? Colors.white : AppColors.inkMute,
          ),
        ),
      ),
    );
  }
}

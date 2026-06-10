import 'package:flutter/material.dart';
import 'chart_point.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';

/// Bar chart with staggered grow-in animation, dashed gridlines and a
/// floating tooltip over the peak bar. Re-runs the grow tween whenever
/// the data set changes (period switch).
class AnimatedBarChart extends StatefulWidget {
  final List<ChartPoint> points;
  final double maxY;
  final String Function(double v) yLabel;
  final String Function(double v) valueLabel;

  const AnimatedBarChart({
    super.key,
    required this.points,
    required this.maxY,
    required this.yLabel,
    required this.valueLabel,
  });

  @override
  State<AnimatedBarChart> createState() => _AnimatedBarChartState();
}

class _AnimatedBarChartState extends State<AnimatedBarChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  @override
  void didUpdateWidget(covariant AnimatedBarChart old) {
    super.didUpdateWidget(old);
    if (old.points != widget.points) {
      _ctrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: Padding(
        padding: const EdgeInsets.only(top: 8, right: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _YAxisLabels(maxY: widget.maxY, format: widget.yLabel),
            const SizedBox(width: 6),
            Expanded(
              child: AnimatedBuilder(
                animation: _ctrl,
                builder: (_, __) => CustomPaint(
                  painter: _BarChartPainter(
                    points: widget.points,
                    maxY: widget.maxY,
                    progress: _ctrl.value,
                    valueLabel: widget.valueLabel,
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

class _YAxisLabels extends StatelessWidget {
  final double maxY;
  final String Function(double v) format;
  const _YAxisLabels({required this.maxY, required this.format});

  @override
  Widget build(BuildContext context) {
    const ticks = 6;
    final values =
    List.generate(ticks, (i) => maxY - (maxY / (ticks - 1)) * i);
    return Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: values
            .map((v) => Text(
          format(v),
          style: AppTypography.statSmall.copyWith(fontSize: 10),
        ))
            .toList(),
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<ChartPoint> points;
  final double maxY;
  final double progress;
  final String Function(double v) valueLabel;

  _BarChartPainter({
    required this.points,
    required this.maxY,
    required this.progress,
    required this.valueLabel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const bottomLabelArea = 26.0;
    final chartH = size.height - bottomLabelArea;
    final chartRect = Rect.fromLTWH(0, 0, size.width, chartH);

    _drawGrid(canvas, chartRect);

    final n = points.length;
    final slot = chartRect.width / n;
    final maxBarWidth = (slot * 0.55).clamp(10.0, 22.0);

    int peakIndex = 0;
    for (var i = 1; i < points.length; i++) {
      if (points[i].value > points[peakIndex].value) peakIndex = i;
    }

    for (var i = 0; i < n; i++) {
      final p = points[i];
      final cx = slot * i + slot / 2;

      final barStart = Curves.easeOutCubic.transform(
        ((progress - i * 0.06) / 0.55).clamp(0.0, 1.0),
      );
      final h = chartH * (p.value / maxY) * barStart;

      final rect = Rect.fromLTWH(
        cx - maxBarWidth / 2,
        chartH - h,
        maxBarWidth,
        h,
      );
      final rrect = RRect.fromRectAndCorners(
        rect,
        topLeft: const Radius.circular(8),
        topRight: const Radius.circular(8),
      );

      final barPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.tealBright,
            AppColors.teal.withOpacity(0.92),
          ],
        ).createShader(rect);
      canvas.drawRRect(rrect, barPaint);

      // Label
      _paintText(
        canvas,
        text: p.label,
        position: Offset(cx, chartH + 12),
        style: AppTypography.statSmall.copyWith(fontSize: 10),
        align: TextAlign.center,
      );

      // Peak value tooltip
      if (i == peakIndex && progress > 0.55) {
        final fade = ((progress - 0.55) / 0.45).clamp(0.0, 1.0);
        _paintTooltip(
          canvas,
          center: Offset(cx, chartH - h - 14),
          label: valueLabel(p.value),
          opacity: fade,
        );
      }
    }
  }

  void _drawGrid(Canvas canvas, Rect rect) {
    final paint = Paint()
      ..color = AppColors.cardEdge
      ..strokeWidth = 1;
    const ticks = 6;
    for (var i = 0; i < ticks; i++) {
      final y = rect.height * (i / (ticks - 1));
      _drawDashedLine(
        canvas,
        Offset(rect.left, y),
        Offset(rect.right, y),
        paint,
      );
    }
  }

  void _drawDashedLine(Canvas canvas, Offset a, Offset b, Paint paint) {
    const dash = 4.0;
    const gap = 4.0;
    final dx = b.dx - a.dx;
    final length = dx.abs();
    var d = 0.0;
    while (d < length) {
      final start = Offset(a.dx + d, a.dy);
      final end = Offset(a.dx + (d + dash).clamp(0.0, length), b.dy);
      canvas.drawLine(start, end, paint);
      d += dash + gap;
    }
  }

  void _paintText(
      Canvas canvas, {
        required String text,
        required Offset position,
        required TextStyle style,
        TextAlign align = TextAlign.center,
      }) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: align,
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, position - Offset(tp.width / 2, 0));
  }

  void _paintTooltip(
      Canvas canvas, {
        required Offset center,
        required String label,
        required double opacity,
      }) {
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: AppTypography.actionLabel.copyWith(
          color: Colors.white.withOpacity(opacity),
          fontSize: 10,
          letterSpacing: 0.3,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final w = tp.width + 12;
    final h = tp.height + 6;
    final rect = Rect.fromCenter(center: center, width: w, height: h);
    final paint = Paint()..color = AppColors.teal.withOpacity(opacity);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(6)),
      paint,
    );
    final tipPath = Path()
      ..moveTo(center.dx - 4, rect.bottom)
      ..lineTo(center.dx + 4, rect.bottom)
      ..lineTo(center.dx, rect.bottom + 4)
      ..close();
    canvas.drawPath(tipPath, paint);
    tp.paint(
      canvas,
      Offset(center.dx - tp.width / 2, center.dy - tp.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter old) =>
      old.progress != progress ||
          old.points != points ||
          old.maxY != maxY;
}

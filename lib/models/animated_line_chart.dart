import 'package:flutter/material.dart';
import 'chart_point.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';

/// Line chart with a smooth Catmull–Rom path that draws progressively
/// from left to right. The area beneath is filled with a fading gradient.
class AnimatedLineChart extends StatefulWidget {
  final List<ChartPoint> points;
  final double maxY;
  final String Function(double v) yLabel;
  final String Function(double v) valueLabel;

  const AnimatedLineChart({
    super.key,
    required this.points,
    required this.maxY,
    required this.yLabel,
    required this.valueLabel,
  });

  @override
  State<AnimatedLineChart> createState() => _AnimatedLineChartState();
}

class _AnimatedLineChartState extends State<AnimatedLineChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();

  @override
  void didUpdateWidget(covariant AnimatedLineChart old) {
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
                  painter: _LinePainter(
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

class _LinePainter extends CustomPainter {
  final List<ChartPoint> points;
  final double maxY;
  final double progress;
  final String Function(double v) valueLabel;

  _LinePainter({
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

    if (points.isEmpty) return;

    final coords = <Offset>[];
    final n = points.length;
    final slot = chartRect.width / n;
    for (var i = 0; i < n; i++) {
      final cx = slot * i + slot / 2;
      final y = chartH * (1 - (points[i].value / maxY));
      coords.add(Offset(cx, y));
    }

    final smoothed = _catmullRomPath(coords);

    // Filled area under the curve.
    final eased = Curves.easeInOutCubic.transform(progress);
    final clipWidth = chartRect.width * eased;
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, clipWidth, chartH + bottomLabelArea));

    final fillPath = Path.from(smoothed)
      ..lineTo(coords.last.dx, chartH)
      ..lineTo(coords.first.dx, chartH)
      ..close();
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.tealBright.withOpacity(0.32),
          AppColors.tealBright.withOpacity(0.0),
        ],
      ).createShader(chartRect);
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = AppColors.teal
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(smoothed, linePaint);

    canvas.restore();

    // Dots that fade in as the line reaches them.
    for (var i = 0; i < n; i++) {
      final t = (i + 0.5) / n;
      final appear = ((eased - t + 0.05) / 0.12).clamp(0.0, 1.0);
      if (appear <= 0) continue;
      final dotR = 4.0 * appear;
      canvas.drawCircle(
        coords[i],
        dotR + 2,
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        coords[i],
        dotR,
        Paint()..color = AppColors.teal,
      );
    }

    // x-axis labels
    for (var i = 0; i < n; i++) {
      _paintText(
        canvas,
        text: points[i].label,
        position: Offset(coords[i].dx, chartH + 12),
        style: AppTypography.statSmall.copyWith(fontSize: 10),
      );
    }

    // Tooltip on the peak point.
    int peakIndex = 0;
    for (var i = 1; i < points.length; i++) {
      if (points[i].value > points[peakIndex].value) peakIndex = i;
    }
    if (progress > 0.7) {
      final fade = ((progress - 0.7) / 0.3).clamp(0.0, 1.0);
      _paintTooltip(
        canvas,
        center: coords[peakIndex] + const Offset(0, -16),
        label: valueLabel(points[peakIndex].value),
        opacity: fade,
      );
    }
  }

  Path _catmullRomPath(List<Offset> pts) {
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 0; i < pts.length - 1; i++) {
      final p0 = i == 0 ? pts[i] : pts[i - 1];
      final p1 = pts[i];
      final p2 = pts[i + 1];
      final p3 = i + 2 < pts.length ? pts[i + 2] : p2;

      final c1 = Offset(
        p1.dx + (p2.dx - p0.dx) / 6,
        p1.dy + (p2.dy - p0.dy) / 6,
      );
      final c2 = Offset(
        p2.dx - (p3.dx - p1.dx) / 6,
        p2.dy - (p3.dy - p1.dy) / 6,
      );
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    }
    return path;
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
    final length = (b.dx - a.dx).abs();
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
      }) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
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
  bool shouldRepaint(covariant _LinePainter old) =>
      old.progress != progress ||
          old.points != points ||
          old.maxY != maxY;
}

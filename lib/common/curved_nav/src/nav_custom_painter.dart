import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'dart:io';

/// Max notch width as a fraction of the bar width (original package value).
const double _maxNotchFraction = 0.2;

/// Absolute notch width cap in logical pixels. On phones (~390 wide) the
/// original 0.2 fraction (~78px) wins, so nothing changes there. On tablets
/// this cap keeps the notch hugging the floating button instead of
/// stretching into a wide shallow dish across the screen.
const double _maxNotchWidth = 92.0;

class NavCustomPainter extends CustomPainter {
  late double loc;
  late double s;
  late double bottom;
  Color color;
  bool hasLabel;
  TextDirection textDirection;

  NavCustomPainter({
    required double startingLoc,
    required int itemsLength,
    required double barWidth,
    required this.color,
    required this.textDirection,
    this.hasLabel = false,
  }) {
    // Notch width: fraction of the bar, capped in absolute pixels so wide
    // (tablet) bars keep phone-like proportions around the floating button.
    s = math.min(_maxNotchFraction, _maxNotchWidth / barWidth);
    final span = 1.0 / itemsLength;
    final l = startingLoc + (span - s) / 2;
    loc = textDirection == TextDirection.rtl ? 0.8 - l : l;
    bottom = hasLabel
        ? (Platform.isAndroid ? 0.55 : 0.45)
        : (Platform.isAndroid ? 0.6 : 0.5);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * (loc - 0.05), 0)
      ..cubicTo(
        size.width * (loc + s * 0.2), // topX
        size.height * 0.05, // topY
        size.width * loc, // bottomX
        size.height * bottom, // bottomY
        size.width * (loc + s * 0.5), // centerX
        size.height * bottom, // centerY
      )
      ..cubicTo(
        size.width * (loc + s), // bottomX
        size.height * bottom, // bottomY
        size.width * (loc + s * 0.8), // topX
        size.height * 0.05, // topY
        size.width * (loc + s + 0.05),
        0,
      )
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant NavCustomPainter oldDelegate) {
    return oldDelegate.loc != loc ||
        oldDelegate.s != s ||
        oldDelegate.color != color ||
        oldDelegate.bottom != bottom;
  }
}

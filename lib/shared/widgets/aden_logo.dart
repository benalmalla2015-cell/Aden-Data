import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../app/theme.dart';

class AdenLogo extends StatelessWidget {
  final double size;
  const AdenLogo({super.key, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _LogoPainter(),
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final colors = [
      const Color(0xFF1E3A8A),
      const Color(0xFF2563EB),
      const Color(0xFF3B82F6),
      const Color(0xFF60A5FA),
    ];
    for (int i = 0; i < 4; i++) {
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * 0.08
        ..strokeCap = StrokeCap.round;
      final yBase = h * (0.2 + i * 0.2);
      final path = Path();
      path.moveTo(0, yBase);
      path.cubicTo(
        w * 0.3,
        yBase - h * 0.1,
        w * 0.7,
        yBase + h * 0.1,
        w,
        yBase,
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SpeedGaugePainter extends CustomPainter {
  final double value;
  final Color primaryColor;
  final Color bgColor;

  SpeedGaugePainter({
    required this.value,
    required this.primaryColor,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 12;

    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    final fgPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    const startAngle = math.pi * 0.75;
    const sweepAngle = math.pi * 1.5;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    final clampedValue = value.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle * clampedValue,
      false,
      fgPaint,
    );

    final needleAngle = startAngle + sweepAngle * clampedValue;
    final needleEnd = Offset(
      center.dx + (radius - 20) * math.cos(needleAngle),
      center.dy + (radius - 20) * math.sin(needleAngle),
    );
    final needlePaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, needleEnd, needlePaint);

    final dotPaint = Paint()..color = primaryColor;
    canvas.drawCircle(center, 6, dotPaint);
  }

  @override
  bool shouldRepaint(covariant SpeedGaugePainter old) =>
      old.value != value;
}

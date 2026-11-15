import 'package:flutter/material.dart';

class LaserReticlePainter extends CustomPainter {
  final double animationValue; // 0.0 to 1.0
  final Color laserColor;
  final Color cornerColor;

  LaserReticlePainter({
    required this.animationValue,
    required this.laserColor,
    required this.cornerColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    const cornerLength = 24.0;
    const cornerStroke = 3.5;

    final cornerPaint = Paint()
      ..color = cornerColor
      ..strokeWidth = cornerStroke
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Top-Left
    canvas.drawLine(
      rect.topLeft,
      rect.topLeft + const Offset(cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      rect.topLeft,
      rect.topLeft + const Offset(0, cornerLength),
      cornerPaint,
    );

    // Top-Right
    canvas.drawLine(
      rect.topRight,
      rect.topRight + const Offset(-cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      rect.topRight,
      rect.topRight + const Offset(0, cornerLength),
      cornerPaint,
    );

    // Bottom-Left
    canvas.drawLine(
      rect.bottomLeft,
      rect.bottomLeft + const Offset(cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      rect.bottomLeft,
      rect.bottomLeft + const Offset(0, -cornerLength),
      cornerPaint,
    );

    // Bottom-Right
    canvas.drawLine(
      rect.bottomRight,
      rect.bottomRight + const Offset(-cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      rect.bottomRight,
      rect.bottomRight + const Offset(0, -cornerLength),
      cornerPaint,
    );

    // Animated Red/Emerald Laser Line
    final laserY = rect.top + rect.height * animationValue;
    final laserPaint = Paint()
      ..color = laserColor
      ..strokeWidth = 2.0
      ..shader = LinearGradient(
        colors: [laserColor.withAlpha(0), laserColor, laserColor.withAlpha(0)],
      ).createShader(Rect.fromLTWH(rect.left, laserY - 1, rect.width, 2));

    canvas.drawLine(
      Offset(rect.left + 4, laserY),
      Offset(rect.right - 4, laserY),
      laserPaint,
    );

    // Laser glow shadow
    final glowPaint = Paint()
      ..color = laserColor.withAlpha(50)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawRect(
      Rect.fromLTWH(rect.left + 6, laserY - 3, rect.width - 12, 6),
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant LaserReticlePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.laserColor != laserColor ||
        oldDelegate.cornerColor != cornerColor;
  }
}

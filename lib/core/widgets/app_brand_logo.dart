import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

/// Clean, resolution-independent vector brand emblem for VoiceVitals.
/// Renders a teal heart icon with an integrated ECG pulse waveform.
class AppBrandLogo extends StatelessWidget {
  final double size;
  final double iconSize;
  final bool showBackground;

  const AppBrandLogo({
    super.key,
    this.size = 36,
    this.iconSize = 20,
    this.showBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget emblem = CustomPaint(
      size: Size(size, size),
      painter: _VoiceVitalsLogoPainter(
        color: AppColors.primary,
        strokeColor: Colors.white,
      ),
    );

    if (showBackground) {
      return Container(
        width: size * 1.3,
        height: size * 1.3,
        decoration: BoxDecoration(
          color: AppColors.subtleTealSurface,
          shape: BoxShape.circle,
        ),
        child: Center(child: emblem),
      );
    }

    return emblem;
  }
}

class _VoiceVitalsLogoPainter extends CustomPainter {
  final Color color;
  final Color strokeColor;

  _VoiceVitalsLogoPainter({
    required this.color,
    required this.strokeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintHeart = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final width = size.width;
    final height = size.height;

    // Draw stylized heart
    final path = Path();
    path.moveTo(width / 2, height * 0.88);
    path.cubicTo(
      width * 0.08,
      height * 0.58,
      0,
      height * 0.28,
      width * 0.28,
      height * 0.15,
    );
    path.cubicTo(
      width * 0.42,
      height * 0.08,
      width / 2,
      height * 0.24,
      width / 2,
      height * 0.24,
    );
    path.cubicTo(
      width / 2,
      height * 0.24,
      width * 0.58,
      height * 0.08,
      width * 0.72,
      height * 0.15,
    );
    path.cubicTo(
      width,
      height * 0.28,
      width * 0.92,
      height * 0.58,
      width / 2,
      height * 0.88,
    );
    path.close();

    canvas.drawPath(path, paintHeart);

    // Draw ECG pulse line across the center of the heart
    final paintLine = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = (width * 0.07).clamp(1.5, 4.0)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    final ecg = Path();
    final yCenter = height * 0.46;
    ecg.moveTo(width * 0.18, yCenter);
    ecg.lineTo(width * 0.38, yCenter);
    ecg.lineTo(width * 0.44, yCenter - height * 0.2);
    ecg.lineTo(width * 0.52, yCenter + height * 0.22);
    ecg.lineTo(width * 0.59, yCenter - height * 0.1);
    ecg.lineTo(width * 0.64, yCenter);
    ecg.lineTo(width * 0.82, yCenter);

    canvas.drawPath(ecg, paintLine);
  }

  @override
  bool shouldRepaint(covariant _VoiceVitalsLogoPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeColor != strokeColor;
}

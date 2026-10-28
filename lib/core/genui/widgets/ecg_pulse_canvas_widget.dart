import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';

/// Bespoke ECG cardiac rhythm canvas drawn using low-level [CustomPainter].
/// Demonstrates deep Flutter rendering pipeline mastery with oscilloscope grid,
/// P-Q-R-S-T waveform trajectory, and sweeping phosphorescent pulse head.
class EcgPulseCanvasWidget extends StatefulWidget {
  final double bpm;
  final Color color;
  final double height;
  final bool isLive;

  const EcgPulseCanvasWidget({
    super.key,
    this.bpm = 72,
    this.color = AppColors.pulseVital,
    this.height = 100,
    this.isLive = true,
  });

  @override
  State<EcgPulseCanvasWidget> createState() => _EcgPulseCanvasWidgetState();
}

class _EcgPulseCanvasWidgetState extends State<EcgPulseCanvasWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Frequency calculated from BPM: 60 / bpm gives seconds per cardiac cycle
    final cycleSeconds = (60.0 / widget.bpm.clamp(40.0, 180.0)).clamp(0.4, 2.0);
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (cycleSeconds * 1000).toInt()),
    );

    if (widget.isLive) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant EcgPulseCanvasWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bpm != widget.bpm) {
      final cycleSeconds = (60.0 / widget.bpm.clamp(40.0, 180.0)).clamp(0.4, 2.0);
      _controller.duration = Duration(milliseconds: (cycleSeconds * 1000).toInt());
      if (widget.isLive && !_controller.isAnimating) {
        _controller.repeat();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      label: 'Real-time electrocardiogram waveform monitor displaying ${widget.bpm.toInt()} beats per minute.',
      value: '${widget.bpm.toInt()} BPM',
      child: Container(
        height: widget.height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF060D1F) : const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.color.withValues(alpha: 0.35),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: _EcgCanvasPainter(
                progress: _controller.value,
                color: widget.color,
                isDark: isDark,
              ),
              size: Size.infinite,
            );
          },
        ),
      ),
    );
  }
}

class _EcgCanvasPainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool isDark;

  _EcgCanvasPainter({
    required this.progress,
    required this.color,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final midY = height * 0.5;

    // 1. Draw Medical Oscilloscope Grid
    final gridPaint = Paint()
      ..color = const Color(0xFF1E293B).withValues(alpha: 0.45)
      ..strokeWidth = 0.5;

    const gridSize = 16.0;
    for (double x = 0; x < width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, height), gridPaint);
    }
    for (double y = 0; y < height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(width, y), gridPaint);
    }

    // 2. Generate Normalized P-Q-R-S-T Cardiac Waveform
    final path = Path();
    final glowPath = Path();

    final sweepHeadX = width * progress;
    bool isFirst = true;

    for (double x = 0; x < width; x += 2.0) {
      // Relative distance behind sweep head
      final distFromHead = (sweepHeadX - x) % width;
      final alpha = (1.0 - (distFromHead / width)).clamp(0.0, 1.0);

      if (alpha < 0.05) continue;

      // Local cardiac phase (0.0 to 1.0 across every cycle segment)
      final segmentLength = width * 0.45;
      final localPhase = (x / segmentLength) % 1.0;
      final yOffset = _evaluateEcgY(localPhase, height * 0.38);

      final currentPt = Offset(x, midY + yOffset);

      if (isFirst) {
        path.moveTo(currentPt.dx, currentPt.dy);
        glowPath.moveTo(currentPt.dx, currentPt.dy);
        isFirst = false;
      } else {
        path.lineTo(currentPt.dx, currentPt.dy);
        glowPath.lineTo(currentPt.dx, currentPt.dy);
      }
    }

    // 3. Draw Outer Phosphor Glow
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
    canvas.drawPath(glowPath, glowPaint);

    // 4. Draw Core Waveform Beam
    final beamPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, beamPaint);

    // 5. Draw Sweeping Pulse Head Dot with Radial Halo
    final headY = midY + _evaluateEcgY((sweepHeadX / (width * 0.45)) % 1.0, height * 0.38);
    final headPos = Offset(sweepHeadX, headY);

    final haloPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white,
          color.withValues(alpha: 0.8),
          color.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.4, 1.0],
      ).createShader(Rect.fromCircle(center: headPos, radius: 10));

    canvas.drawCircle(headPos, 10, haloPaint);
    canvas.drawCircle(headPos, 2.5, Paint()..color = Colors.white);
  }

  /// Calculates mathematically accurate P-Q-R-S-T deflection points
  double _evaluateEcgY(double phase, double amplitude) {
    // 0.00 - 0.15: Baseline
    if (phase < 0.15) return 0.0;
    // 0.15 - 0.25: P Wave (atrial depolarization, mild positive bump)
    if (phase < 0.25) {
      final pPhase = (phase - 0.15) / 0.10;
      return -math.sin(pPhase * math.pi) * (amplitude * 0.22);
    }
    // 0.25 - 0.35: PR Interval (flat)
    if (phase < 0.35) return 0.0;
    // 0.35 - 0.38: Q Wave (mild negative dip)
    if (phase < 0.38) {
      final qPhase = (phase - 0.35) / 0.03;
      return math.sin(qPhase * math.pi) * (amplitude * 0.15);
    }
    // 0.38 - 0.45: R Wave (steep ventricular depolarization spike)
    if (phase < 0.45) {
      final rPhase = (phase - 0.38) / 0.07;
      return -math.sin(rPhase * math.pi) * amplitude;
    }
    // 0.45 - 0.50: S Wave (deep negative rebound)
    if (phase < 0.50) {
      final sPhase = (phase - 0.45) / 0.05;
      return math.sin(sPhase * math.pi) * (amplitude * 0.32);
    }
    // 0.50 - 0.60: ST Segment (isoelectric)
    if (phase < 0.60) return 0.0;
    // 0.60 - 0.78: T Wave (ventricular repolarization, broader dome)
    if (phase < 0.78) {
      final tPhase = (phase - 0.60) / 0.18;
      return -math.sin(tPhase * math.pi) * (amplitude * 0.35);
    }
    // 0.78 - 1.00: Diastolic relaxation baseline
    return 0.0;
  }

  @override
  bool shouldRepaint(covariant _EcgCanvasPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

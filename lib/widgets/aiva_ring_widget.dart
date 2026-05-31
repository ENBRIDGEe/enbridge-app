import 'dart:math';
import 'package:flutter/material.dart';
import 'package:enbridge/theme/app_theme.dart';

/// Animated AIVA ring widget — replicates the blue gradient concentric
/// circles + sound-wave bars from the AIVA Freelancia hero page SVG logo.
class AIVARingWidget extends StatefulWidget {
  final double size;
  final bool animate;

  const AIVARingWidget({super.key, this.size = 180, this.animate = true});

  @override
  State<AIVARingWidget> createState() => _AIVARingWidgetState();
}

class _AIVARingWidgetState extends State<AIVARingWidget>
    with TickerProviderStateMixin {
  late AnimationController _rotateCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _waveCtrl;

  @override
  void initState() {
    super.initState();
    _rotateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotateCtrl.dispose();
    _pulseCtrl.dispose();
    _waveCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return SizedBox(
      width: s,
      height: s,
      child: AnimatedBuilder(
        animation: Listenable.merge([_rotateCtrl, _pulseCtrl, _waveCtrl]),
        builder: (context, _) {
          return CustomPaint(
            painter: _AIVARingPainter(
              rotateAngle: _rotateCtrl.value * 2 * pi,
              pulseValue: _pulseCtrl.value,
              waveValue: _waveCtrl.value,
            ),
          );
        },
      ),
    );
  }
}

class _AIVARingPainter extends CustomPainter {
  final double rotateAngle;
  final double pulseValue;
  final double waveValue;

  _AIVARingPainter({
    required this.rotateAngle,
    required this.pulseValue,
    required this.waveValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final maxR = size.width / 2;

    // ── Outer gradient ring (rotating dash) ──────────────────────────────
    final gradPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..shader = SweepGradient(
        colors: const [AppColors.aivaGradStart, AppColors.aivaGradEnd, AppColors.aivaGradStart],
        transform: GradientRotation(rotateAngle),
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: maxR * 0.9));

    canvas.drawCircle(Offset(cx, cy), maxR * 0.9, gradPaint);

    // ── Mid ring (static, subtle white) ──────────────────────────────────
    final midPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.white.withValues(alpha: 0.10 + pulseValue * 0.08);

    canvas.drawCircle(Offset(cx, cy), maxR * 0.62, midPaint);

    // ── Inner ring (pulsing glow) ─────────────────────────────────────────
    final innerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = AppColors.aivaBlueMid.withValues(alpha: 0.18 + pulseValue * 0.15);

    canvas.drawCircle(Offset(cx, cy), maxR * 0.36, innerPaint);

    // ── Centre glow ───────────────────────────────────────────────────────
    final glowPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = RadialGradient(
        colors: [
          AppColors.aivaBlue.withValues(alpha: 0.25 + pulseValue * 0.1),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: maxR * 0.28));

    canvas.drawCircle(Offset(cx, cy), maxR * 0.28, glowPaint);

    // ── Sound wave bars (5 bars, AIVA logo motif) ─────────────────────────
    _drawSoundWave(canvas, cx, cy, maxR);
  }

  void _drawSoundWave(Canvas canvas, double cx, double cy, double maxR) {
    // Bar heights match AIVA Freelancia SVG: 40 80 120 60 20 (px at 120px scale)
    final normalizedHeights = [40 / 120.0, 80 / 120.0, 1.0, 60 / 120.0, 20 / 120.0];
    const barCount = 5;
    final barWidth = maxR * 0.085;
    final barGap = maxR * 0.06;
    final maxBarH = maxR * 0.48;
    final totalWidth = barCount * barWidth + (barCount - 1) * barGap;
    final startX = cx - totalWidth / 2;

    // Wave animation offsets — each bar oscillates with a phase offset
    final phaseOffsets = [0.0, 0.3, 0.6, 0.9, 1.2];

    final barPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.aivaGradStart, AppColors.aivaGradEnd],
      ).createShader(Rect.fromLTWH(0, cy - maxBarH, totalWidth, maxBarH * 2));

    for (int i = 0; i < barCount; i++) {
      final phase = phaseOffsets[i];
      final animFactor = 0.7 + 0.3 * sin((waveValue * 2 * pi) + phase * pi);
      final barH = normalizedHeights[i] * maxBarH * animFactor;
      final x = startX + i * (barWidth + barGap);
      final top = cy - barH / 2;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, top, barWidth, barH),
        Radius.circular(barWidth / 2),
      );
      canvas.drawRRect(rect, barPaint);
    }
  }

  @override
  bool shouldRepaint(_AIVARingPainter old) => true;
}

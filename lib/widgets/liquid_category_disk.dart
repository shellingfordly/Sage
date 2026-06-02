import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

Color liquidCategoryShade(Color color, double lightnessDelta) {
  final hsl = HSLColor.fromColor(color);
  return hsl
      .withLightness((hsl.lightness + lightnessDelta).clamp(0.0, 1.0))
      .toColor();
}

class LiquidCategoryDisk extends StatefulWidget {
  const LiquidCategoryDisk({
    super.key,
    required this.amountLabel,
    required this.progress,
    required this.color,
    this.size = 76,
  });

  final String amountLabel;
  final double progress;
  final Color color;
  final double size;

  @override
  State<LiquidCategoryDisk> createState() => _LiquidCategoryDiskState();
}

class _LiquidCategoryDiskState extends State<LiquidCategoryDisk>
    with SingleTickerProviderStateMixin {
  late final AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final progress = widget.progress.clamp(0.0, 1.0);
    final amountOnFill = progress >= 0.52;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _waveController,
        builder: (context, child) {
          return CustomPaint(
            painter: _LiquidDiskPainter(
              progress: progress,
              color: widget.color,
              trackColor: Color.alphaBlend(
                widget.color.withValues(alpha: 0.16),
                colors.surface,
              ),
              wavePhase: _waveController.value * math.pi * 2,
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    widget.amountLabel,
                    style: AppTextStyles.bodyStrong(context).copyWith(
                      color: amountOnFill ? colors.onStrong : widget.color,
                      fontSize: (13 * widget.size / 76).clamp(10.0, 13.0),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LiquidDiskPainter extends CustomPainter {
  const _LiquidDiskPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.wavePhase,
  });

  final double progress;
  final Color color;
  final Color trackColor;
  final double wavePhase;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final circlePath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));

    canvas.drawPath(circlePath, Paint()..color = trackColor);

    if (progress <= 0) {
      return;
    }

    canvas.save();
    canvas.clipPath(circlePath);

    const waveHeight = 2.8;
    final waveLength = size.width / 1.6;
    final fillLevel = size.height * (1 - progress.clamp(0.04, 1.0));
    final waterRect = Rect.fromLTWH(
      0,
      fillLevel - waveHeight * 2,
      size.width,
      size.height - fillLevel + waveHeight * 2,
    );
    final wavePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          liquidCategoryShade(color, -0.08),
          color,
          liquidCategoryShade(color, 0.14),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(waterRect);
    final waterPath = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width, fillLevel);

    for (var x = size.width; x >= 0; x -= 1) {
      final y =
          fillLevel +
          math.sin((x / waveLength * math.pi * 2) + wavePhase) * waveHeight;
      waterPath.lineTo(x, y);
    }
    waterPath.close();
    canvas.drawPath(waterPath, wavePaint);

    final highlightPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          liquidCategoryShade(color, 0.08).withValues(alpha: 0.0),
          liquidCategoryShade(color, 0.2).withValues(alpha: 0.28),
        ],
      ).createShader(waterRect)
      ..style = PaintingStyle.fill;
    final highlightPath = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width, fillLevel + 4);

    for (var x = size.width; x >= 0; x -= 1) {
      final y =
          fillLevel +
          4 +
          math.sin((x / waveLength * math.pi * 2) + wavePhase + math.pi / 3) *
              (waveHeight * 0.55);
      highlightPath.lineTo(x, y);
    }
    highlightPath.close();
    canvas.drawPath(highlightPath, highlightPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LiquidDiskPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.wavePhase != wavePhase;
  }
}

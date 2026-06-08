import 'package:flutter/material.dart';

/// Sage 品牌色：账本主体。
const Color sageLedgerColor = Color(0xFF2F8F83);

/// Sage 品牌色：智慧洞察。
const Color sageInsightColor = Color(0xFFE6A82E);

/// Sage 应用标识：一体字形——日 + 口 + 知笔意。
class SageLogo extends StatelessWidget {
  const SageLogo({super.key, this.size = 80});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: const CustomPaint(
        painter: SageLogoPainter(),
      ),
    );
  }
}

class SageLogoPainter extends CustomPainter {
  const SageLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final stroke = w * 0.058;
    final corner = w * 0.08;

    final bodyStroke = Paint()
      ..color = sageLedgerColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final ri = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.16, h * 0.60, w * 0.68, h * 0.24),
      Radius.circular(corner),
    );
    canvas.drawRRect(ri, bodyStroke);
    canvas.drawLine(
      Offset(w * 0.28, h * 0.72),
      Offset(w * 0.72, h * 0.72),
      bodyStroke,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.30, h * 0.28, w * 0.40, h * 0.26),
        Radius.circular(corner),
      ),
      bodyStroke,
    );

    final insightStroke = Paint()
      ..color = sageInsightColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke * 0.94
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final insight = Path()
      ..moveTo(w * 0.20, h * 0.14)
      ..quadraticBezierTo(w * 0.34, h * 0.30, w * 0.46, h * 0.42)
      ..lineTo(w * 0.72, h * 0.42);
    canvas.drawPath(insight, insightStroke);

    canvas.drawCircle(
      Offset(w * 0.76, h * 0.42),
      stroke * 0.40,
      Paint()
        ..color = sageInsightColor
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant SageLogoPainter oldDelegate) => false;
}

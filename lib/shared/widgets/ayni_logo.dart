import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// AYNI brand mark — hoja-escudo de café con la letra "A" formada por la
/// vena central y dos venas laterales (negative space).
///
/// Espejo en Flutter del componente `AyniMark` de ayni_web
/// (components/brand/ayni-mark.tsx), mismo viewBox 120×140.
class AyniLogo extends StatelessWidget {
  final double size;
  final Color fill;
  final Color veinColor;

  const AyniLogo({
    super.key,
    this.size = 64,
    this.fill = AppColors.primary,
    this.veinColor = AppColors.secondary,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * (140 / 120),
      child: CustomPaint(
        painter: _AyniLogoPainter(fill: fill, veinColor: veinColor),
      ),
    );
  }
}

class _AyniLogoPainter extends CustomPainter {
  final Color fill;
  final Color veinColor;

  _AyniLogoPainter({required this.fill, required this.veinColor});

  static const double _viewWidth = 120;
  static const double _viewHeight = 140;

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / _viewWidth;
    final scaleY = size.height / _viewHeight;
    canvas.save();
    canvas.scale(scaleX, scaleY);

    final shieldPath = Path()
      ..moveTo(60, 6)
      ..cubicTo(92, 6, 112, 30, 112, 70)
      ..lineTo(60, 134)
      ..lineTo(8, 70)
      ..cubicTo(8, 30, 28, 6, 60, 6)
      ..close();

    canvas.drawPath(shieldPath, Paint()..color = fill);

    final veinPaint = Paint()
      ..color = veinColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawLine(const Offset(36, 100), const Offset(60, 38), veinPaint);
    canvas.drawLine(const Offset(84, 100), const Offset(60, 38), veinPaint);
    canvas.drawLine(const Offset(46, 74), const Offset(74, 74), veinPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AyniLogoPainter oldDelegate) {
    return oldDelegate.fill != fill || oldDelegate.veinColor != veinColor;
  }
}

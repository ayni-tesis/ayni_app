import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// AYNI brand mark — hoja de café en forma de corazón con vena central
/// y un rostro calmo (ojos curvos + sonrisa sutil).
///
/// Por defecto dibuja el lockup completo (squircle de fondo + hoja +
/// rostro), tal como el ícono de la app. Pasa [background] en `null`
/// para usarlo "suelto" (solo la hoja con rostro, sin fondo), útil en
/// headers o badges donde el contenedor ya aporta el fondo.
class AyniLogo extends StatelessWidget {
  final double size;
  final Color? background;
  final Color faceColor;
  final Color featureColor;
  final Color veinColor;

  const AyniLogo({
    super.key,
    this.size = 64,
    this.background = AppColors.primary,
    this.faceColor = AppColors.white,
    this.featureColor = AppColors.primary,
    this.veinColor = AppColors.secondary,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _AyniLogoPainter(
          background: background,
          faceColor: faceColor,
          featureColor: featureColor,
          veinColor: veinColor,
        ),
      ),
    );
  }
}

class _AyniLogoPainter extends CustomPainter {
  final Color? background;
  final Color faceColor;
  final Color featureColor;
  final Color veinColor;

  _AyniLogoPainter({
    required this.background,
    required this.faceColor,
    required this.featureColor,
    required this.veinColor,
  });

  static const double _viewSize = 200;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / _viewSize;
    canvas.save();
    canvas.scale(scale, scale);

    if (background != null) {
      final bgPath = Path()
        ..addRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(0, 0, _viewSize, _viewSize),
            const Radius.circular(_viewSize * 0.22),
          ),
        );
      canvas.drawPath(bgPath, Paint()..color = background!);
    }

    // Heart-shaped leaf: two rounded lobes at the top meeting in a
    // notch, tapering to a drip-tip point at the bottom.
    final leafPath = Path()
      ..moveTo(100, 46)
      ..cubicTo(82, 14, 30, 18, 30, 70)
      ..cubicTo(30, 112, 70, 142, 100, 178)
      ..cubicTo(130, 142, 170, 112, 170, 70)
      ..cubicTo(170, 18, 118, 14, 100, 46)
      ..close();
    canvas.drawPath(leafPath, Paint()..color = faceColor);

    // Center vein.
    final veinPaint = Paint()
      ..color = veinColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(100, 56), const Offset(100, 160), veinPaint);

    // Calm crescent eyes + subtle smile.
    final featurePaint = Paint()
      ..color = featureColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;

    final leftEye = Path()
      ..moveTo(70, 102)
      ..quadraticBezierTo(78, 92, 86, 102);
    final rightEye = Path()
      ..moveTo(114, 102)
      ..quadraticBezierTo(122, 92, 130, 102);
    canvas.drawPath(leftEye, featurePaint);
    canvas.drawPath(rightEye, featurePaint);

    final smile = Path()
      ..moveTo(84, 122)
      ..quadraticBezierTo(100, 134, 116, 122);
    canvas.drawPath(smile, featurePaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AyniLogoPainter oldDelegate) {
    return oldDelegate.background != background ||
        oldDelegate.faceColor != faceColor ||
        oldDelegate.featureColor != featureColor ||
        oldDelegate.veinColor != veinColor;
  }
}

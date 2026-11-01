import 'package:flutter/material.dart';

/// Ethiopian Cross / Meskel geometric watermark motif for the net worth hero card.
class MeskelWatermark extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;

  const MeskelWatermark({
    super.key,
    this.size = 180,
    this.color = Colors.white,
    this.opacity = 0.08,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: opacity,
        child: CustomPaint(
          size: Size(size, size),
          painter: _MeskelPainter(color),
        ),
      ),
    );
  }
}

class _MeskelPainter extends CustomPainter {
  final Color color;
  _MeskelPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final scale = size.width / 100.0;
    canvas.save();
    canvas.scale(scale, scale);

    final path = Path()
      // Outer Cross Contour
      ..moveTo(40, 0)
      ..lineTo(60, 0)
      ..lineTo(60, 30)
      ..lineTo(90, 30)
      ..lineTo(90, 40)
      ..lineTo(100, 40)
      ..lineTo(100, 60)
      ..lineTo(90, 60)
      ..lineTo(90, 70)
      ..lineTo(60, 70)
      ..lineTo(60, 100)
      ..lineTo(40, 100)
      ..lineTo(40, 70)
      ..lineTo(10, 70)
      ..lineTo(10, 60)
      ..lineTo(0, 60)
      ..lineTo(0, 40)
      ..lineTo(10, 40)
      ..lineTo(10, 30)
      ..lineTo(40, 30)
      ..close()

      // Inner Cutout Pattern
      ..moveTo(46, 12)
      ..lineTo(54, 12)
      ..lineTo(54, 34)
      ..lineTo(76, 34)
      ..lineTo(76, 42)
      ..lineTo(88, 42)
      ..lineTo(88, 58)
      ..lineTo(76, 58)
      ..lineTo(76, 66)
      ..lineTo(54, 66)
      ..lineTo(54, 88)
      ..lineTo(46, 88)
      ..lineTo(46, 66)
      ..lineTo(24, 66)
      ..lineTo(24, 58)
      ..lineTo(12, 58)
      ..lineTo(12, 42)
      ..lineTo(24, 42)
      ..lineTo(24, 34)
      ..lineTo(46, 34)
      ..close();

    path.fillType = PathFillType.evenOdd;
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MeskelPainter oldDelegate) => color != oldDelegate.color;
}

import 'package:flutter/material.dart';

import '../state.dart';
import '../theme.dart';

/// Fond d'écran clair derrière toute l'app, choisi dans les paramètres.
class BarroBackground extends StatelessWidget {
  final Widget child;

  const BarroBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) => Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(child: CustomPaint(painter: BackgroundPainter(state.background))),
          child,
        ],
      ),
    );
  }
}

class BackgroundPainter extends CustomPainter {
  final BackgroundStyle style;

  BackgroundPainter(this.style);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = BarroColors.bg);
    switch (style) {
      case BackgroundStyle.blanc:
        break;
      case BackgroundStyle.feuillage:
        _leaves(canvas, size);
        break;
      case BackgroundStyle.points:
        _dots(canvas, size);
        break;
    }
  }

  void _dots(Canvas canvas, Size size) {
    final paint = Paint()..color = BarroColors.green.withValues(alpha: 0.08);
    const step = 24.0;
    for (double y = 12; y < size.height; y += step) {
      for (double x = 12; x < size.width; x += step) {
        canvas.drawCircle(Offset(x, y), 1.3, paint);
      }
    }
  }

  void _leaves(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final paint = Paint()..color = BarroColors.green.withValues(alpha: 0.06);
    void leaf(Offset at, double angle, double s) {
      canvas.save();
      canvas.translate(at.dx, at.dy);
      canvas.rotate(angle);
      final path = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(s * 0.5, -s * 0.36, s, 0)
        ..quadraticBezierTo(s * 0.5, s * 0.36, 0, 0)
        ..close();
      canvas.drawPath(path, paint);
      canvas.restore();
    }

    leaf(Offset(w * 0.88, h * 0.04), 2.3, 150);
    leaf(Offset(w * 1.02, h * 0.16), 2.0, 96);
    leaf(Offset(-24, h * 0.88), -0.6, 170);
    leaf(Offset(w * 0.08, h * 1.0), -1.1, 110);
  }

  @override
  bool shouldRepaint(BackgroundPainter oldDelegate) => oldDelegate.style != style;
}

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../state.dart';
import '../theme.dart';

/// Fond d'écran dessiné derrière toute l'app, choisi dans les paramètres.
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
      case BackgroundStyle.savane:
        _savane(canvas, size);
        break;
      case BackgroundStyle.faso:
        _faso(canvas, size);
        break;
      case BackgroundStyle.etoiles:
        _stars(canvas, size);
        break;
      case BackgroundStyle.uni:
        break;
    }
  }

  /// Soleil couchant en haut, collines et herbes en bas.
  void _savane(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final sunCenter = Offset(w * 0.85, h * 0.12);
    canvas.drawCircle(
      sunCenter,
      w * 0.55,
      Paint()
        ..shader = RadialGradient(colors: [
          BarroColors.orange.withValues(alpha: 0.16),
          BarroColors.orange.withValues(alpha: 0.0),
        ]).createShader(Rect.fromCircle(center: sunCenter, radius: w * 0.55)),
    );
    canvas.drawCircle(sunCenter, w * 0.09, Paint()..color = BarroColors.orange.withValues(alpha: 0.18));

    final hill1 = Path()
      ..moveTo(0, h * 0.86)
      ..quadraticBezierTo(w * 0.3, h * 0.78, w * 0.62, h * 0.86)
      ..quadraticBezierTo(w * 0.85, h * 0.92, w, h * 0.84)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(hill1, Paint()..color = BarroColors.green.withValues(alpha: 0.06));
    final hill2 = Path()
      ..moveTo(0, h * 0.93)
      ..quadraticBezierTo(w * 0.45, h * 0.86, w, h * 0.95)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(hill2, Paint()..color = BarroColors.green.withValues(alpha: 0.08));

    final rnd = math.Random(7);
    final dot = Paint()..color = BarroColors.text.withValues(alpha: 0.05);
    for (var i = 0; i < 60; i++) {
      canvas.drawCircle(Offset(rnd.nextDouble() * w, rnd.nextDouble() * h * 0.75), 1 + rnd.nextDouble() * 1.5, dot);
    }
  }

  /// Bandes tissées inspirées du Faso Dan Fani.
  void _faso(Canvas canvas, Size size) {
    final colors = [BarroColors.green, BarroColors.orange, BarroColors.blue, BarroColors.violet];
    const band = 46.0;
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(-math.pi / 9);
    final diag = math.sqrt(size.width * size.width + size.height * size.height);
    var i = 0;
    for (double x = -diag; x < diag; x += band) {
      final c = colors[i % colors.length];
      canvas.drawRect(Rect.fromLTWH(x, -diag, band * 0.45, diag * 2), Paint()..color = c.withValues(alpha: 0.05));
      canvas.drawRect(Rect.fromLTWH(x + band * 0.6, -diag, 2, diag * 2), Paint()..color = c.withValues(alpha: 0.08));
      i++;
    }
    canvas.restore();
  }

  /// Ciel de nuit avec étoiles.
  void _stars(Canvas canvas, Size size) {
    final rnd = math.Random(42);
    for (var i = 0; i < 120; i++) {
      final r = rnd.nextDouble() * 1.6 + 0.4;
      final alpha = 0.08 + rnd.nextDouble() * 0.22;
      canvas.drawCircle(
        Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height),
        r,
        Paint()..color = Colors.white.withValues(alpha: alpha),
      );
    }
    final moon = Offset(size.width * 0.82, size.height * 0.1);
    canvas.drawCircle(moon, 26, Paint()..color = BarroColors.text.withValues(alpha: 0.12));
    canvas.drawCircle(moon.translate(10, -6), 22, Paint()..color = BarroColors.bg);
  }

  @override
  bool shouldRepaint(BackgroundPainter oldDelegate) => oldDelegate.style != style;
}

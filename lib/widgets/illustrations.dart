import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// Ce qui accompagne le poussin selon le module.
enum SceneProp { sun, water, coin }

SceneProp propForModule(int moduleNumber) {
  switch (moduleNumber) {
    case 2:
      return SceneProp.water;
    case 3:
      return SceneProp.coin;
    default:
      return SceneProp.sun;
  }
}

/// Illustration dessinée : un poussin dans son décor, qui respire doucement.
class ChickScene extends StatefulWidget {
  final SceneProp prop;
  final Color sky;
  final double height;

  const ChickScene({super.key, required this.prop, this.sky = const Color(0xFF13233F), this.height = 200});

  @override
  State<ChickScene> createState() => _ChickSceneState();
}

class _ChickSceneState extends State<ChickScene> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => CustomPaint(
            painter: _ChickPainter(prop: widget.prop, sky: widget.sky, t: Curves.easeInOut.transform(_c.value)),
          ),
        ),
      ),
    );
  }
}

class _ChickPainter extends CustomPainter {
  final SceneProp prop;
  final Color sky;
  final double t;

  _ChickPainter({required this.prop, required this.sky, required this.t});

  static const _yellow = Color(0xFFFFD34D);
  static const _yellowDark = Color(0xFFF2B526);
  static const _beak = Color(0xFFFF8A3D);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    canvas.drawRect(Offset.zero & size, Paint()..color = sky);

    // Sol
    final ground = Path()
      ..moveTo(0, h * 0.78)
      ..quadraticBezierTo(w * 0.5, h * 0.70, w, h * 0.80)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(ground, Paint()..color = const Color(0xFF1D5C3A));
    final grass = Paint()
      ..color = BarroColors.green.withValues(alpha: 0.7)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final rnd = math.Random(3);
    for (var i = 0; i < 18; i++) {
      final x = rnd.nextDouble() * w;
      final y = h * 0.82 + rnd.nextDouble() * h * 0.14;
      canvas.drawLine(Offset(x, y), Offset(x - 3, y - 8), grass);
      canvas.drawLine(Offset(x, y), Offset(x + 3, y - 9), grass);
    }

    _drawProp(canvas, size);

    // Poussin
    final cx = w * 0.5;
    final bob = t * 4;
    final bodyR = h * 0.2;
    final bodyC = Offset(cx, h * 0.62 - bob);
    final headR = h * 0.135;
    final headC = Offset(cx + bodyR * 0.35, bodyC.dy - bodyR * 0.95);

    // Ombre
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, h * 0.83), width: bodyR * 2.2, height: h * 0.05),
        Paint()..color = Colors.black.withValues(alpha: 0.25));
    // Pattes
    final leg = Paint()
      ..color = _beak
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (final dx in [-bodyR * 0.3, bodyR * 0.25]) {
      final top = Offset(cx + dx, bodyC.dy + bodyR * 0.85);
      final foot = Offset(cx + dx, h * 0.82);
      canvas.drawLine(top, foot, leg);
      canvas.drawLine(foot, foot.translate(7, 0), leg);
      canvas.drawLine(foot, foot.translate(-5, 2), leg);
    }
    // Corps et tête
    canvas.drawCircle(bodyC, bodyR, Paint()..color = _yellow);
    canvas.drawCircle(headC, headR, Paint()..color = _yellow);
    // Aile qui bat un peu
    canvas.save();
    canvas.translate(bodyC.dx - bodyR * 0.15, bodyC.dy + bodyR * 0.05);
    canvas.rotate(-0.25 - t * 0.2);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: bodyR * 1.0, height: bodyR * 0.6),
        Paint()..color = _yellowDark);
    canvas.restore();
    // Bec
    final beak = Path()
      ..moveTo(headC.dx + headR * 0.85, headC.dy - headR * 0.1)
      ..lineTo(headC.dx + headR * 1.45, headC.dy + headR * 0.1)
      ..lineTo(headC.dx + headR * 0.85, headC.dy + headR * 0.3)
      ..close();
    canvas.drawPath(beak, Paint()..color = _beak);
    // Œil
    final eye = Offset(headC.dx + headR * 0.35, headC.dy - headR * 0.2);
    canvas.drawCircle(eye, headR * 0.18, Paint()..color = BarroColors.ink);
    canvas.drawCircle(eye.translate(-headR * 0.05, -headR * 0.06), headR * 0.06, Paint()..color = Colors.white);
    // Joue
    canvas.drawCircle(Offset(headC.dx + headR * 0.15, headC.dy + headR * 0.35), headR * 0.16,
        Paint()..color = const Color(0xFFFF9F7A).withValues(alpha: 0.6));
    // Petite houppette
    final tuft = Paint()
      ..color = _yellowDark
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final top = Offset(headC.dx - headR * 0.1, headC.dy - headR * 0.95);
    canvas.drawLine(top, top.translate(-4, -9), tuft);
    canvas.drawLine(top, top.translate(4, -10), tuft);
  }

  void _drawProp(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    switch (prop) {
      case SceneProp.sun:
        final c = Offset(w * 0.18, h * 0.24);
        final r = h * 0.1;
        final ray = Paint()
          ..color = BarroColors.orange
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round;
        for (var i = 0; i < 8; i++) {
          final a = i * math.pi / 4 + t * 0.3;
          canvas.drawLine(
            c + Offset(math.cos(a), math.sin(a)) * (r * 1.35),
            c + Offset(math.cos(a), math.sin(a)) * (r * 1.75),
            ray,
          );
        }
        canvas.drawCircle(c, r, Paint()..color = BarroColors.orange);
        // Thermomètre
        final tx = w * 0.82, ty = h * 0.3;
        final tube = RRect.fromRectAndRadius(Rect.fromLTWH(tx - 6, ty, 12, h * 0.34), const Radius.circular(6));
        canvas.drawRRect(tube, Paint()..color = Colors.white.withValues(alpha: 0.85));
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(tx - 3, ty + h * 0.12, 6, h * 0.22), const Radius.circular(3)),
          Paint()..color = const Color(0xFFFF6B6B),
        );
        canvas.drawCircle(Offset(tx, ty + h * 0.36), 10, Paint()..color = const Color(0xFFFF6B6B));
        break;
      case SceneProp.water:
        final c = Offset(w * 0.2, h * 0.46);
        final s = h * 0.17;
        final drop = Path()
          ..moveTo(c.dx, c.dy - s)
          ..quadraticBezierTo(c.dx + s * 0.75, c.dy - s * 0.05, c.dx + s * 0.5, c.dy + s * 0.45)
          ..arcToPoint(Offset(c.dx - s * 0.5, c.dy + s * 0.45), radius: Radius.circular(s * 0.55))
          ..quadraticBezierTo(c.dx - s * 0.75, c.dy - s * 0.05, c.dx, c.dy - s)
          ..close();
        canvas.drawPath(drop, Paint()..color = BarroColors.blue);
        canvas.drawCircle(c.translate(-s * 0.18, s * 0.1), s * 0.1, Paint()..color = Colors.white.withValues(alpha: 0.6));
        // Graines
        final rnd = math.Random(11);
        for (var i = 0; i < 12; i++) {
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(w * 0.7 + rnd.nextDouble() * w * 0.2, h * 0.8 + rnd.nextDouble() * h * 0.08),
              width: 6,
              height: 4,
            ),
            Paint()..color = const Color(0xFFF2C14E),
          );
        }
        break;
      case SceneProp.coin:
        for (var i = 0; i < 3; i++) {
          final c = Offset(w * 0.8, h * 0.72 - i * 9.0);
          canvas.drawOval(Rect.fromCenter(center: c, width: 44, height: 16), Paint()..color = const Color(0xFFE0A21B));
          canvas.drawOval(Rect.fromCenter(center: c.translate(0, -3), width: 44, height: 16),
              Paint()..color = const Color(0xFFFFC94A));
        }
        // Croix de santé
        final hc = Offset(w * 0.2, h * 0.32);
        canvas.drawCircle(hc, h * 0.11, Paint()..color = BarroColors.green);
        final arm = h * 0.06;
        final cross = Paint()..color = Colors.white;
        canvas.drawRRect(
            RRect.fromRectAndRadius(Rect.fromCenter(center: hc, width: arm * 0.8, height: arm * 2.2), const Radius.circular(3)),
            cross);
        canvas.drawRRect(
            RRect.fromRectAndRadius(Rect.fromCenter(center: hc, width: arm * 2.2, height: arm * 0.8), const Radius.circular(3)),
            cross);
        break;
    }
  }

  @override
  bool shouldRepaint(_ChickPainter old) => old.t != t || old.prop != prop || old.sky != sky;
}

/// Pluie de confettis pour la récompense.
class Confetti extends StatefulWidget {
  const Confetti({super.key});

  @override
  State<Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<Confetti> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));
  late final List<_Bit> _bits;

  @override
  void initState() {
    super.initState();
    final rnd = math.Random();
    const colors = [BarroColors.green, BarroColors.blue, BarroColors.orange, BarroColors.violet, BarroColors.pink];
    _bits = List.generate(
      60,
      (i) => _Bit(
        x: rnd.nextDouble(),
        drift: (rnd.nextDouble() - 0.5) * 0.4,
        speed: 0.6 + rnd.nextDouble() * 0.6,
        spin: (rnd.nextDouble() - 0.5) * 12,
        size: 5 + rnd.nextDouble() * 6,
        color: colors[i % colors.length],
        delay: rnd.nextDouble() * 0.3,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!MediaQuery.of(context).disableAnimations && !_c.isAnimating && _c.value == 0) {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(painter: _ConfettiPainter(_bits, _c.value), size: Size.infinite),
      ),
    );
  }
}

class _Bit {
  final double x, drift, speed, spin, size, delay;
  final Color color;

  _Bit({
    required this.x,
    required this.drift,
    required this.speed,
    required this.spin,
    required this.size,
    required this.color,
    required this.delay,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_Bit> bits;
  final double t;

  _ConfettiPainter(this.bits, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    if (t == 0 || t == 1) return;
    for (final b in bits) {
      final double p = ((t - b.delay) / (1 - b.delay)).clamp(0.0, 1.0).toDouble();
      if (p <= 0) continue;
      final x = (b.x + b.drift * p) * size.width;
      final y = -20 + p * b.speed * size.height * 1.1;
      final paint = Paint()..color = b.color.withValues(alpha: 1 - p);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(b.spin * p);
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: b.size, height: b.size * 0.5), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}

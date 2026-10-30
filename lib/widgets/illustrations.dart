import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// Ce qui accompagne la poule selon le module.
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

/// Illustration géométrique : une poule qui respire, cligne des yeux et bat de l'aile.
/// [compact] : version pour les cartes (poule en bas à droite, sans décor).
class HenScene extends StatefulWidget {
  final double height;
  final SceneProp prop;
  final bool compact;

  const HenScene({super.key, required this.height, this.prop = SceneProp.sun, this.compact = false});

  @override
  State<HenScene> createState() => _HenSceneState();
}

class _HenSceneState extends State<HenScene> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 4200));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => CustomPaint(
            painter: _HenPainter(v: _c.value, prop: widget.prop, compact: widget.compact),
          ),
        ),
      ),
    );
  }
}

class _HenPainter extends CustomPainter {
  final double v;
  final SceneProp prop;
  final bool compact;

  _HenPainter({required this.v, required this.prop, required this.compact});

  static Path _poly(List<Offset> pts) {
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final q in pts.skip(1)) {
      path.lineTo(q.dx, q.dy);
    }
    return path..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final wave = math.sin(v * 2 * math.pi);
    final blink = v < 0.035 || (v > 0.52 && v < 0.55);

    if (compact) {
      final s = h * 0.78 / 200;
      final o = Offset(w - 222 * s, h - 194 * s);
      canvas.drawCircle(o + Offset(190 * s, 40 * s), 26 * s * (1 + 0.05 * wave), Paint()..color = BarroColors.sun);
      canvas.drawOval(
        Rect.fromCenter(center: o + Offset(118 * s, 190 * s), width: 144 * s, height: 14 * s),
        Paint()..color = BarroColors.greenMid,
      );
      _hen(canvas, o, s, wave, blink);
      return;
    }

    canvas.drawCircle(Offset(w * 0.84, h * 0.24), h * 0.15 * (1 + 0.04 * wave), Paint()..color = BarroColors.sun);
    final ground = Path()
      ..moveTo(0, h * 0.80)
      ..quadraticBezierTo(w * 0.5, h * 0.68, w, h * 0.80)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(ground, Paint()..color = BarroColors.greenMid);
    _prop(canvas, size, wave);
    final s = h * 0.76 / 200;
    final o = Offset(w * 0.58 - 120 * s, h * 0.86 - 190 * s);
    _hen(canvas, o, s, wave, blink);
  }

  void _hen(Canvas canvas, Offset o, double s, double wave, bool blink) {
    final bob = -wave * 2.5 * s;
    Offset p(double x, double y) => Offset(o.dx + x * s, o.dy + y * s + bob);
    Offset fixed(double x, double y) => Offset(o.dx + x * s, o.dy + y * s);

    final leg = Paint()
      ..color = BarroColors.orange
      ..strokeWidth = 6 * s
      ..strokeCap = StrokeCap.round;
    for (final x in [100.0, 128.0]) {
      canvas.drawLine(p(x, 176), fixed(x, 191), leg);
    }

    canvas.drawPath(_poly([p(62, 112), p(26, 58), p(48, 54), p(80, 98)]), Paint()..color = BarroColors.green);
    canvas.drawCircle(p(115, 122), 58 * s, Paint()..color = Colors.white);
    canvas.drawCircle(p(160, 70), 30 * s, Paint()..color = Colors.white);

    // Aile, qui bouge un peu
    final pivot = p(114, 120);
    canvas.save();
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(math.sin(v * 4 * math.pi) * 0.06);
    canvas.translate(-pivot.dx, -pivot.dy);
    final a = p(78, 120), b = p(150, 120);
    final wing = Path()
      ..moveTo(a.dx, a.dy)
      ..arcToPoint(b, radius: Radius.circular(36 * s), clockwise: false)
      ..close();
    canvas.drawPath(wing, Paint()..color = BarroColors.wing);
    canvas.restore();

    final red = Paint()..color = BarroColors.comb;
    canvas.drawCircle(p(150, 38), 9 * s, red);
    canvas.drawCircle(p(163, 33), 9 * s, red);
    canvas.drawCircle(p(175, 40), 8 * s, red);
    canvas.drawPath(_poly([p(188, 63), p(208, 71), p(188, 79)]), Paint()..color = BarroColors.orange);
    canvas.drawCircle(p(186, 90), 7 * s, red);

    if (blink) {
      canvas.drawLine(
        p(164, 62),
        p(174, 62),
        Paint()
          ..color = BarroColors.ink
          ..strokeWidth = 2.6 * s
          ..strokeCap = StrokeCap.round,
      );
    } else {
      canvas.drawCircle(p(169, 62), 5 * s, Paint()..color = BarroColors.ink);
      canvas.drawCircle(p(170.6, 60.4), 1.6 * s, Paint()..color = Colors.white);
    }
  }

  void _chick(Canvas canvas, Offset o, double cs, double wave) {
    final bob = -math.max(0.0, wave) * 3 * cs;
    Offset p(double x, double y) => Offset(o.dx + x * cs, o.dy + y * cs + bob);
    canvas.drawCircle(p(22, 22), 18 * cs, Paint()..color = BarroColors.chick);
    canvas.drawCircle(p(36, 6), 12 * cs, Paint()..color = BarroColors.chick);
    canvas.drawPath(_poly([p(46, 4), p(56, 8), p(46, 12)]), Paint()..color = BarroColors.orange);
    canvas.drawCircle(p(40, 3), 2.5 * cs, Paint()..color = BarroColors.ink);
  }

  void _prop(Canvas canvas, Size size, double wave) {
    final w = size.width, h = size.height;
    switch (prop) {
      case SceneProp.sun:
        final cs = h / 228;
        _chick(canvas, Offset(w * 0.1, h * 0.79 - 40 * cs), cs, wave);
        break;
      case SceneProp.water:
        final c = Offset(w * 0.18, h * 0.42 + wave * 3);
        final d = h * 0.13;
        final drop = Path()
          ..moveTo(c.dx, c.dy - d)
          ..quadraticBezierTo(c.dx + d * 0.75, c.dy - d * 0.05, c.dx + d * 0.5, c.dy + d * 0.45)
          ..arcToPoint(Offset(c.dx - d * 0.5, c.dy + d * 0.45), radius: Radius.circular(d * 0.55))
          ..quadraticBezierTo(c.dx - d * 0.75, c.dy - d * 0.05, c.dx, c.dy - d)
          ..close();
        canvas.drawPath(drop, Paint()..color = const Color(0xFF60A5FA));
        canvas.drawCircle(c.translate(-d * 0.18, d * 0.1), d * 0.1, Paint()..color = Colors.white.withValues(alpha: 0.7));
        final rnd = math.Random(11);
        for (var i = 0; i < 12; i++) {
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(w * 0.12 + rnd.nextDouble() * w * 0.24, h * 0.84 + rnd.nextDouble() * h * 0.08),
              width: 7,
              height: 4,
            ),
            Paint()..color = const Color(0xFFE0A21B),
          );
        }
        break;
      case SceneProp.coin:
        for (var i = 0; i < 3; i++) {
          final c = Offset(w * 0.16, h * 0.84 - i * 9.0);
          canvas.drawOval(Rect.fromCenter(center: c, width: 46, height: 16), Paint()..color = const Color(0xFFE0A21B));
          canvas.drawOval(
              Rect.fromCenter(center: c.translate(0, -3), width: 46, height: 16), Paint()..color = const Color(0xFFFFC94A));
        }
        final hc = Offset(w * 0.16, h * 0.34);
        final r = h * 0.1 * (1 + 0.04 * wave);
        canvas.drawCircle(hc, r, Paint()..color = BarroColors.green);
        final arm = r * 0.55;
        final cross = Paint()..color = Colors.white;
        canvas.drawRRect(
            RRect.fromRectAndRadius(Rect.fromCenter(center: hc, width: arm * 0.7, height: arm * 2), const Radius.circular(3)),
            cross);
        canvas.drawRRect(
            RRect.fromRectAndRadius(Rect.fromCenter(center: hc, width: arm * 2, height: arm * 0.7), const Radius.circular(3)),
            cross);
        break;
    }
  }

  @override
  bool shouldRepaint(_HenPainter old) => old.v != v || old.prop != prop || old.compact != compact;
}

/// Bouton « lecture » entouré d'une onde qui pulse.
class PulsePlay extends StatefulWidget {
  final Color color;
  final Color iconColor;

  const PulsePlay({super.key, this.color = Colors.white, this.iconColor = BarroColors.greenDeep});

  @override
  State<PulsePlay> createState() => _PulsePlayState();
}

class _PulsePlayState extends State<PulsePlay> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 112,
      height: 112,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 72 + 40 * t,
                height: 72 + 40 * t,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withValues(alpha: 0.28 * (1 - t)),
                ),
              ),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color),
                child: Icon(Icons.play_arrow_rounded, size: 40, color: widget.iconColor),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Pluie de confettis pour la récompense.
class Confetti extends StatefulWidget {
  const Confetti({super.key});

  @override
  State<Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<Confetti> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));
  late final List<_Bit> _bits;

  @override
  void initState() {
    super.initState();
    final rnd = math.Random();
    const colors = [
      BarroColors.green,
      BarroColors.orange,
      BarroColors.blue,
      BarroColors.violet,
      BarroColors.comb,
      Color(0xFFFACC15),
    ];
    _bits = List.generate(
      70,
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

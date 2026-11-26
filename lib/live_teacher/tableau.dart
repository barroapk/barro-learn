import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'moteur.dart';

/// Un élément du tableau. Son état visible est entièrement calculé à partir du temps audio.
class ElementTableau {
  ElementTableau({
    required this.id,
    required this.genre,
    required this.zone,
    required this.tApparition,
    this.texte,
    this.style = 'note',
    this.url,
    this.animer = false,
  });
  final String id;
  final String genre;
  final String zone;
  final String style;
  final String? texte;
  final String? url;
  final int tApparition;
  final bool animer;
  int? tSouligne;
  int? tCercle;
  int? tSurligne;
  int? tEfface;
}

double prog(int t, int? t0, int dureeMs) => t0 == null ? 0 : ((t - t0) / dureeMs).clamp(0.0, 1.0).toDouble();

List<String> _cibles(dynamic c) => c is List ? [for (final x in c) x as String] : [c as String];

Map<String, ElementTableau> etatTableau(ScenePrete s, int t) {
  final els = <String, ElementTableau>{};
  for (final e in s.evenements) {
    if (e.tMs > t) break;
    final c = e.cmd;
    final id = c['id'] as String?;
    switch (c['type']) {
      case 'board.write':
        els[id!] = ElementTableau(
            id: id, genre: 'texte', zone: (c['zone'] ?? 'droite') as String, tApparition: e.tMs,
            texte: c['texte'] as String?, style: (c['style'] ?? 'note') as String,
            animer: c['animation'] == 'ecriture_manuscrite');
      case 'media.show':
        els[id!] = ElementTableau(
            id: id, genre: 'image', zone: (c['zone'] ?? 'gauche') as String, tApparition: e.tMs,
            url: s.images[c['media']]);
      case 'board.draw':
        els[id!] = ElementTableau(id: id, genre: 'fleche', zone: (c['zone'] ?? 'bas') as String, tApparition: e.tMs);
      case 'board.underline':
        for (final x in _cibles(c['cible'])) {
          els[x]?.tSouligne ??= e.tMs;
        }
      case 'board.circle':
        for (final x in _cibles(c['cible'])) {
          els[x]?.tCercle ??= e.tMs;
        }
      case 'board.highlight':
        for (final x in _cibles(c['cible'])) {
          els[x]?.tSurligne = e.tMs;
        }
      case 'board.erase':
        for (final x in _cibles(c['cible'])) {
          els[x]?.tEfface ??= e.tMs;
        }
    }
  }
  return els;
}

TextStyle _style(String s) {
  const f = GoogleFonts.patrickHand;
  switch (s) {
    case 'titre':
      return f(fontSize: 28, color: const Color(0xFF0D3B66), fontWeight: FontWeight.bold);
    case 'notion':
      return f(fontSize: 24, color: const Color(0xFFD1495B), fontWeight: FontWeight.bold);
    case 'explication':
      return f(fontSize: 20, color: const Color(0xFF1B6CA8));
    case 'repere':
      return f(fontSize: 19, color: const Color(0xFF222222), fontWeight: FontWeight.bold);
    case 'conclusion':
      return f(fontSize: 20, color: const Color(0xFF2E7D32), fontWeight: FontWeight.bold);
    case 'question':
      return f(fontSize: 22, color: const Color(0xFF6A1B9A), fontWeight: FontWeight.bold);
    default:
      return f(fontSize: 17, color: const Color(0xFF555555), fontStyle: FontStyle.italic);
  }
}

class LiveBoard extends StatelessWidget {
  const LiveBoard({super.key, required this.elements, required this.t});
  final Map<String, ElementTableau> elements;
  final int t;

  Iterable<ElementTableau> _zone(String z) => elements.values.where((e) => e.zone == z);

  @override
  Widget build(BuildContext context) {
    final images = _zone('gauche').where((e) => e.genre == 'image').toList();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDDE3DF)),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Wrap(children: [for (final e in _zone('titre')) ElementVue(e: e, t: t)])),
        const SizedBox(height: 12),
        if (images.isNotEmpty)
          SizedBox(
            height: 150,
            child: Row(children: [
              for (final e in images)
                Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: ImageVue(e: e, t: t))),
            ]),
          ),
        const SizedBox(height: 12),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [for (final e in _zone('droite')) ElementVue(e: e, t: t)],
            ),
          ),
        ),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          runSpacing: 4,
          children: [for (final e in _zone('bas')) ElementVue(e: e, t: t)],
        ),
      ]),
    );
  }
}

class ImageVue extends StatelessWidget {
  const ImageVue({super.key, required this.e, required this.t});
  final ElementTableau e;
  final int t;

  @override
  Widget build(BuildContext context) {
    final o = prog(t, e.tApparition, 600) * (1 - prog(t, e.tEfface, 500));
    return Opacity(
      opacity: o,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: e.url == null
            ? Container(color: const Color(0xFFEEEEEE), child: const Center(child: Icon(Icons.image_not_supported)))
            : Image.network(e.url!, fit: BoxFit.cover, width: double.infinity,
                errorBuilder: (_, __, ___) => Container(color: const Color(0xFFEEEEEE))),
      ),
    );
  }
}

class ElementVue extends StatelessWidget {
  const ElementVue({super.key, required this.e, required this.t});
  final ElementTableau e;
  final int t;

  @override
  Widget build(BuildContext context) {
    final dureeEcriture = math.max(600, math.min(2200, (e.texte?.length ?? 4) * 70));
    final apparition = e.animer ? prog(t, e.tApparition, dureeEcriture) : prog(t, e.tApparition, 300);
    final visible = 1 - prog(t, e.tEfface, 500);
    if (visible <= 0) return const SizedBox.shrink();
    Widget w;
    if (e.genre == 'fleche') {
      w = CustomPaint(size: const Size(48, 24), painter: _Fleche(apparition));
    } else {
      final txt = Text(e.texte ?? '', style: _style(e.style));
      w = e.animer
          ? ClipRect(child: Align(alignment: Alignment.centerLeft, widthFactor: apparition, child: txt))
          : Opacity(opacity: apparition, child: txt);
      w = Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFEB3B).withValues(alpha: 0.55 * prog(t, e.tSurligne, 400)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: CustomPaint(
          foregroundPainter: _Marques(prog(t, e.tSouligne, 500), prog(t, e.tCercle, 700)),
          child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), child: w),
        ),
      );
    }
    return Opacity(opacity: visible, child: Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: w));
  }
}

class _Marques extends CustomPainter {
  _Marques(this.souligne, this.cercle);
  final double souligne;
  final double cercle;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFFE53935)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    if (souligne > 0) {
      canvas.drawLine(Offset(4, size.height - 2), Offset(4 + (size.width - 8) * souligne, size.height - 2), p);
    }
    if (cercle > 0) {
      canvas.drawArc(Rect.fromLTWH(-2, -2, size.width + 4, size.height + 4), -math.pi / 2, 2 * math.pi * cercle, false, p);
    }
  }

  @override
  bool shouldRepaint(_Marques old) => old.souligne != souligne || old.cercle != cercle;
}

class _Fleche extends CustomPainter {
  _Fleche(this.p);
  final double p;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF222222)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final y = size.height / 2;
    final x = 4 + (size.width - 8) * p;
    canvas.drawLine(Offset(4, y), Offset(x, y), paint);
    if (p >= 1) {
      canvas.drawLine(Offset(x, y), Offset(x - 8, y - 7), paint);
      canvas.drawLine(Offset(x, y), Offset(x - 8, y + 7), paint);
    }
  }

  @override
  bool shouldRepaint(_Fleche old) => old.p != p;
}

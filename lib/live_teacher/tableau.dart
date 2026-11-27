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
    this.couleur = 'noir',
  });
  final String couleur;
  String marque = 'rouge';
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
            animer: c['animation'] == 'ecriture_manuscrite',
            couleur: (c['couleur'] ?? couleurParDefaut[c['style'] ?? 'note'] ?? 'noir') as String);
      case 'media.show':
        els[id!] = ElementTableau(
            id: id, genre: 'image', zone: (c['zone'] ?? 'gauche') as String, tApparition: e.tMs,
            url: s.images[c['media']]);
      case 'board.draw':
        els[id!] = ElementTableau(
            id: id, genre: 'fleche', zone: (c['zone'] ?? 'bas') as String, tApparition: e.tMs,
            couleur: (c['couleur'] ?? 'noir') as String);
      case 'board.underline':
        for (final x in _cibles(c['cible'])) {
          els[x]?.tSouligne ??= e.tMs;
          if (c['couleur'] != null) els[x]?.marque = c['couleur'] as String;
        }
      case 'board.circle':
        for (final x in _cibles(c['cible'])) {
          els[x]?.tCercle ??= e.tMs;
          if (c['couleur'] != null) els[x]?.marque = c['couleur'] as String;
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

const couleurParDefaut = {
  'titre': 'bleu_fonce', 'notion': 'rouge', 'explication': 'bleu', 'repere': 'noir',
  'conclusion': 'vert', 'question': 'violet', 'note': 'gris',
};
const _encres = {
  'bleu_fonce': Color(0xFF0D3B66), 'rouge': Color(0xFFD1495B), 'bleu': Color(0xFF1B6CA8),
  'noir': Color(0xFF222222), 'vert': Color(0xFF2E7D32), 'violet': Color(0xFF6A1B9A), 'gris': Color(0xFF555555),
};
Color encre(String c) => _encres[c] ?? const Color(0xFF222222);

/// Le feutre dans la main a la couleur de l'encre.
String stylo(String c) {
  if (c == 'bleu') return _mainStylo;
  if (c == 'gris' || !_encres.containsKey(c)) return 'assets/live_teacher/stylo_noir.webp';
  return 'assets/live_teacher/stylo_$c.webp';
}

TextStyle styleTableau(String s, [String? couleur]) {
  const f = GoogleFonts.patrickHand;
  final c = encre(couleur ?? couleurParDefaut[s] ?? 'noir');
  switch (s) {
    case 'titre':
      return f(fontSize: 26, color: c, fontWeight: FontWeight.bold);
    case 'notion':
      return f(fontSize: 22, color: c, fontWeight: FontWeight.bold);
    case 'explication':
      return f(fontSize: 20, color: c);
    case 'repere':
      return f(fontSize: 19, color: c, fontWeight: FontWeight.bold);
    case 'conclusion':
      return f(fontSize: 20, color: c, fontWeight: FontWeight.bold);
    case 'question':
      return f(fontSize: 22, color: c, fontWeight: FontWeight.bold);
    default:
      return f(fontSize: 17, color: c, fontStyle: FontStyle.italic);
  }
}

// Les mains du professeur (Faso Dan Fani). Pointe du feutre et patin de la brosse mesurés au pixel.
const _mainStylo = 'assets/live_teacher/main_stylo.webp';
const _mainBrosse = 'assets/live_teacher/main_brosse.webp';
const _largeurStylo = 210.0;
const _pointeStylo = Offset(1, 41.5);
const _largeurBrosse = 230.0;
const _patinBrosse = Offset(175, 34.5);
const _hauteurImage = 110.0;
const _bandes = 5;

const dureeImage = 1600;
const dureeFleche = 600;
const dureeSouligne = 500;
const dureeCercle = 700;
const dureeEfface = 700;
int dureeEcriture(String? t) => math.max(500, math.min(2600, (t?.length ?? 4) * 85));

/// Mesure du texte : position de chaque lettre, pour que la pointe avance lettre par lettre.
class _Mesure {
  _Mesure(String texte, TextStyle style)
      : tp = TextPainter(
          text: TextSpan(text: texte, style: style),
          textDirection: TextDirection.ltr,
          maxLines: 1,
          textScaler: TextScaler.noScaling,
        )..layout() {
    bornes = [for (var i = 0; i <= texte.length; i++) tp.getOffsetForCaret(TextPosition(offset: i), Rect.zero).dx];
  }
  final TextPainter tp;
  late final List<double> bornes;
  double get largeur => tp.width;
  double get hauteur => tp.height;
  Size get boite => Size(tp.width + 16, tp.height + 8);

  /// Pointe du feutre dans la boîte : avance lettre par lettre et monte/descend dans chaque lettre.
  Offset pointe(double p) {
    final n = bornes.length - 1;
    if (n <= 0) return const Offset(8, 4);
    final pos = p * n;
    final k = pos.floor().clamp(0, n - 1);
    final f = pos - k;
    final x = bornes[k] + (bornes[k + 1] - bornes[k]) * f;
    final y = hauteur * (0.3 + 0.4 * (0.5 - 0.5 * math.cos(2 * math.pi * f)));
    return Offset(8 + x, 4 + y);
  }
}

class _Main {
  _Main(this.id, this.point, this.brosse, this.encre);
  final String id;
  final Offset point;
  final bool brosse;
  final String encre;
}

Offset _pointeImage(double p, Size s) {
  final pos = p * _bandes;
  final k = pos.floor().clamp(0, _bandes - 1);
  final f = pos - k;
  final h = s.height / _bandes;
  final x = k.isEven ? s.width * f : s.width * (1 - f);
  return Offset(x, h * (k + 0.5));
}

class LiveBoard extends StatefulWidget {
  const LiveBoard({super.key, required this.elements, required this.t});
  final Map<String, ElementTableau> elements;
  final int t;

  @override
  State<LiveBoard> createState() => _LiveBoardState();
}

class _LiveBoardState extends State<LiveBoard> {
  final _liens = <String, LayerLink>{};
  LayerLink _lien(String id) => _liens.putIfAbsent(id, LayerLink.new);

  Iterable<ElementTableau> _zone(String z) => widget.elements.values.where((e) => e.zone == z);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final t = widget.t;
      final images = _zone('gauche').where((e) => e.genre == 'image').toList();
      final interieur = c.maxWidth - 24 - 32;
      final tailleImage = Size(images.isEmpty ? 0 : interieur / images.length - 8, _hauteurImage);
      final mesures = <String, _Mesure>{
        for (final e in widget.elements.values)
          if (e.genre == 'texte') e.id: _Mesure(e.texte ?? '', styleTableau(e.style, e.couleur)),
      };
      final main = _mainActive(t, mesures, tailleImage);
      return Stack(clipBehavior: Clip.none, children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFDDE3DF)),
            boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Wrap(children: [for (final e in _zone('titre')) _vue(e, mesures, t)])),
            const SizedBox(height: 12),
            if (images.isNotEmpty)
              SizedBox(
                height: _hauteurImage,
                child: Row(children: [
                  for (final e in images)
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: _image(e, t, tailleImage)),
                ]),
              ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [for (final e in _zone('droite')) _vue(e, mesures, t)],
                ),
              ),
            ),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              runSpacing: 4,
              children: [for (final e in _zone('bas')) _vue(e, mesures, t)],
            ),
          ]),
        ),
        if (main != null)
          Positioned(
            left: 0,
            top: 0,
            child: CompositedTransformFollower(
              link: _lien(main.id),
              showWhenUnlinked: false,
              offset: main.point - (main.brosse ? _patinBrosse : _pointeStylo),
              child: IgnorePointer(
                child: Image.asset(
                  main.brosse ? _mainBrosse : stylo(main.encre),
                  width: main.brosse ? _largeurBrosse : _largeurStylo,
                  gaplessPlayback: true,
                ),
              ),
            ),
          ),
      ]);
    });
  }

  /// Le geste en cours le plus récent décide où se trouve la main et quel feutre elle tient.
  _Main? _mainActive(int t, Map<String, _Mesure> m, Size tailleImage) {
    _Main? meilleur;
    var debut = -1;
    void proposer(String id, int t0, Offset p, bool brosse, String couleur) {
      if (t0 >= debut) {
        debut = t0;
        meilleur = _Main(id, p, brosse, couleur);
      }
    }

    for (final e in widget.elements.values) {
      final ef = prog(t, e.tEfface, dureeEfface);
      if (ef > 0 && ef < 1) {
        final b = e.genre == 'texte' ? m[e.id]!.boite : (e.genre == 'image' ? tailleImage : const Size(48, 24));
        proposer(e.id, e.tEfface!, Offset(b.width * (0.5 + 0.45 * math.sin(ef * math.pi * 5)), b.height * ef), true, 'noir');
        continue;
      }
      if (e.genre == 'texte') {
        final me = m[e.id]!;
        if (e.animer) {
          final p = prog(t, e.tApparition, dureeEcriture(e.texte));
          if (p > 0 && p < 1) proposer(e.id, e.tApparition, me.pointe(p), false, e.couleur);
        }
        final b = me.boite;
        final u = prog(t, e.tSouligne, dureeSouligne);
        if (u > 0 && u < 1) proposer(e.id, e.tSouligne!, Offset(4 + (b.width - 8) * u, b.height - 2), false, e.marque);
        final c = prog(t, e.tCercle, dureeCercle);
        if (c > 0 && c < 1) {
          final a = -math.pi / 2 + 2 * math.pi * c;
          proposer(e.id, e.tCercle!,
              Offset(b.width / 2 + (b.width / 2 + 2) * math.cos(a), b.height / 2 + (b.height / 2 + 2) * math.sin(a)),
              false, e.marque);
        }
      } else if (e.genre == 'image') {
        final p = prog(t, e.tApparition, dureeImage);
        if (p > 0 && p < 1) proposer(e.id, e.tApparition, _pointeImage(p, tailleImage), false, 'noir');
      } else if (e.genre == 'fleche') {
        final p = prog(t, e.tApparition, dureeFleche);
        if (p > 0 && p < 1) proposer(e.id, e.tApparition, Offset(4 + 40 * p, 12), false, e.couleur);
      }
    }
    return meilleur;
  }

  Widget _image(ElementTableau e, int t, Size s) {
    final p = prog(t, e.tApparition, dureeImage);
    final visible = 1 - prog(t, e.tEfface, dureeEfface);
    return CompositedTransformTarget(
      link: _lien(e.id),
      child: SizedBox(
        width: s.width,
        height: s.height,
        child: Opacity(
          opacity: visible,
          child: ClipPath(
            clipper: _ClipBandes(p),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: e.url == null
                  ? Container(color: const Color(0xFFEEEEEE))
                  : Image.network(e.url!, fit: BoxFit.contain, gaplessPlayback: true,
                      errorBuilder: (_, __, ___) => Container(color: const Color(0xFFEEEEEE))),
            ),
          ),
        ),
      ),
    );
  }

  Widget _vue(ElementTableau e, Map<String, _Mesure> m, int t) {
    final visible = 1 - prog(t, e.tEfface, dureeEfface);
    if (visible <= 0) return const SizedBox.shrink();
    Widget boite;
    if (e.genre == 'fleche') {
      boite = CustomPaint(size: const Size(48, 24), painter: _Fleche(prog(t, e.tApparition, dureeFleche), encre(e.couleur)));
    } else {
      final me = m[e.id]!;
      final p = e.animer ? prog(t, e.tApparition, dureeEcriture(e.texte)) : 1.0;
      final opacite = e.animer ? 1.0 : prog(t, e.tApparition, 300);
      final revele = p >= 1 ? me.largeur + 6 : me.pointe(p).dx - 6;
      final texte = SizedBox(
        width: me.largeur,
        height: me.hauteur,
        child: ClipRect(
          clipper: _ClipGauche(revele),
          child: Text(e.texte ?? '', style: styleTableau(e.style, e.couleur), maxLines: 1, softWrap: false,
              textScaler: TextScaler.noScaling),
        ),
      );
      boite = Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFEB3B).withValues(alpha: 0.55 * prog(t, e.tSurligne, 400)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: CustomPaint(
          foregroundPainter: _Marques(prog(t, e.tSouligne, dureeSouligne), prog(t, e.tCercle, dureeCercle), encre(e.marque)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Opacity(opacity: opacite, child: texte),
          ),
        ),
      );
    }
    return Opacity(
      opacity: visible,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: CompositedTransformTarget(link: _lien(e.id), child: boite),
        ),
      ),
    );
  }
}

class _ClipGauche extends CustomClipper<Rect> {
  _ClipGauche(this.largeur);
  final double largeur;

  @override
  Rect getClip(Size size) => Rect.fromLTWH(-4, -12, largeur.clamp(0.0, size.width + 12).toDouble() + 4, size.height + 24);

  @override
  bool shouldReclip(_ClipGauche old) => old.largeur != largeur;
}

class _ClipBandes extends CustomClipper<Path> {
  _ClipBandes(this.p);
  final double p;

  @override
  Path getClip(Size s) {
    final path = Path();
    final h = s.height / _bandes;
    final pos = p * _bandes;
    final k = pos.floor();
    for (var i = 0; i < _bandes; i++) {
      if (i < k) {
        path.addRect(Rect.fromLTWH(0, i * h, s.width, h + 0.5));
      } else if (i == k) {
        final w = s.width * (pos - k);
        path.addRect(i.isEven ? Rect.fromLTWH(0, i * h, w, h + 0.5) : Rect.fromLTWH(s.width - w, i * h, w, h + 0.5));
      }
    }
    return path;
  }

  @override
  bool shouldReclip(_ClipBandes old) => old.p != p;
}

class _Marques extends CustomPainter {
  _Marques(this.souligne, this.cercle, this.couleur);
  final double souligne;
  final double cercle;
  final Color couleur;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = couleur
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
  _Fleche(this.p, this.couleur);
  final double p;
  final Color couleur;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = couleur
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

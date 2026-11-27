import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'moteur.dart';
import 'tableau.dart';

const quizAsset = 'assets/live_teacher/poulet-chair-scene-01-quiz.json';

class _Question {
  _Question(this.enonceId, this.enonce, this.choix, this.bonne, this.explications, this.pourquoi, this.retenir,
      this.refutations);
  final String enonceId;
  final String enonce;
  final List<String> choix;
  final String bonne;
  final List<String> explications;
  final String pourquoi;
  final List<String> retenir;
  final Map<String, String> refutations;
}

enum _Mode { questions, resultat, revue, explication }

/// Quiz façon examen : l'élève répond à tout, reçoit sa note, puis la correction carte par carte.
/// Sur chaque carte, « Besoin d'explication » ouvre un tableau où le professeur explique en dessinant.
class QuizVue extends StatefulWidget {
  const QuizVue({super.key, required this.voix, required this.onFin});
  final String voix;
  final VoidCallback onFin;

  @override
  State<QuizVue> createState() => _QuizVueState();
}

class _QuizVueState extends State<QuizVue> with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final _player = AudioPlayer();
  final _hasard = math.Random();
  final _audio = <String, String>{};
  final _durees = <String, int>{};
  final _textes = <String, String>{};
  late final Ticker _ticker = createTicker((_) => _tick());
  Map _quiz = {};
  List<_Question> _questions = [];
  List<String?> _reponses = [];
  List<String> _felicitationsRevue = [];
  List<String> _retenirRevue = [];
  List<String> _recents = [];
  _Mode _mode = _Mode.questions;
  int _i = 0;
  int _jeton = 0;
  bool _parle = false;
  bool _pret = false;
  String? _erreur;
  ScenePrete? _sceneExp;
  String? _expActuelle;
  int _tExp = 0;
  bool _expFinie = false;

  int get _score => [
        for (var k = 0; k < _questions.length; k++)
          if (_reponses[k] == _questions[k].bonne) 1
      ].length;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _player.playerStateStream.listen((s) {
      final parle = s.playing && s.processingState != ProcessingState.completed;
      if (mounted && parle != _parle) setState(() => _parle = parle);
    });
    _charger();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _jeton++;
    _ticker.dispose();
    _player.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState etat) {
    if (etat != AppLifecycleState.resumed && _player.playing) {
      _player.pause();
      if (mounted) setState(() {});
    }
  }

  Future<void> _charger() async {
    try {
      final d = jsonDecode(await rootBundle.loadString(quizAsset)) as Map;
      for (final s in d['segments'] as List) {
        _textes[s['id'] as String] = s['texte'] as String;
      }
      var cat = await lireJsonWeb(catalogueVoix) as List;
      final attendus = (d['segments'] as List).length;
      bool complet(List c) =>
          c.where((e) => e['scene'] == d['scene'] && e['voix'] == widget.voix && e['actif'] == true).length >= attendus;
      if (!complet(cat)) cat = await lireJsonFrais(catalogueVoix) as List;
      for (final c in cat) {
        if (c['scene'] == d['scene'] && c['voix'] == widget.voix && c['actif'] == true) {
          _audio[c['segment'] as String] = c['audio'] as String;
          _durees[c['segment'] as String] = (c['duree_ms'] as num).toInt();
        }
      }
      final prefs = await SharedPreferences.getInstance();
      _recents = prefs.getStringList('quiz:recents') ?? [];
      _quiz = d['quiz'] as Map;
      _nouveauQuiz();
    } catch (e) {
      if (mounted) setState(() => _erreur = 'Quiz indisponible : $e');
    }
  }

  void _nouveauQuiz() {
    final qs = List<Map>.from(_quiz['questions'] as List)..shuffle(_hasard);
    final n = math.min(qs.length, (_quiz['questions_par_quiz'] ?? 3) as int);
    setState(() {
      _questions = [for (final q in qs.take(n)) _construire(q)];
      _reponses = List<String?>.filled(n, null);
      _mode = _Mode.questions;
      _i = 0;
      _pret = true;
    });
    _jouer([_tirer(_quiz['intro']), _questions[0].enonceId]);
  }

  _Question _construire(Map q) {
    final enonces = List<String>.from(q['enonces'] as List);
    final textes = List<String>.from(q['textes_enonces'] as List);
    final k = _hasard.nextInt(enonces.length);
    final choix = [q['bonne'] as String, ...List<String>.from(q['fausses'] as List)]..shuffle(_hasard);
    return _Question(
        enonces[k],
        textes[k],
        choix,
        q['bonne'] as String,
        List<String>.from(q['explications'] as List),
        (q['pourquoi'] ?? '') as String,
        List<String>.from((q['retenir'] ?? []) as List),
        Map<String, String>.from((q['refutations'] ?? {}) as Map));
  }

  /// Tire une phrase au hasard en évitant les 20 dernières entendues.
  String _tirer(dynamic liste, {String? sauf}) {
    final ids = List<String>.from(liste as List);
    var libres = ids.where((x) => !_recents.contains(x) && x != sauf).toList();
    if (libres.isEmpty) libres = ids.where((x) => x != sauf).toList();
    final pool = libres.isEmpty ? ids : libres;
    final choix = pool[_hasard.nextInt(pool.length)];
    _recents = [..._recents.where((x) => x != choix), choix];
    if (_recents.length > 20) _recents = _recents.sublist(_recents.length - 20);
    SharedPreferences.getInstance().then((p) => p.setStringList('quiz:recents', _recents));
    return choix;
  }

  /// Joue une suite de phrases. Chaque nouvel appel arrête proprement le précédent.
  /// Renvoie vrai si la lecture est allée jusqu'au bout.
  Future<bool> _jouer(List<String> ids) async {
    final jeton = ++_jeton;
    final urls = [for (final id in ids) if (_audio[id] != null) _audio[id]!];
    if (urls.isEmpty) return false;
    try {
      await _player.stop();
      if (jeton != _jeton) return false;
      await _player.setAudioSource(
          ConcatenatingAudioSource(children: [for (final u in urls) AudioSource.uri(Uri.parse(u))]));
      if (jeton != _jeton) return false;
      _player.play();
      await _player.processingStateStream
          .firstWhere((s) => s == ProcessingState.completed)
          .timeout(const Duration(seconds: 120));
      return jeton == _jeton;
    } catch (_) {
      return false;
    }
  }

  // ---------- 1. Les questions (sans correction immédiate) ----------

  Future<void> _repondre(String r) async {
    if (_reponses[_i] != null) return;
    final index = _i;
    setState(() => _reponses[_i] = r);
    await Future.delayed(const Duration(milliseconds: 650));
    if (!mounted || _mode != _Mode.questions || _i != index) return;
    if (_i + 1 < _questions.length) {
      setState(() => _i++);
      _jouer([_questions[_i].enonceId]);
    } else {
      _afficherResultat();
    }
  }

  void _afficherResultat() {
    final n = _questions.length;
    _felicitationsRevue = [for (var k = 0; k < n; k++) _tirer(_quiz['felicitations'])];
    _retenirRevue = [
      for (final q in _questions) q.retenir.isEmpty ? '' : q.retenir[_hasard.nextInt(q.retenir.length)]
    ];
    setState(() => _mode = _Mode.resultat);
    final s = _score;
    final groupe = s == n ? 'fin_parfait' : (s * 2 >= n ? 'fin_moyen' : 'fin_faible');
    _jouer([_tirer(_quiz[groupe] ?? _quiz['fin'])]);
  }

  // ---------- 2. La correction, carte par carte ----------

  void _ouvrirRevue(int k) {
    setState(() {
      _mode = _Mode.revue;
      _i = k;
    });
    final juste = _reponses[k] == _questions[k].bonne;
    _jouer([juste ? _felicitationsRevue[k] : _tirer(_quiz['erreurs'])]);
  }

  void _naviguer(int sens) {
    final k = _i + sens;
    if (k < 0) return;
    if (k >= _questions.length) {
      _jeton++;
      _player.stop();
      setState(() => _mode = _Mode.resultat);
      return;
    }
    _ouvrirRevue(k);
  }

  // ---------- 3. Le professeur explique au tableau ----------

  Future<void> _expliquer({bool autrement = false}) async {
    final q = _questions[_i];
    final choisi = _reponses[_i];
    final juste = choisi == q.bonne;
    final refut = (juste || autrement || choisi == null) ? null : q.refutations[choisi];
    final x = _tirer(q.explications, sauf: _expActuelle);
    final k = q.explications.indexOf(x);
    final retenir = k >= 0 && k < q.retenir.length ? q.retenir[k] : q.pourquoi;
    setState(() {
      _mode = _Mode.explication;
      _sceneExp = _construireScene(q, juste ? null : choisi, refut, x, retenir);
      _expActuelle = x;
      _tExp = 0;
      _expFinie = false;
    });
    if (!_ticker.isActive) _ticker.start();
    final complet = await _jouer([if (refut != null) refut, x]);
    if (mounted && _mode == _Mode.explication && _expActuelle == x) {
      setState(() => _expFinie = true);
      if (!complet) _tExp = 1 << 30;
    }
  }

  /// Le tableau « caricature » l'explication : l'erreur s'écrit puis s'efface,
  /// la bonne réponse s'écrit en vert, l'essentiel s'écrit en rouge puis se souligne.
  ScenePrete _construireScene(_Question q, String? faux, String? refut, String x, String retenir) {
    final dr = refut == null ? 0 : (_durees[refut] ?? 3000);
    final dx = _durees[x] ?? 9000;
    final cmds = <Map<String, dynamic>>[
      {'type': 'board.write', 'id': 'titre', 'zone': 'titre', 'texte': 'Pourquoi ?', 'style': 'titre',
        'animation': 'ecriture_manuscrite', '_t': 150},
      if (refut != null && faux != null) ...[
        {'type': 'board.write', 'id': 'faux', 'zone': 'droite', 'texte': 'Pas : $faux', 'style': 'note',
          'animation': 'ecriture_manuscrite', '_t': 900},
        {'type': 'board.erase', 'cible': 'faux', '_t': math.max(2600, dr - 200)},
      ],
      {'type': 'board.write', 'id': 'reponse', 'zone': 'droite', 'texte': q.bonne, 'style': 'conclusion',
        'animation': 'ecriture_manuscrite', '_t': dr + 500},
      {'type': 'board.write', 'id': 'retenir', 'zone': 'bas', 'texte': retenir, 'style': 'notion',
        'animation': 'ecriture_manuscrite', '_t': dr + (dx * 0.5).round()},
      {'type': 'board.underline', 'cible': 'retenir', '_t': dr + (dx * 0.88).round()},
    ];
    cmds.sort((a, b) => (a['_t'] as int).compareTo(b['_t'] as int));
    final ev = <Evenement>[];
    for (var k = 0; k < cmds.length; k++) {
      cmds[k]['_suivant'] = k + 1 < cmds.length ? cmds[k + 1]['_t'] : (cmds[k]['_t'] as int) + 5000;
      ev.add(Evenement(cmds[k]['_t'] as int, k, cmds[k]));
    }
    final segs = <SegmentPret>[];
    var debut = 0;
    for (final id in [if (refut != null) refut, x]) {
      final d = _durees[id] ?? 5000;
      segs.add(SegmentPret(id, _audio[id] ?? '', debut, d));
      debut += d;
    }
    return ScenePrete('Explication', segs, ev, const <String, String>{});
  }

  void _tick() {
    final s = _sceneExp;
    if (_mode != _Mode.explication || s == null || _expFinie) return;
    final idx = (_player.currentIndex ?? 0).clamp(0, s.segments.length - 1);
    final t = s.segments[idx].debutMs + _player.position.inMilliseconds;
    if (t != _tExp) setState(() => _tExp = t);
  }

  void _fermerExplication() {
    _jeton++;
    _player.stop();
    setState(() {
      _mode = _Mode.revue;
      _expActuelle = null;
    });
  }

  // ---------- Affichage ----------

  @override
  Widget build(BuildContext context) {
    Widget contenu;
    if (_erreur != null) {
      contenu = Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_erreur!, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: widget.onFin, child: const Text('Continuer')),
        ]),
      );
    } else if (!_pret) {
      contenu = const Center(child: CircularProgressIndicator());
    } else {
      contenu = switch (_mode) {
        _Mode.questions => _vueQuestion(),
        _Mode.resultat => _vueResultat(),
        _Mode.revue => _vueRevue(),
        _Mode.explication => _vueExplication(),
      };
    }
    if (_mode == _Mode.explication && _erreur == null && _pret) return contenu;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDDE3DF)),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: contenu,
    );
  }

  Widget _pastille(String texte, Color fond, Color couleur) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: fond, borderRadius: BorderRadius.circular(20)),
        child: Text(texte, style: TextStyle(color: couleur, fontWeight: FontWeight.bold)),
      );

  Widget _barres({required bool correction}) {
    return Row(children: [
      for (var k = 0; k < _questions.length; k++)
        Expanded(
          child: Container(
            height: 5,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: correction
                  ? (_reponses[k] == _questions[k].bonne ? const Color(0xFF2E7D32) : const Color(0xFFD1495B))
                      .withValues(alpha: k == _i ? 1 : 0.35)
                  : (_reponses[k] != null || k < _i ? const Color(0xFF1B6CA8) : Colors.black12),
            ),
          ),
        ),
    ]);
  }

  Widget _enonce(_Question q) => Text(q.enonce,
      style: GoogleFonts.patrickHand(fontSize: 26, color: const Color(0xFF0D3B66), fontWeight: FontWeight.bold));

  Widget _choix(String texte, int k, {Color fond = const Color(0xFFF5F7F6), Color bord = const Color(0xFFDDE3DF),
      Color pastille = const Color(0xFF1B6CA8), IconData? icone, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: fond,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration:
                BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: bord, width: 1.5)),
            child: Row(children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: pastille,
                child: Text(String.fromCharCode(65 + k),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(texte, style: const TextStyle(fontSize: 16))),
              if (icone != null) Icon(icone, color: bord),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _vueQuestion() {
    final q = _questions[_i];
    final choisi = _reponses[_i];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        _pastille('Mini-quiz', const Color(0xFFE8F5E9), const Color(0xFF2E7D32)),
        const SizedBox(width: 10),
        AnimatedOpacity(
          opacity: _parle ? 1 : 0,
          duration: const Duration(milliseconds: 250),
          child: const Icon(Icons.graphic_eq, color: Color(0xFF1B6CA8)),
        ),
        const Spacer(),
        Text('${_i + 1} / ${_questions.length}', style: const TextStyle(color: Colors.black54)),
      ]),
      const SizedBox(height: 10),
      _barres(correction: false),
      const SizedBox(height: 14),
      Expanded(
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _enonce(q),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _jouer([q.enonceId]),
                icon: const Icon(Icons.replay, size: 18),
                label: const Text('Réécouter la question'),
              ),
            ),
            const SizedBox(height: 6),
            for (var k = 0; k < q.choix.length; k++)
              q.choix[k] == choisi
                  ? _choix(q.choix[k], k,
                      fond: const Color(0xFFE3F0FB), bord: const Color(0xFF1B6CA8), icone: Icons.radio_button_checked)
                  : _choix(q.choix[k], k,
                      pastille: choisi == null ? const Color(0xFF1B6CA8) : const Color(0xFFB0BEC5),
                      onTap: choisi == null ? () => _repondre(q.choix[k]) : null),
          ]),
        ),
      ),
    ]);
  }

  Widget _vueResultat() {
    final n = _questions.length;
    final s = _score;
    final (icone, message) = s == n
        ? (Icons.emoji_events, 'Parfait, tout est juste !')
        : s * 2 >= n
            ? (Icons.star_rounded, 'Bien joué ! Regardons les petites erreurs.')
            : (Icons.menu_book, "Ce n'est pas grave, on revoit ça ensemble.");
    return Center(
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icone, size: 76, color: const Color(0xFFF9A825)),
          const SizedBox(height: 12),
          Text('$s / $n', style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 26),
          FilledButton.icon(
            onPressed: () => _ouvrirRevue(0),
            icon: const Icon(Icons.fact_check),
            label: const Text('Voir la correction'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(onPressed: _nouveauQuiz, icon: const Icon(Icons.refresh), label: const Text('Refaire le quiz')),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () {
              _jeton++;
              _player.stop();
              widget.onFin();
            },
            child: const Text('Terminer'),
          ),
        ]),
      ),
    );
  }

  Widget _vueRevue() {
    final q = _questions[_i];
    final choisi = _reponses[_i];
    final juste = choisi == q.bonne;
    return LayoutBuilder(builder: (context, c) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (d) => _naviguer(d.localPosition.dx < c.maxWidth * 0.3 ? -1 : 1),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            _pastille('Correction', const Color(0xFFE3F0FB), const Color(0xFF1B6CA8)),
            const Spacer(),
            Text('${_i + 1} / ${_questions.length}', style: const TextStyle(color: Colors.black54)),
          ]),
          const SizedBox(height: 10),
          _barres(correction: true),
          const SizedBox(height: 14),
          Expanded(
            child: SingleChildScrollView(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                _enonce(q),
                const SizedBox(height: 12),
                for (var k = 0; k < q.choix.length; k++)
                  q.choix[k] == q.bonne
                      ? _choix(q.choix[k], k,
                          fond: const Color(0xFFE8F5E9), bord: const Color(0xFF2E7D32),
                          pastille: const Color(0xFF2E7D32), icone: Icons.check_circle)
                      : q.choix[k] == choisi
                          ? _choix(q.choix[k], k,
                              fond: const Color(0xFFFFEBEE), bord: const Color(0xFFD1495B),
                              pastille: const Color(0xFFD1495B), icone: Icons.cancel)
                          : _choix(q.choix[k], k, pastille: const Color(0xFFB0BEC5)),
                const SizedBox(height: 6),
                juste ? _carteBonne(q) : _carteMauvaise(q, choisi),
              ]),
            ),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: _expliquer,
            icon: const Icon(Icons.school),
            label: const Text("Besoin d'explication"),
          ),
          const SizedBox(height: 6),
          const Text('Touche à droite pour continuer, à gauche pour revenir',
              textAlign: TextAlign.center, style: TextStyle(color: Colors.black45, fontSize: 12)),
        ]),
      );
    });
  }

  Widget _carte({required Color bord, required Color fond, required List<Widget> enfants}) {
    return TweenAnimationBuilder<double>(
      key: ValueKey('carte-$_i'),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutBack,
      builder: (context, v, child) =>
          Opacity(opacity: v.clamp(0.0, 1.0).toDouble(), child: Transform.scale(scale: 0.92 + 0.08 * v, child: child)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: fond,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: bord, width: 1.5),
          boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 14, offset: Offset(0, 5))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: enfants),
      ),
    );
  }

  Widget _carteBonne(_Question q) {
    final f = _textes[_felicitationsRevue[_i]];
    return _carte(bord: const Color(0xFF2E7D32), fond: const Color(0xFFF1F8F2), enfants: [
      const Row(children: [
        Icon(Icons.check_circle, color: Color(0xFF2E7D32)),
        SizedBox(width: 8),
        Text('Bonne réponse !', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
      ]),
      if (f != null) ...[
        const SizedBox(height: 8),
        Text(f, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF2E7D32))),
      ],
      if (q.pourquoi.isNotEmpty) ...[
        const SizedBox(height: 12),
        const Text('Pourquoi ?', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(q.pourquoi, style: const TextStyle(fontSize: 16, height: 1.35)),
      ],
    ]);
  }

  Widget _carteMauvaise(_Question q, String? choisi) {
    final retenir = _retenirRevue[_i];
    return _carte(bord: const Color(0xFFD1495B), fond: Colors.white, enfants: [
      const Row(children: [
        Icon(Icons.cancel, color: Color(0xFFD1495B)),
        SizedBox(width: 8),
        Text('Mauvaise réponse', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFD1495B))),
      ]),
      const SizedBox(height: 10),
      Text('Ta réponse : ${choisi ?? 'aucune'}', style: const TextStyle(color: Colors.black54)),
      const SizedBox(height: 8),
      const Text('La bonne réponse :', style: TextStyle(color: Colors.black54)),
      Text(q.bonne,
          style: GoogleFonts.patrickHand(fontSize: 25, color: const Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
      if (q.pourquoi.isNotEmpty) ...[
        const SizedBox(height: 10),
        const Text('Pourquoi ?', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(q.pourquoi, style: const TextStyle(fontSize: 16, height: 1.35)),
      ],
      if (retenir.isNotEmpty) ...[
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            const Icon(Icons.lightbulb, color: Color(0xFFF9A825)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(retenir, style: GoogleFonts.patrickHand(fontSize: 21, color: const Color(0xFF0D3B66))),
            ),
          ]),
        ),
      ],
    ]);
  }

  Widget _vueExplication() {
    final s = _sceneExp!;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (_expFinie) return;
        _player.playing ? _player.pause() : _player.play();
        setState(() {});
      },
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            const Icon(Icons.school, color: Color(0xFF1B6CA8)),
            const SizedBox(width: 8),
            const Expanded(
              child: Text("Le professeur t'explique", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            IconButton(onPressed: _fermerExplication, icon: const Icon(Icons.close)),
          ]),
        ),
        Expanded(child: LiveBoard(elements: etatTableau(s, _tExp + 400), t: _tExp)),
        const SizedBox(height: 12),
        if (_expFinie)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Text('Tu as compris ?',
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                      onPressed: () => _expliquer(autrement: true), child: const Text('Explique autrement')),
                ),
                const SizedBox(width: 8),
                Expanded(child: FilledButton(onPressed: _fermerExplication, child: const Text("Oui, j'ai compris"))),
              ]),
            ]),
          )
        else
          Text(_player.playing ? 'Touche le tableau pour mettre en pause' : 'En pause — touche pour reprendre',
              textAlign: TextAlign.center, style: const TextStyle(color: Colors.black45)),
        const SizedBox(height: 8),
      ]),
    );
  }
}

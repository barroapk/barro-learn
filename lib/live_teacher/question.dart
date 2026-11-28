import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';

import 'moteur.dart';
import 'tableau.dart';

const questionsAsset = 'assets/live_teacher/poulet-chair-scene-01-questions.json';

/// L'élève interrompt le cours et pose une question préparée.
/// Le professeur répond sur un tableau séparé, demande « Tu as compris ? », puis le cours reprend.
class QuestionEleve extends StatefulWidget {
  const QuestionEleve({super.key, required this.voix, required this.segmentsVus});
  final String voix;
  final List<String> segmentsVus;

  @override
  State<QuestionEleve> createState() => _QuestionEleveState();
}

class _QuestionEleveState extends State<QuestionEleve> with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final _player = AudioPlayer();
  final _hasard = math.Random();
  final _audio = <String, String>{};
  final _durees = <String, int>{};
  late final Ticker _ticker = createTicker((_) => _tick());
  Map _banque = {};
  List<Map> _questions = [];
  Map? _choisie;
  int _variante = -1;
  ScenePrete? _scene;
  int _t = 0;
  bool _finie = false;
  bool _pret = false;
  String? _erreur;
  int _jeton = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
      final d = jsonDecode(await rootBundle.loadString(questionsAsset)) as Map;
      final attendus = (d['segments'] as List).length;
      bool complet(List c) =>
          c.where((e) => e['scene'] == d['scene'] && e['voix'] == widget.voix && e['actif'] == true).length >= attendus;
      var cat = await lireJsonWeb(catalogueVoix) as List;
      if (!complet(cat)) cat = await lireJsonFrais(catalogueVoix) as List;
      for (final c in cat) {
        if (c['scene'] == d['scene'] && c['voix'] == widget.voix && c['actif'] == true) {
          _audio[c['segment'] as String] = c['audio'] as String;
          _durees[c['segment'] as String] = (c['duree_ms'] as num).toInt();
        }
      }
      _banque = d;
      _questions = [
        for (final q in d['questions'] as List)
          if (widget.segmentsVus.contains(q['a_partir_de'])) q as Map
      ];
      if (mounted) setState(() => _pret = true);
    } catch (e) {
      if (mounted) setState(() => _erreur = 'Questions indisponibles : $e');
    }
  }

  String _tirer(dynamic liste) {
    final ids = List<String>.from(liste as List);
    return ids[_hasard.nextInt(ids.length)];
  }

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

  Future<void> _repondre(Map q, {bool autrement = false}) async {
    final reponses = List<Map>.from(q['reponses'] as List);
    final possibles = [for (var k = 0; k < reponses.length; k++) if (k != _variante || reponses.length == 1) k];
    final k = possibles[_hasard.nextInt(possibles.length)];
    final r = reponses[k];
    final intro = autrement ? null : _tirer(_banque['intro']);
    final di = intro == null ? 0 : (_durees[intro] ?? 1500);
    final dv = _durees[r['id']] ?? 9000;
    final cmds = <Map<String, dynamic>>[
      {'type': 'board.write', 'id': 'titre', 'zone': 'titre', 'texte': q['titre'], 'style': 'titre',
        'animation': 'ecriture_manuscrite', '_t': 150},
      if (r['figure'] != null)
        {'type': 'board.figure', 'id': 'figure', 'zone': 'centre', 'figure': r['figure'], '_t': di + 700},
      {'type': 'board.write', 'id': 'retenir', 'zone': 'bas', 'texte': r['retenir'], 'style': 'notion',
        'animation': 'ecriture_manuscrite', '_t': di + (dv * 0.62).round()},
      {'type': 'board.underline', 'cible': 'retenir', '_t': di + (dv * 0.88).round()},
    ];
    cmds.sort((a, b) => (a['_t'] as int).compareTo(b['_t'] as int));
    final ev = <Evenement>[];
    for (var i = 0; i < cmds.length; i++) {
      cmds[i]['_suivant'] = i + 1 < cmds.length ? cmds[i + 1]['_t'] : (cmds[i]['_t'] as int) + 5000;
      ev.add(Evenement(cmds[i]['_t'] as int, i, cmds[i]));
    }
    final segs = <SegmentPret>[];
    var debut = 0;
    for (final id in [if (intro != null) intro, r['id'] as String]) {
      final d = _durees[id] ?? 5000;
      segs.add(SegmentPret(id, _audio[id] ?? '', debut, d));
      debut += d;
    }
    setState(() {
      _choisie = q;
      _variante = k;
      _scene = ScenePrete(q['titre'] as String, segs, ev, const <String, String>{});
      _t = 0;
      _finie = false;
    });
    if (!_ticker.isActive) _ticker.start();
    final complet = await _jouer([if (intro != null) intro, r['id'] as String]);
    if (mounted && _choisie == q && _variante == k) {
      setState(() {
        _finie = true;
        if (!complet) _t = 1 << 30;
      });
    }
  }

  void _tick() {
    final s = _scene;
    if (s == null || _finie) return;
    final idx = (_player.currentIndex ?? 0).clamp(0, s.segments.length - 1);
    final t = s.segments[idx].debutMs + _player.position.inMilliseconds;
    if (t != _t) setState(() => _t = t);
  }

  Future<void> _reprendreCours() async {
    await _jouer([_tirer(_banque['outro'])]);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    Widget corps;
    if (_erreur != null) {
      corps = Center(child: Text(_erreur!, textAlign: TextAlign.center));
    } else if (!_pret) {
      corps = const Center(child: CircularProgressIndicator());
    } else if (_choisie == null) {
      corps = _liste();
    } else {
      corps = _tableau();
    }
    return Scaffold(backgroundColor: const Color(0xFFF3F6F4), body: SafeArea(child: corps));
  }

  Widget _liste() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          const Icon(Icons.help_outline, color: Color(0xFF1B6CA8), size: 28),
          const SizedBox(width: 10),
          const Expanded(child: Text('Ta question', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
          IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close)),
        ]),
        const SizedBox(height: 4),
        const Text('Choisis une question sur ce que tu viens d\'apprendre.', style: TextStyle(color: Colors.black54)),
        const SizedBox(height: 18),
        Expanded(
          child: ListView(children: [
            if (_questions.isEmpty)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text('Avance encore un peu dans le cours : les questions arrivent avec les notions.'),
              ),
            for (final q in _questions)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _repondre(q),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFDDE3DF)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.chat_bubble_outline, color: Color(0xFF1B6CA8)),
                        const SizedBox(width: 12),
                        Expanded(child: Text(q['texte'] as String, style: const TextStyle(fontSize: 16))),
                        const Icon(Icons.chevron_right, color: Colors.black38),
                      ]),
                    ),
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF1F0),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(children: [
                Icon(Icons.edit_note, color: Colors.black38),
                SizedBox(width: 12),
                Expanded(
                  child: Text('Écrire ma propre question — bientôt disponible',
                      style: TextStyle(color: Colors.black45, fontSize: 15)),
                ),
              ]),
            ),
          ]),
        ),
        TextButton.icon(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.play_arrow),
          label: const Text('Retour au cours'),
        ),
      ]),
    );
  }

  Widget _tableau() {
    final s = _scene!;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (_finie) return;
        _player.playing ? _player.pause() : _player.play();
        setState(() {});
      },
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
          child: Row(children: [
            const Icon(Icons.school, color: Color(0xFF1B6CA8)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(_choisie!['texte'] as String,
                  style: GoogleFonts.patrickHand(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF0D3B66))),
            ),
            IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close)),
          ]),
        ),
        Expanded(child: LiveBoard(elements: etatTableau(s, _t + 400), t: _t)),
        const SizedBox(height: 12),
        if (_finie)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Text('Tu as compris ?',
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _repondre(_choisie!, autrement: true),
                    child: const Text('Explique autrement'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: FilledButton(onPressed: _reprendreCours, child: const Text('Oui, reprendre le cours'))),
              ]),
            ]),
          )
        else
          Text(_player.playing ? 'Touche le tableau pour mettre en pause' : 'En pause — touche pour reprendre',
              textAlign: TextAlign.center, style: const TextStyle(color: Colors.black45)),
        const SizedBox(height: 10),
      ]),
    );
  }
}

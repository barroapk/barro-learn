import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'moteur.dart';

const quizAsset = 'assets/live_teacher/poulet-chair-scene-01-quiz.json';

class _Question {
  _Question(this.enonceId, this.enonce, this.choix, this.bonne, this.explications);
  final String enonceId;
  final String enonce;
  final List<String> choix;
  final String bonne;
  final List<String> explications;
}

/// Mini-quiz de fin de scène : questions et réponses au hasard, félicitations variées,
/// explications différentes du cours, sans répéter ce que l'élève vient d'entendre.
/// Le déroulement ne dépend jamais du son : il continue même si un audio échoue.
class QuizVue extends StatefulWidget {
  const QuizVue({super.key, required this.voix, required this.onFin});
  final String voix;
  final VoidCallback onFin;

  @override
  State<QuizVue> createState() => _QuizVueState();
}

class _QuizVueState extends State<QuizVue> with WidgetsBindingObserver {
  final _player = AudioPlayer();
  final _hasard = math.Random();
  final _audio = <String, String>{};
  final _textes = <String, String>{};
  Map _quiz = {};
  List<_Question> _questions = [];
  List<String> _recents = [];
  int _i = 0;
  int _score = 0;
  int _jeton = 0;
  String? _choisi;
  String? _retour;
  String? _explication;
  bool _parle = false;
  bool _pret = false;
  bool _termine = false;
  String? _erreur;

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
    _player.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState etat) {
    if (etat != AppLifecycleState.resumed && _player.playing) _player.pause();
  }

  Future<void> _charger() async {
    try {
      final d = jsonDecode(await rootBundle.loadString(quizAsset)) as Map;
      for (final s in d['segments'] as List) {
        _textes[s['id'] as String] = s['texte'] as String;
      }
      var cat = await lireJsonWeb('$cdnVoix/catalogue.json') as List;
      if (!cat.any((c) => c['scene'] == d['scene'] && c['voix'] == widget.voix)) {
        cat = await lireJsonFrais('$cdnVoix/catalogue.json') as List;
      }
      for (final c in cat) {
        if (c['scene'] == d['scene'] && c['voix'] == widget.voix && c['actif'] == true) {
          _audio[c['segment'] as String] = c['audio'] as String;
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
      _i = 0;
      _score = 0;
      _choisi = null;
      _retour = null;
      _explication = null;
      _termine = false;
      _pret = true;
    });
    _jouer([_tirer(_quiz['intro']), _questions[0].enonceId]);
  }

  _Question _construire(Map q) {
    final enonces = List<String>.from(q['enonces'] as List);
    final textes = List<String>.from(q['textes_enonces'] as List);
    final k = _hasard.nextInt(enonces.length);
    final choix = [q['bonne'] as String, ...List<String>.from(q['fausses'] as List)]..shuffle(_hasard);
    return _Question(enonces[k], textes[k], choix, q['bonne'] as String, List<String>.from(q['explications'] as List));
  }

  /// Tire une phrase au hasard en évitant les 20 dernières entendues.
  String _tirer(dynamic liste) {
    final ids = List<String>.from(liste as List);
    final libres = ids.where((x) => !_recents.contains(x)).toList();
    final pool = libres.isEmpty ? ids : libres;
    final choix = pool[_hasard.nextInt(pool.length)];
    _recents = [..._recents.where((x) => x != choix), choix];
    if (_recents.length > 20) _recents = _recents.sublist(_recents.length - 20);
    SharedPreferences.getInstance().then((p) => p.setStringList('quiz:recents', _recents));
    return choix;
  }

  /// Joue une suite de phrases. Chaque nouvel appel arrête proprement le précédent.
  Future<void> _jouer(List<String> ids) async {
    final jeton = ++_jeton;
    final urls = [for (final id in ids) if (_audio[id] != null) _audio[id]!];
    if (urls.isEmpty) return;
    try {
      await _player.stop();
      if (jeton != _jeton) return;
      await _player.setAudioSource(
          ConcatenatingAudioSource(children: [for (final u in urls) AudioSource.uri(Uri.parse(u))]));
      if (jeton != _jeton) return;
      _player.play();
      await _player.processingStateStream
          .firstWhere((s) => s == ProcessingState.completed)
          .timeout(const Duration(seconds: 40));
    } catch (_) {}
  }

  Future<void> _choisir(String r) async {
    if (_choisi != null) return;
    final q = _questions[_i];
    final index = _i;
    if (r == q.bonne) {
      _score++;
      final f = _tirer(_quiz['felicitations']);
      setState(() {
        _choisi = r;
        _retour = _textes[f];
      });
      final debut = DateTime.now();
      await _jouer([f]);
      final reste = 1400 - DateTime.now().difference(debut).inMilliseconds;
      await Future.delayed(Duration(milliseconds: math.max(500, reste)));
      if (mounted && _i == index && _choisi == r) _suivante();
    } else {
      final e = _tirer(_quiz['erreurs']);
      final x = _tirer(q.explications);
      setState(() {
        _choisi = r;
        _retour = _textes[e];
        _explication = _textes[x];
      });
      await _jouer([e, x]);
    }
  }

  void _suivante() {
    if (_i + 1 >= _questions.length) {
      setState(() => _termine = true);
      _jouer([_tirer(_quiz['fin'])]);
      return;
    }
    setState(() {
      _i++;
      _choisi = null;
      _retour = null;
      _explication = null;
    });
    _jouer([_questions[_i].enonceId]);
  }

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
      contenu = _termine ? _resultat() : _questionVue();
    }
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

  Widget _entete() {
    return Column(children: [
      Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(20)),
          child: const Text('Mini-quiz', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
        ),
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
      Row(children: [
        for (var k = 0; k < _questions.length; k++)
          Expanded(
            child: Container(
              height: 5,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: k < _i || (k == _i && _choisi != null) ? const Color(0xFF2E7D32) : Colors.black12,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
      ]),
    ]);
  }

  Widget _questionVue() {
    final q = _questions[_i];
    final juste = _choisi != null && _choisi == q.bonne;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _entete(),
      const SizedBox(height: 14),
      Expanded(
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(q.enonce,
                style: GoogleFonts.patrickHand(fontSize: 26, color: const Color(0xFF0D3B66), fontWeight: FontWeight.bold)),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _jouer([q.enonceId]),
                icon: const Icon(Icons.replay, size: 18),
                label: const Text('Réécouter la question'),
              ),
            ),
            const SizedBox(height: 6),
            for (var k = 0; k < q.choix.length; k++) _choixVue(q, k),
            if (juste && _retour != null) _bandeau(_retour!, const Color(0xFFE8F5E9), const Color(0xFF2E7D32), Icons.celebration),
            if (!juste && _explication != null)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFFE082)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Row(children: [
                    Icon(Icons.lightbulb, color: Color(0xFFF9A825)),
                    SizedBox(width: 6),
                    Text('Explication', style: TextStyle(fontWeight: FontWeight.bold)),
                  ]),
                  if (_retour != null) ...[
                    const SizedBox(height: 6),
                    Text(_retour!, style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.black54)),
                  ],
                  const SizedBox(height: 6),
                  Text(_explication!, style: const TextStyle(fontSize: 16, height: 1.35)),
                ]),
              ),
          ]),
        ),
      ),
      if (_choisi != null)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: FilledButton(
            onPressed: _suivante,
            child: Text(_i + 1 >= _questions.length
                ? 'Voir mon résultat'
                : (juste ? 'Question suivante' : "J'ai compris, question suivante")),
          ),
        ),
    ]);
  }

  Widget _bandeau(String texte, Color fond, Color couleur, IconData icone) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: fond, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Icon(icone, color: couleur),
        const SizedBox(width: 10),
        Expanded(child: Text(texte, style: TextStyle(fontSize: 16, color: couleur, fontWeight: FontWeight.w600))),
      ]),
    );
  }

  Widget _choixVue(_Question q, int k) {
    final r = q.choix[k];
    var fond = const Color(0xFFF5F7F6);
    var bord = const Color(0xFFDDE3DF);
    IconData? icone;
    if (_choisi != null) {
      if (r == q.bonne) {
        fond = const Color(0xFFE8F5E9);
        bord = const Color(0xFF2E7D32);
        icone = Icons.check_circle;
      } else if (r == _choisi) {
        fond = const Color(0xFFFFEBEE);
        bord = const Color(0xFFD1495B);
        icone = Icons.cancel;
      }
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: fond,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _choisi == null ? () => _choisir(r) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: bord, width: 1.5),
            ),
            child: Row(children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: _choisi == null ? const Color(0xFF1B6CA8) : bord,
                child: Text(String.fromCharCode(65 + k),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(r, style: const TextStyle(fontSize: 16))),
              if (icone != null) Icon(icone, color: bord),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _resultat() {
    final parfait = _score == _questions.length;
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(parfait ? Icons.emoji_events : Icons.star_rounded, size: 76, color: const Color(0xFFF9A825)),
      const SizedBox(height: 12),
      Text('$_score / ${_questions.length}', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
      const SizedBox(height: 6),
      Text(parfait ? 'Parfait, tout est juste !' : 'Bien joué, continue comme ça !',
          style: const TextStyle(fontSize: 16)),
      const SizedBox(height: 24),
      FilledButton(
        onPressed: () {
          _jeton++;
          _player.stop();
          widget.onFin();
        },
        child: const Text('Terminer'),
      ),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        onPressed: _nouveauQuiz,
        icon: const Icon(Icons.refresh),
        label: const Text('Refaire le quiz'),
      ),
    ]);
  }
}

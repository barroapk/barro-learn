import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'moteur.dart';
import 'question.dart';
import 'quiz.dart';
import 'tableau.dart';

const sceneAsset = 'assets/live_teacher/poulet-chair-scene-01.json';

class LiveTeacherScreen extends StatefulWidget {
  const LiveTeacherScreen({super.key});

  @override
  State<LiveTeacherScreen> createState() => _LiveTeacherScreenState();
}

class _LiveTeacherScreenState extends State<LiveTeacherScreen> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final _player = AudioPlayer();
  late final Ticker _ticker = createTicker((_) => _tick());
  ScenePrete? _scene;
  String? _voix;
  String? _erreur;
  bool _chargement = false;
  bool _fini = false;
  int _t = 0;
  bool _quizFini = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sauver();
    _ticker.dispose();
    _player.dispose();
    super.dispose();
  }

  /// Règle absolue : aucun son quand l'élève quitte l'écran ou l'application.
  @override
  void didChangeAppLifecycleState(AppLifecycleState etat) {
    if (etat != AppLifecycleState.resumed && _player.playing) {
      _player.pause();
      _sauver();
      if (mounted) setState(() {});
    }
  }

  int _derniereSauvegarde = 0;

  /// Sauvegarde du segment et de la position exacte (le tableau se reconstruit à partir du temps).
  Future<void> _sauver() async {
    final voix = _voix;
    if (_scene == null || voix == null) return;
    final fini = _fini;
    final index = _player.currentIndex ?? 0;
    final position = _player.position.inMilliseconds;
    final prefs = await SharedPreferences.getInstance();
    final cle = 'live_teacher:position:$sceneAsset:$voix';
    if (fini) {
      await prefs.remove(cle);
    } else {
      await prefs.setString(cle, jsonEncode({'index': index, 'position_ms': position}));
    }
  }

  Future<void> _demarrer(String voix) async {
    setState(() {
      _voix = voix;
      _chargement = true;
      _erreur = null;
      _fini = false;
      _quizFini = false;
      _t = 0;
    });
    try {
      final scene = await preparerScene(sceneAsset, voix);
      if (!mounted) return;
      for (final url in scene.images.values.where((u) => !u.endsWith('.json'))) {
        precacheImage(NetworkImage(url), context);
      }
      await _player.setAudioSource(ConcatenatingAudioSource(
        children: [for (final s in scene.segments) AudioSource.uri(Uri.parse(s.audioUrl))],
      ));
      final prefs = await SharedPreferences.getInstance();
      final sauve = prefs.getString('live_teacher:position:$sceneAsset:$voix');
      if (sauve != null) {
        final p = jsonDecode(sauve) as Map;
        final index = (p['index'] as int).clamp(0, scene.segments.length - 1);
        await _player.seek(Duration(milliseconds: math.max(0, (p['position_ms'] as int) - 1500)), index: index);
      }
      setState(() {
        _scene = scene;
        _chargement = false;
      });
      if (!_ticker.isActive) _ticker.start();
      _player.play();
    } catch (e) {
      setState(() {
        _chargement = false;
        _erreur = 'Impossible de charger le cours : $e';
      });
    }
  }

  void _tick() {
    final s = _scene;
    if (s == null) return;
    if (_player.processingState == ProcessingState.completed) {
      if (!_fini) {
        setState(() {
          _fini = true;
          _t = s.dureeMs + 60000;
        });
        _sauver();
      }
      return;
    }
    final i = (_player.currentIndex ?? 0).clamp(0, s.segments.length - 1);
    final t = s.segments[i].debutMs + _player.position.inMilliseconds;
    if (_player.playing && (t - _derniereSauvegarde).abs() > 3000) {
      _derniereSauvegarde = t;
      _sauver();
    }
    if (t != _t) setState(() => _t = t);
  }

  void _basculer() {
    _player.playing ? _player.pause() : _player.play();
    setState(() {});
  }

  /// Comme un statut WhatsApp : gauche = revenir, droite = suivant, centre = pause.
  void _toucher(TapUpDetails d) {
    if (_scene == null || _fini) return;
    final x = d.globalPosition.dx / MediaQuery.of(context).size.width;
    if (x < 0.25) {
      _sauter(-1);
    } else if (x > 0.75) {
      _sauter(1);
    } else {
      _basculer();
    }
  }

  Future<void> _sauter(int sens) async {
    final s = _scene!;
    final i = _player.currentIndex ?? 0;
    var cible = i + sens;
    if (sens < 0 && _player.position.inMilliseconds > 1500) cible = i;
    if (cible < 0) cible = 0;
    if (cible >= s.segments.length) return;
    await _player.seek(Duration.zero, index: cible);
  }

  /// L'élève interrompt le cours : pause, sauvegarde, question, puis reprise 1 s avant l'arrêt.
  Future<void> _poserQuestion() async {
    final s = _scene;
    final voix = _voix;
    if (s == null || voix == null) return;
    await _player.pause();
    await _sauver();
    if (!mounted) return;
    final idx = (_player.currentIndex ?? 0).clamp(0, s.segments.length - 1);
    final vus = [for (final seg in s.segments.take(idx + 1)) seg.id];
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => QuestionEleve(voix: voix, segmentsVus: vus)));
    if (!mounted) return;
    final pos = _player.position.inMilliseconds;
    await _player.seek(Duration(milliseconds: math.max(0, pos - 1000)), index: idx);
    _player.play();
    setState(() {});
  }

  Future<void> _recommencer() async {
    setState(() {
      _fini = false;
      _quizFini = false;
      _t = 0;
    });
    await _player.seek(Duration.zero, index: 0);
    _player.play();
  }

  void _changerVoix() {
    _player.stop();
    setState(() {
      _scene = null;
      _fini = false;
      _quizFini = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = _scene;
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F4),
      body: SafeArea(child: s == null ? _accueil() : _cours(s)),
      floatingActionButton: s != null && !_fini
          ? FloatingActionButton.extended(
              onPressed: _poserQuestion,
              icon: const Icon(Icons.help_outline),
              label: const Text('Poser une question'),
            )
          : null,
    );
  }

  Widget _accueil() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('BARRO Live Teacher', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("Qu'est-ce qu'un poulet de chair ?", style: TextStyle(fontSize: 16)),
          const SizedBox(height: 28),
          if (_chargement)
            const CircularProgressIndicator()
          else ...[
            if (_erreur != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(_erreur!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
              ),
            const Text('Choisis ton professeur'),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => _demarrer('henri'),
              icon: const Icon(Icons.record_voice_over),
              label: const Text('Henri'),
            ),
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              onPressed: () => _demarrer('vivienne'),
              icon: const Icon(Icons.record_voice_over),
              label: const Text('Vivienne'),
            ),
            const SizedBox(height: 20),
            const Text(
              'Pendant le cours : touche le centre pour mettre en pause,\nla gauche pour revenir, la droite pour avancer.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, fontSize: 13),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _cours(ScenePrete s) {
    final etat = etatTableau(s, _t + 400);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: _toucher,
      child: Stack(children: [
        Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Row(children: [
              for (final seg in s.segments)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        minHeight: 4,
                        value: ((_t - seg.debutMs) / seg.dureeMs).clamp(0.0, 1.0).toDouble(),
                        backgroundColor: Colors.black12,
                      ),
                    ),
                  ),
                ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(children: [
              Expanded(child: Text(s.titre, style: const TextStyle(fontWeight: FontWeight.w600))),
              Text(_voix == 'henri' ? 'Henri' : 'Vivienne', style: const TextStyle(color: Colors.black54)),
            ]),
          ),
          Expanded(child: _fini && !_quizFini ? QuizVue(key: ValueKey('quiz-$_voix'), voix: _voix!, onFin: () => setState(() => _quizFini = true)) : LiveBoard(elements: etat, t: _t, dessins: s.dessins, nbImages: s.evenements.where((e) => e.cmd['type'] == 'media.show').length)),
          if (_fini && _quizFini)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(children: [
                Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: [
                  FilledButton(onPressed: _recommencer, child: const Text('Recommencer')),
                  OutlinedButton(onPressed: _changerVoix, child: const Text('Changer de voix')),
                ]),
              ]),
            ),
          const SizedBox(height: 12),
        ]),
        if (!_player.playing && !_fini)
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black38,
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: const [
                  Icon(Icons.pause_circle_filled, size: 72, color: Colors.white),
                  SizedBox(height: 8),
                  Text('En pause — touche le centre pour reprendre',
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                  SizedBox(height: 6),
                  Text('◀ revenir          avancer ▶', style: TextStyle(color: Colors.white70, fontSize: 14)),
                ]),
              ),
            ),
          ),
      ]),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:just_audio/just_audio.dart';

import 'moteur.dart';
import 'tableau.dart';

const sceneAsset = 'assets/live_teacher/poulet-chair-scene-01.json';

class LiveTeacherScreen extends StatefulWidget {
  const LiveTeacherScreen({super.key});

  @override
  State<LiveTeacherScreen> createState() => _LiveTeacherScreenState();
}

class _LiveTeacherScreenState extends State<LiveTeacherScreen> with SingleTickerProviderStateMixin {
  final _player = AudioPlayer();
  late final Ticker _ticker = createTicker((_) => _tick());
  ScenePrete? _scene;
  String? _voix;
  String? _erreur;
  bool _chargement = false;
  bool _fini = false;
  int _t = 0;

  @override
  void dispose() {
    _ticker.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _demarrer(String voix) async {
    setState(() {
      _voix = voix;
      _chargement = true;
      _erreur = null;
      _fini = false;
      _t = 0;
    });
    try {
      final scene = await preparerScene(sceneAsset, voix);
      for (final url in scene.images.values) {
        if (!mounted) return;
        await precacheImage(NetworkImage(url), context);
      }
      await _player.setAudioSource(ConcatenatingAudioSource(
        children: [for (final s in scene.segments) AudioSource.uri(Uri.parse(s.audioUrl))],
      ));
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
      }
      return;
    }
    final i = (_player.currentIndex ?? 0).clamp(0, s.segments.length - 1);
    final t = s.segments[i].debutMs + _player.position.inMilliseconds;
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

  Future<void> _recommencer() async {
    setState(() {
      _fini = false;
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
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = _scene;
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F4),
      body: SafeArea(child: s == null ? _accueil() : _cours(s)),
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
          Expanded(child: LiveBoard(elements: etat, t: _t)),
          if (_fini)
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

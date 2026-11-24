import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../data/bibliotheque.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Lecture d'une leçon avec le lecteur officiel YouTube (aucun téléchargement).
class LecteurScreen extends StatefulWidget {
  final CoursVideo cours;
  final int index;

  const LecteurScreen({super.key, required this.cours, required this.index});

  @override
  State<LecteurScreen> createState() => _LecteurScreenState();
}

class _LecteurScreenState extends State<LecteurScreen> {
  late int _index = widget.index;
  late final YoutubePlayerController _controller = YoutubePlayerController.fromVideoId(
    videoId: _lecon.youtube,
    autoPlay: true,
    params: const YoutubePlayerParams(
      showFullscreenButton: false,
      origin: 'https://www.youtube-nocookie.com', // évite l'erreur 152/153 dans la WebView
    ),
  );

  LeconVideo get _lecon => widget.cours.lecons[_index];

  void _aller(int i) {
    if (i < 0 || i >= widget.cours.lecons.length) return;
    setState(() => _index = i);
    _controller.loadVideoById(videoId: _lecon.youtube);
  }

  Future<void> _ouvrirDansYoutube() async {
    var ok = false;
    try {
      ok = await launchUrl(
        Uri.parse('https://www.youtube.com/watch?v=${_lecon.youtube}'),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {}
    if (!ok && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Impossible d\'ouvrir YouTube. Vérifie ta connexion.')));
    }
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.cours.lecons.length;
    return BarroPage(
      child: Column(
        children: [
          TabHeader(
            onBack: () => Navigator.of(context).pop(),
            title: Text(widget.cours.titre, style: display(16), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          YoutubePlayer(controller: _controller, aspectRatio: 16 / 9),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                Text('Leçon ${_index + 1} sur $total · ${dureeTexte(_lecon.duree)}',
                    style: body(12, color: BarroColors.muted)),
                const SizedBox(height: 4),
                Text(_lecon.titre, style: body(16, weight: FontWeight.w800)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _index > 0 ? () => _aller(_index - 1) : null,
                        icon: const Icon(Icons.skip_previous),
                        label: const Text('Précédente'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _index < total - 1 ? () => _aller(_index + 1) : null,
                        icon: const Icon(Icons.skip_next),
                        label: const Text('Suivante'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: _ouvrirDansYoutube,
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('La vidéo ne se lance pas ? Ouvrir dans YouTube'),
                ),
                const SizedBox(height: 8),
                Text(
                  'Vidéo YouTube de la chaîne Mindluster, lue avec le lecteur officiel YouTube.',
                  style: body(12, color: BarroColors.faint),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

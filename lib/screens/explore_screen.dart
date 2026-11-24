import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/catalog.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'bibliotheque_screen.dart';
import 'metiers_screen.dart';
import 'search_screen.dart';

class _Universe {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color tint;
  final bool available;

  const _Universe(this.title, this.subtitle, this.icon, this.color, this.tint, {this.available = false});
}

const _universes = [
  _Universe('Métiers', 'Apprendre un métier qui rapporte', Icons.work_outline, BarroColors.greenText, BarroColors.greenSoft,
      available: true),
  _Universe('Comment faire', 'Des tutoriels pas à pas, en pratique', Icons.checklist, BarroColors.blue, BarroColors.blueSoft),
  _Universe('Astuces du quotidien', 'Une astuce utile chaque jour', Icons.lightbulb_outline, BarroColors.orangeText,
      BarroColors.orangeSoft),
  _Universe('Comment ça marche', 'Les machines, le corps, la nature', Icons.settings_outlined, BarroColors.teal,
      BarroColors.tealSoft),
  _Universe('Histoire & Géographie', 'Comprendre le monde et l\'Afrique', Icons.public, BarroColors.violet,
      BarroColors.violetSoft),
  _Universe('Sciences & Création', 'Expérimenter, inventer, créer', Icons.science_outlined, BarroColors.pink,
      BarroColors.pinkSoft),
];

class ExploreScreen extends StatelessWidget {
  final ValueChanged<int> onOpenTab;

  const ExploreScreen({super.key, required this.onOpenTab});

  void _openSearch(BuildContext context) => Navigator.of(context).push(barroRoute(const SearchScreen()));

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabHeader(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Explorer', style: display(22)),
              Text('${_universes.length} univers · $metierCount métiers', style: body(12, color: BarroColors.muted)),
            ],
          ),
          bottom: Tap(
            onTap: () => _openSearch(context),
            semanticLabel: 'Rechercher',
            child: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: BarroColors.soft, borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  const Icon(Icons.search, color: BarroColors.muted),
                  const SizedBox(width: 10),
                  Text('Que veux-tu apprendre ?', style: body(15, color: BarroColors.muted)),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
            itemCount: _universes.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              if (i == _universes.length) return const FadeSlideIn(index: 6, child: _OnlineCoursesCard());
              final u = _universes[i];
              return FadeSlideIn(
                index: i,
                child: Tap(
                  semanticLabel: u.title,
                  onTap: () => u.available
                      ? Navigator.of(context).push(barroRoute(const MetiersScreen()))
                      : showSoon(context, u.title),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: u.available ? u.tint : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: u.available ? u.tint : BarroColors.line),
                    ),
                    child: Row(
                      children: [
                        SoftIcon(
                          icon: u.icon,
                          tint: u.available ? Colors.white : u.tint,
                          color: u.color,
                          size: 48,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(u.title, style: body(16, weight: FontWeight.w800)),
                              const SizedBox(height: 2),
                              Text(u.subtitle, style: body(13, color: BarroColors.muted)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        u.available
                            ? const Pill(label: 'Ouvert', background: BarroColors.greenDeep, foreground: Colors.white)
                            : Text('Bientôt', style: body(12, color: BarroColors.faint, weight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Bibliothèque de formations : cours vidéo Mindluster lus dans BARRO,
/// avec un lien secondaire vers le site Mindluster.
class _OnlineCoursesCard extends StatelessWidget {
  const _OnlineCoursesCard();

  Future<void> _openSite(BuildContext context) async {
    var ok = false;
    try {
      ok = await launchUrl(Uri.parse('https://www.mindluster.com'), mode: LaunchMode.externalApplication);
    } catch (_) {}
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Impossible d\'ouvrir le site. Vérifie ta connexion.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Tap(
          onTap: () => Navigator.of(context).push(barroRoute(const BibliothequeScreen())),
          semanticLabel: 'Ouvrir la bibliothèque de formations',
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: BarroColors.greenDeep,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.video_library_outlined, color: Colors.white, size: 32),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bibliothèque de formations', style: display(16, color: Colors.white)),
                      const SizedBox(height: 2),
                      Text('Des centaines de cours vidéo en français, avec Mindluster.',
                          style: body(12, color: BarroColors.greenMid, height: 1.35)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white, size: 24),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => _openSite(context),
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text('Site Mindluster et certificats'),
          ),
        ),
      ],
    );
  }
}

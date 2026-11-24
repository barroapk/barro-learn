import 'package:flutter/material.dart';

import '../data/bibliotheque.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'cours_mindluster_screen.dart';

const Map<String, IconData> _icones = {
  'programmation': Icons.code,
  'numerique': Icons.computer,
  'gestion': Icons.trending_up,
  'langues': Icons.translate,
  'sante': Icons.health_and_safety_outlined,
  'autres': Icons.auto_stories_outlined,
};

/// Bibliothèque de formations : les domaines du catalogue vidéo.
class BibliothequeScreen extends StatelessWidget {
  const BibliothequeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BarroPage(
      child: Column(
        children: [
          TabHeader(
            onBack: () => Navigator.of(context).pop(),
            title: Text('Bibliothèque', style: display(22)),
          ),
          Expanded(
            child: FutureBuilder<Bibliotheque>(
              future: Bibliotheque.charger(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return _Message('Le catalogue n\'a pas pu être chargé.');
                }
                final b = snap.data;
                if (b == null) return const Center(child: CircularProgressIndicator());
                if (b.cours.isEmpty) return _Message('Aucun cours disponible pour le moment.');
                final domaines = b.domaines;
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
                  itemCount: domaines.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    if (i == 0) {
                      return Text(
                        '${b.cours.length} cours vidéo en français, proposés avec Mindluster. '
                        'Les vidéos sont lues avec le lecteur officiel YouTube : une connexion internet est nécessaire.',
                        style: body(13, color: BarroColors.muted),
                      );
                    }
                    final d = domaines[i - 1];
                    final nom = domainesBibliotheque[d.key] ?? d.key;
                    return FadeSlideIn(
                      index: i,
                      child: _Carte(
                        icone: _icones[d.key] ?? Icons.auto_stories_outlined,
                        titre: nom,
                        sousTitre: '${d.value} cours',
                        onTap: () => Navigator.of(context).push(barroRoute(
                          _DomaineScreen(nom: nom, cours: b.duDomaine(d.key)),
                        )),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Les cours d'un domaine.
class _DomaineScreen extends StatelessWidget {
  final String nom;
  final List<CoursVideo> cours;

  const _DomaineScreen({required this.nom, required this.cours});

  @override
  Widget build(BuildContext context) {
    return BarroPage(
      child: Column(
        children: [
          TabHeader(
            onBack: () => Navigator.of(context).pop(),
            title: Text(nom, style: display(22)),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
              itemCount: cours.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final c = cours[i];
                return _Carte(
                  icone: Icons.play_circle_outline,
                  titre: c.titre,
                  sousTitre: '${c.lecons.length} leçons · ${dureeTexte(c.dureeTotale)}',
                  onTap: () => Navigator.of(context).push(barroRoute(CoursMindlusterScreen(cours: c))),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Carte extends StatelessWidget {
  final IconData icone;
  final String titre;
  final String sousTitre;
  final VoidCallback onTap;

  const _Carte({required this.icone, required this.titre, required this.sousTitre, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tap(
      onTap: onTap,
      semanticLabel: titre,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: BarroColors.line),
        ),
        child: Row(
          children: [
            SoftIcon(icon: icone, tint: BarroColors.greenSoft, color: BarroColors.greenText, size: 48),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titre, style: body(15, weight: FontWeight.w800), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(sousTitre, style: body(12, color: BarroColors.muted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: BarroColors.faint),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final String texte;

  const _Message(this.texte);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(texte, textAlign: TextAlign.center, style: body(14, color: BarroColors.muted)),
      ),
    );
  }
}

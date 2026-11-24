import 'package:flutter/material.dart';

import '../data/bibliotheque.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'lecteur_screen.dart';

/// Les leçons d'un cours vidéo Mindluster.
class CoursMindlusterScreen extends StatelessWidget {
  final CoursVideo cours;

  const CoursMindlusterScreen({super.key, required this.cours});

  @override
  Widget build(BuildContext context) {
    final lecons = cours.lecons;
    return BarroPage(
      child: Column(
        children: [
          TabHeader(
            onBack: () => Navigator.of(context).pop(),
            title: Text(cours.titre, style: display(18), maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
              itemCount: lecons.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                if (i == 0) {
                  return Text(
                    '${lecons.length} leçons · ${dureeTexte(cours.dureeTotale)}'
                    '${cours.peutEtreIncomplet ? '\nCe cours a peut-être d\'autres leçons, ajoutées plus tard.' : ''}',
                    style: body(13, color: BarroColors.muted),
                  );
                }
                final l = lecons[i - 1];
                return Tap(
                  semanticLabel: 'Leçon $i : ${l.titre}',
                  onTap: () => Navigator.of(context).push(barroRoute(LecteurScreen(cours: cours, index: i - 1))),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: BarroColors.line),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: BarroColors.greenSoft,
                          child: Text('$i', style: body(12, color: BarroColors.greenText, weight: FontWeight.w800)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l.titre, style: body(14, weight: FontWeight.w700), maxLines: 2, overflow: TextOverflow.ellipsis),
                              Text(dureeTexte(l.duree), style: body(12, color: BarroColors.muted)),
                            ],
                          ),
                        ),
                        const Icon(Icons.play_arrow_rounded, color: BarroColors.greenText),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

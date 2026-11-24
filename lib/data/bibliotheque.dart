import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// Domaines de la Bibliothèque de formations (correspondance provisoire).
const Map<String, String> domainesBibliotheque = {
  'programmation': 'Programmation',
  'numerique': 'Numérique',
  'gestion': 'Gestion',
  'langues': 'Langues',
  'sante': 'Santé',
  'autres': 'Autres connaissances',
};

final RegExp _youtubeId = RegExp(r'^[A-Za-z0-9_-]{11}$');

/// Une leçon vidéo du catalogue Mindluster.
class LeconVideo {
  final String id; // mindluster:lesson:N
  final String titre;
  final String youtube; // identifiant de la vidéo YouTube
  final int? duree; // en secondes, parfois inconnue

  const LeconVideo({required this.id, required this.titre, required this.youtube, this.duree});
}

/// Un cours vidéo du catalogue Mindluster.
class CoursVideo {
  final String id; // mindluster:course:N
  final String titre;
  final String domaine;
  final String categorie;
  final List<String> alertes;
  final List<LeconVideo> lecons;

  const CoursVideo({
    required this.id,
    required this.titre,
    required this.domaine,
    required this.categorie,
    required this.alertes,
    required this.lecons,
  });

  bool get peutEtreIncomplet => alertes.contains('peut_etre_tronque_40');

  int get dureeTotale => lecons.fold(0, (s, l) => s + (l.duree ?? 0));
}

/// Le catalogue complet, lu une seule fois depuis les fichiers de l'app.
class Bibliotheque {
  final List<CoursVideo> cours;

  const Bibliotheque(this.cours);

  static const assetPath = 'assets/catalogue/catalogue_fr.json';
  static Future<Bibliotheque>? _chargement;

  /// Charge le catalogue (une seule lecture, puis réutilisation).
  static Future<Bibliotheque> charger() {
    return _chargement ??= rootBundle.loadString(assetPath).then(
      Bibliotheque.fromJsonText,
      onError: (Object e) {
        _chargement = null; // un nouvel essai sera possible
        throw e;
      },
    );
  }

  factory Bibliotheque.fromJsonText(String text) => Bibliotheque.fromJson(jsonDecode(text) as Map<String, dynamic>);

  /// Lecture prudente : une leçon ou un cours mal formé est ignoré, sans planter.
  factory Bibliotheque.fromJson(Map<String, dynamic> json) {
    final out = <CoursVideo>[];
    for (final c in (json['cours'] as List? ?? const [])) {
      if (c is! Map) continue;
      final lecons = <LeconVideo>[];
      for (final l in (c['lecons'] as List? ?? const [])) {
        if (l is! Map) continue;
        final yt = l['youtube'];
        final id = l['id'];
        if (yt is! String || !_youtubeId.hasMatch(yt) || id is! String) continue;
        final d = l['duree'];
        lecons.add(LeconVideo(
          id: id,
          titre: (l['titre'] as String?)?.trim() ?? '',
          youtube: yt,
          duree: d is int ? d : null,
        ));
      }
      final id = c['id'];
      if (id is! String || lecons.isEmpty) continue;
      final domaine = c['domaine'];
      out.add(CoursVideo(
        id: id,
        titre: (c['titre'] as String?)?.trim() ?? '',
        domaine: domaine is String && domainesBibliotheque.containsKey(domaine) ? domaine : 'autres',
        categorie: (c['categorie'] as String?) ?? '',
        alertes: [for (final a in (c['alertes'] as List? ?? const [])) if (a is String) a],
        lecons: lecons,
      ));
    }
    return Bibliotheque(out);
  }

  List<CoursVideo> duDomaine(String domaine) => [for (final c in cours) if (c.domaine == domaine) c];

  /// Domaines non vides, dans l'ordre de [domainesBibliotheque], avec leur nombre de cours.
  List<MapEntry<String, int>> get domaines {
    final n = <String, int>{};
    for (final c in cours) {
      n[c.domaine] = (n[c.domaine] ?? 0) + 1;
    }
    return [for (final d in domainesBibliotheque.keys) if ((n[d] ?? 0) > 0) MapEntry(d, n[d]!)];
  }
}

/// « 1 h 05 », « 12 min », ou « durée inconnue ».
String dureeTexte(int? secondes) {
  if (secondes == null || secondes <= 0) return 'durée inconnue';
  final h = secondes ~/ 3600;
  final m = (secondes % 3600) ~/ 60;
  if (h > 0) return '$h h ${m.toString().padLeft(2, '0')}';
  return '${m < 1 ? 1 : m} min';
}

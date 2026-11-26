import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;

/// Moteur Live Teacher : relie la scène, les voix (barro-voix) et les images (barro-images).
const cdnVoix = 'https://cdn.jsdelivr.net/gh/barroapk/barro-voix@main';
const cdnImages = 'https://cdn.jsdelivr.net/gh/barroapk/barro-images@main';

Future<dynamic> lireJsonWeb(String url) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
  try {
    final req = await client.getUrl(Uri.parse(url));
    final rep = await req.close();
    if (rep.statusCode != 200) {
      throw Exception('Téléchargement impossible (${rep.statusCode})');
    }
    return jsonDecode(await rep.transform(utf8.decoder).join());
  } finally {
    client.close();
  }
}

/// Même normalisation que le vérificateur d'ancres : minuscules, sans accents ni ponctuation.
String normaliser(String s) {
  const accents = {
    'à': 'a', 'â': 'a', 'ä': 'a', 'á': 'a', 'ã': 'a', 'ç': 'c', 'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
    'î': 'i', 'ï': 'i', 'í': 'i', 'ô': 'o', 'ö': 'o', 'ó': 'o', 'ù': 'u', 'û': 'u', 'ü': 'u', 'ú': 'u',
    'ÿ': 'y', 'œ': 'oe', 'æ': 'ae', '’': "'",
  };
  final b = StringBuffer();
  for (final ch in s.toLowerCase().split('')) {
    b.write(accents[ch] ?? ch);
  }
  return b.toString().replaceAll(RegExp(r"[^a-z0-9']"), '');
}

class Evenement {
  Evenement(this.tMs, this.ordre, this.cmd);
  final int tMs;
  final int ordre;
  final Map<String, dynamic> cmd;
}

class SegmentPret {
  SegmentPret(this.id, this.audioUrl, this.debutMs, this.dureeMs);
  final String id;
  final String audioUrl;
  final int debutMs;
  final int dureeMs;
}

class ScenePrete {
  ScenePrete(this.titre, this.segments, this.evenements, this.images);
  final String titre;
  final List<SegmentPret> segments;
  final List<Evenement> evenements;
  final Map<String, String> images;
  int get dureeMs => segments.isEmpty ? 0 : segments.last.debutMs + segments.last.dureeMs;
}

Future<ScenePrete> preparerScene(String asset, String voix) async {
  final scene = jsonDecode(await rootBundle.loadString(asset)) as Map<String, dynamic>;
  final catVoix = (await lireJsonWeb('$cdnVoix/catalogue.json')) as List;
  final catImages = (await lireJsonWeb('$cdnImages/catalogue.json')) as List;
  final images = <String, String>{};
  for (final c in catImages) {
    if (c['actif'] == true) images[c['id'] as String] = c['url'] as String;
  }
  final segments = <SegmentPret>[];
  final evenements = <Evenement>[];
  var debut = 0;
  var ordre = 0;
  for (final seg in scene['segments'] as List) {
    Map? entree;
    for (final c in catVoix) {
      if (c['scene'] == scene['scene'] && c['segment'] == seg['id'] && c['voix'] == voix && c['actif'] == true) {
        entree = c as Map;
      }
    }
    if (entree == null) throw Exception('Voix introuvable pour le segment ${seg['id']}');
    final donnees = await lireJsonWeb(entree['reperes'] as String) as Map;
    final reperes = donnees['reperes'] as List;
    final mots = [for (final r in reperes) normaliser(r['texte'] as String)];
    for (final cmd in seg['commandes'] as List) {
      var t = 0;
      final ancre = cmd['ancre'];
      if (ancre != null) {
        final cible = normaliser(ancre['mot'] as String);
        final n = (ancre['n'] ?? 1) as int;
        var vu = 0;
        for (var i = 0; i < mots.length; i++) {
          if (mots[i] == cible || mots[i].startsWith(cible)) {
            vu++;
            if (vu == n) {
              t = reperes[i]['debut_ms'] as int;
              break;
            }
          }
        }
      }
      evenements.add(Evenement(debut + t, ordre++, Map<String, dynamic>.from(cmd as Map)));
    }
    final duree = donnees['duree_ms'] as int;
    segments.add(SegmentPret(seg['id'] as String, entree['audio'] as String, debut, duree));
    debut += duree;
  }
  evenements.sort((a, b) => a.tMs != b.tMs ? a.tMs.compareTo(b.tMs) : a.ordre.compareTo(b.ordre));
  return ScenePrete(scene['titre'] as String, segments, evenements, images);
}

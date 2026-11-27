import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Offset;

import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

/// Moteur Live Teacher : relie la scène, les voix (barro-voix) et les images (barro-images).
const cdnVoix = 'https://cdn.jsdelivr.net/gh/barroapk/barro-voix@main';
const cdnImages = 'https://cdn.jsdelivr.net/gh/barroapk/barro-images@main';

/// Les catalogues changent souvent : lus directement sur GitHub (mémoire de 5 min),
/// alors que jsDelivr peut garder une ancienne version jusqu'à 12 h.
const catalogueVoix = 'https://raw.githubusercontent.com/barroapk/barro-voix/main/catalogue.json';
const catalogueImages = 'https://raw.githubusercontent.com/barroapk/barro-images/main/catalogue.json';

Future<String> _telecharger(String url) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
  try {
    final req = await client.getUrl(Uri.parse(url));
    final rep = await req.close();
    if (rep.statusCode != 200) {
      throw Exception('Téléchargement impossible (${rep.statusCode})');
    }
    return await rep.transform(utf8.decoder).join();
  } finally {
    client.close();
  }
}

/// Lecture avec mémoire sur le téléphone.
/// immuable = fichier versionné (ne change jamais) : jamais re-téléchargé.
/// Sinon (catalogues) : ouvert depuis la mémoire, mis à jour en arrière-plan pour la fois suivante.
Future<dynamic> lireJsonWeb(String url, {bool immuable = false}) async {
  final prefs = await SharedPreferences.getInstance();
  final cle = 'cache:$url';
  final cache = prefs.getString(cle);
  if (cache != null) {
    if (!immuable) {
      _telecharger(url).then((t) => prefs.setString(cle, t)).catchError((_) => false);
    }
    return jsonDecode(cache);
  }
  final texte = await _telecharger(url);
  await prefs.setString(cle, texte);
  return jsonDecode(texte);
}

/// Télécharge la version la plus récente et met la mémoire à jour.
Future<dynamic> lireJsonFrais(String url) async {
  final texte = await _telecharger(url);
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('cache:$url', texte);
  return jsonDecode(texte);
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
  ScenePrete(this.titre, this.segments, this.evenements, this.images, [this.dessins = const {}]);
  final String titre;
  final List<SegmentPret> segments;
  final List<Evenement> evenements;
  final Map<String, String> images;
  final Map<String, Dessin> dessins;
  int get dureeMs => segments.isEmpty ? 0 : segments.last.debutMs + segments.last.dureeMs;
}

Future<ScenePrete> preparerScene(String asset, String voix) async {
  final scene = jsonDecode(await rootBundle.loadString(asset)) as Map<String, dynamic>;
  final cats = await Future.wait([lireJsonWeb(catalogueVoix), lireJsonWeb(catalogueImages)]);
  var catVoix = cats[0] as List;
  if (!catVoix.any((c) => c['scene'] == scene['scene'] && c['voix'] == voix)) {
    catVoix = await lireJsonFrais(catalogueVoix) as List;
  }
  final catImages = cats[1] as List;
  final images = <String, String>{};
  for (final c in catImages) {
    if (c['actif'] == true) images[c['id'] as String] = c['url'] as String;
  }
  final segments = <SegmentPret>[];
  final evenements = <Evenement>[];
  var debut = 0;
  var ordre = 0;
  final segs = scene['segments'] as List;
  final entrees = <Map>[];
  for (final seg in segs) {
    Map? entree;
    for (final c in catVoix) {
      if (c['scene'] == scene['scene'] && c['segment'] == seg['id'] && c['voix'] == voix && c['actif'] == true) {
        entree = c as Map;
      }
    }
    if (entree == null) throw Exception('Voix introuvable pour le segment ${seg['id']}');
    entrees.add(entree);
  }
  final tousReperes = await Future.wait([for (final en in entrees) lireJsonWeb(en['reperes'] as String, immuable: true)]);
  for (var si = 0; si < segs.length; si++) {
    final seg = segs[si];
    final entree = entrees[si];
    final donnees = tousReperes[si] as Map;
    final reperes = donnees['reperes'] as List;
    final mots = [for (final r in reperes) normaliser(r['texte'] as String)];
    for (final cmd in seg['commandes'] as List) {
      var t = -1;
      final ancre = cmd['ancre'];
      if (ancre == null) t = 0;
      if (ancre != null) {
        final cible = normaliser(ancre['mot'] as String);
        final n = (ancre['n'] ?? 1) as int;
        var vu = 0;
        for (var i = 0; i < mots.length; i++) {
          if (mots[i] == cible) {
            vu++;
            if (vu == n) {
              t = reperes[i]['debut_ms'] as int;
              break;
            }
          }
        }
      }
      if (t < 0) throw Exception('Ancre introuvable : ${ancre['mot']} (segment ${seg['id']})');
      evenements.add(Evenement(debut + t, ordre++, Map<String, dynamic>.from(cmd as Map)));
    }
    final duree = donnees['duree_ms'] as int;
    segments.add(SegmentPret(seg['id'] as String, entree['audio'] as String, debut, duree));
    debut += duree;
  }
  evenements.sort((a, b) => a.tMs != b.tMs ? a.tMs.compareTo(b.tMs) : a.ordre.compareTo(b.ordre));
  for (var i = 0; i < evenements.length; i++) {
    evenements[i].cmd['_suivant'] = i + 1 < evenements.length ? evenements[i + 1].tMs : evenements[i].tMs + 5000;
  }
  final dessins = <String, Dessin>{};
  for (final seg in scene['segments'] as List) {
    for (final cmd in seg['commandes'] as List) {
      final id = cmd['dessin'] as String?;
      if (id != null && images[id] != null && !dessins.containsKey(id)) {
        dessins[id] = Dessin.fromJson(await lireJsonWeb(images[id]!, immuable: true) as Map);
      }
    }
  }
  return ScenePrete(scene['titre'] as String, segments, evenements, images, dessins);
}

/// Un dessin au trait : traits ordonnés, que la main parcourt du premier au dernier.
class Dessin {
  Dessin(this.largeur, this.hauteur, this.traits) {
    longueurs = [for (final t in traits) _longueur(t)];
    total = longueurs.fold(0.0, (a, b) => a + b);
  }
  factory Dessin.fromJson(Map j) => Dessin(
        (j['largeur'] as num).toDouble(),
        (j['hauteur'] as num).toDouble(),
        [
          for (final t in j['traits'] as List)
            [for (final p in t as List) Offset((p[0] as num).toDouble(), (p[1] as num).toDouble())]
        ],
      );
  final double largeur;
  final double hauteur;
  final List<List<Offset>> traits;
  late final List<double> longueurs;
  late final double total;

  static double _longueur(List<Offset> t) {
    var s = 0.0;
    for (var i = 1; i < t.length; i++) {
      s += (t[i] - t[i - 1]).distance;
    }
    return s;
  }

  /// Les traits déjà dessinés pour une progression p (0..1), le dernier partiellement.
  List<List<Offset>> partiel(double p) {
    var reste = p.clamp(0.0, 1.0) * total;
    final out = <List<Offset>>[];
    for (var i = 0; i < traits.length; i++) {
      final t = traits[i];
      if (reste >= longueurs[i]) {
        out.add(t);
        reste -= longueurs[i];
        continue;
      }
      final partie = <Offset>[t.first];
      for (var j = 1; j < t.length && reste > 0; j++) {
        final seg = (t[j] - t[j - 1]).distance;
        if (reste >= seg) {
          partie.add(t[j]);
          reste -= seg;
        } else {
          partie.add(Offset.lerp(t[j - 1], t[j], reste / seg)!);
          reste = 0;
        }
      }
      out.add(partie);
      break;
    }
    return out;
  }

  /// Position de la pointe du feutre.
  Offset pointe(double p) {
    final parts = partiel(p);
    if (parts.isEmpty) return traits.isEmpty ? Offset.zero : traits.first.first;
    return parts.last.last;
  }
}

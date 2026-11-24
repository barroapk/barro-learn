import 'dart:io';

import 'package:barro_learn/data/bibliotheque.dart';
import 'package:barro_learn/state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final b = Bibliotheque.fromJsonText(File('assets/catalogue/catalogue_fr.json').readAsStringSync());

  test('le catalogue pilote contient 403 cours, tous avec des leçons', () {
    expect(b.cours.length, 403);
    expect(b.cours.every((c) => c.lecons.isNotEmpty), isTrue);
  });

  test('identifiants uniques, au bon format, vidéos YouTube valides', () {
    final ids = b.cours.map((c) => c.id).toList();
    expect(ids.toSet().length, ids.length);
    final yt = RegExp(r'^[A-Za-z0-9_-]{11}$');
    for (final c in b.cours) {
      expect(c.id, matches(RegExp(r'^mindluster:course:\d+$')));
      for (final l in c.lecons) {
        expect(l.id, matches(RegExp(r'^mindluster:lesson:\d+$')));
        expect(yt.hasMatch(l.youtube), isTrue, reason: l.id);
      }
    }
  });

  test('chaque cours appartient à un domaine connu', () {
    for (final c in b.cours) {
      expect(domainesBibliotheque.containsKey(c.domaine), isTrue, reason: c.id);
    }
    expect(b.domaines.fold<int>(0, (s, d) => s + d.value), 403);
  });

  test('une entrée mal formée est ignorée sans planter', () {
    final x = Bibliotheque.fromJson({
      'cours': [
        {'id': 'mindluster:course:1', 'titre': 'A', 'domaine': 'inconnu', 'lecons': [
          {'id': 'mindluster:lesson:1', 'titre': 'ok', 'youtube': 'abcdefghijk', 'duree': 60},
          {'id': 'mindluster:lesson:2', 'titre': 'mauvais', 'youtube': 'trop-court'},
        ]},
        {'id': 'mindluster:course:2', 'titre': 'vide', 'lecons': []},
        'pas un cours',
      ],
    });
    expect(x.cours.length, 1);
    expect(x.cours.first.lecons.length, 1);
    expect(x.cours.first.domaine, 'autres');
  });

  test('les cours BARRO internes restent intacts', () {
    expect(allCourses.keys.toSet(), {'poulet-chair', 'maraichage', 'boutique'});
  });

  test('durées lisibles', () {
    expect(dureeTexte(null), 'durée inconnue');
    expect(dureeTexte(1152), '19 min');
    expect(dureeTexte(3900), '1 h 05');
  });
}

import 'dart:async';
import 'dart:convert';

import 'package:barro_learn/data/poultry_course.dart';
import 'package:barro_learn/state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';

/// Faux stockage : écritures bloquées, en échec ou "mensongères", avec journal.
class FakeStore extends InMemorySharedPreferencesStore {
  FakeStore(Map<String, Object> values)
      : super.withData({for (final e in values.entries) 'flutter.${e.key}': e.value});

  /// Clés (début de nom) dont toute écriture renvoie false sans rien enregistrer.
  final Set<String> failKeys = {};

  /// Clés (début de nom) dont toute écriture renvoie true SANS rien enregistrer.
  final Set<String> lieKeys = {};

  /// Échecs / mensonges ciblés par clé ET valeur.
  bool Function(String key, Object value)? failIf;
  bool Function(String key, Object value)? lieIf;

  /// Écritures bloquées tant que [gate] n'est pas ouverte.
  bool Function(String key, Object value)? gateIf;
  final Completer<void> gate = Completer<void>();
  final Completer<void> gateReached = Completer<void>();
  int gatedStarted = 0;
  int gatedEnded = 0;

  /// Si vrai, toute lecture complète du stockage (reload) échoue.
  bool readsFail = false;

  /// Appelé après chaque écriture réussie (pour déclencher un incident).
  void Function(String key, Object value)? afterWrite;

  /// Clés dont la suppression renvoie false sans rien supprimer.
  final Set<String> failRemoveKeys = {};

  final List<String> log = [];
  int active = 0;
  int maxActive = 0;

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    final short = key.startsWith('flutter.') ? key.substring(8) : key;
    final gated = gateIf?.call(short, value) ?? false;
    active++;
    if (active > maxActive) maxActive = active;
    log.add('start $short=$value');
    try {
      if (gated) {
        gatedStarted++;
        if (!gateReached.isCompleted) gateReached.complete();
        await gate.future;
      }
      if (failKeys.any(short.startsWith) || (failIf?.call(short, value) ?? false)) return false;
      if (lieKeys.any(short.startsWith) || (lieIf?.call(short, value) ?? false)) return true;
      final ok = await super.setValue(valueType, key, value);
      afterWrite?.call(short, value);
      return ok;
    } finally {
      if (gated) gatedEnded++;
      log.add('end $short=$value');
      active--;
    }
  }

  @override
  Future<bool> remove(String key) async {
    final short = key.startsWith('flutter.') ? key.substring(8) : key;
    if (failRemoveKeys.contains(short)) return false;
    return super.remove(key);
  }

  @override
  Future<Map<String, Object>> getAll() {
    if (readsFail) throw StateError('lecture impossible');
    return super.getAll();
  }

  @override
  Future<Map<String, Object>> getAllWithParameters(GetAllParameters parameters) {
    if (readsFail) throw StateError('lecture impossible');
    return super.getAllWithParameters(parameters);
  }
}

class Env {
  Env(this.state, this.prefs);
  final AppState state;
  final SharedPreferences prefs;
}

Future<Env> startWith(FakeStore store) async {
  SharedPreferences.setMockInitialValues({}); // remet le singleton à zéro
  SharedPreferencesStorePlatform.instance = store; // puis branche le faux stockage
  final prefs = await SharedPreferences.getInstance();
  await prefs.reload(); // le cache vient maintenant du faux stockage
  final state = AppState.forTesting();
  await state.load();
  return Env(state, prefs);
}

/// Simule un redémarrage : nouvel AppState chargé depuis le même stockage.
Future<AppState> restart(Env env) async {
  await env.prefs.reload();
  final s = AppState.forTesting();
  await s.load();
  return s;
}

/// Laisse s'exécuter tout ce qui n'est pas bloqué (le faux stockage n'a pas de
/// minuterie). À confirmer à l'exécution : ce n'est pas une garantie universelle.
Future<void> drain() async {
  for (var i = 0; i < 3; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

const _keys = ['completed', 'xp', 'streak', 'lastDay', 'progress_reset_pending'];

/// Le cache de la bibliothèque doit être identique au stockage.
Future<void> expectCacheMatchesStore(Env env, FakeStore store) async {
  final all = await store.getAll();
  for (final k in _keys) {
    expect(env.prefs.get(k), all['flutter.$k'], reason: 'cache ≠ stockage pour $k');
  }
}

Map<String, dynamic> backupOf(Map<String, Object> all, int n) =>
    jsonDecode(all['flutter.progress_backup_$n']! as String) as Map<String, dynamic>;

void main() {
  final lesson = poultryCourse.allLessons.last;

  group('file d\'attente des sauvegardes', () {
    test('jamais deux écritures en même temps, le dernier état gagne', () async {
      final store = FakeStore({'completed': ['poulet-chair:1']});
      store.gateIf = (k, v) => k == 'name' && v == 'A';
      final env = await startWith(store);

      env.state.setName('A');
      await store.gateReached.future; // l'écriture de A est en cours et bloquée
      env.state.setName('B');
      env.state.setName('C');
      await drain();

      // Porte fermée : aucune autre écriture n'a démarré.
      expect(store.log.where((l) => l.startsWith('start ')).last, 'start name=A');
      expect(store.active, 1);

      store.gate.complete();
      await env.state.pendingSave;

      expect(store.gatedEnded, store.gatedStarted);
      expect(store.maxActive, 1);
      expect(store.active, 0);
      expect((await store.getAll())['flutter.name'], 'C');
      final starts = store.log.where((l) => l.startsWith('start name=')).toList();
      expect(starts, ['start name=A', 'start name=C']);
    });

    test('pendingSave ne se termine pas tant qu\'une écriture est bloquée', () async {
      final store = FakeStore({});
      store.gateIf = (k, v) => k == 'name' && v == 'A';
      final env = await startWith(store);

      env.state.setName('A');
      await store.gateReached.future; // A est en cours d'écriture, bloquée
      env.state.completeLesson(lesson, 10);
      env.state.setName('B');
      var finished = false;
      final pending = env.state.pendingSave.then((_) => finished = true);
      await drain();
      expect(finished, isFalse);

      store.gate.complete();
      await pending;

      expect(finished, isTrue);
      expect(store.active, 0);
      expect(store.gatedEnded, store.gatedStarted);
      final all = await store.getAll();
      expect(all['flutter.name'], 'B');
      expect(all['flutter.completed'], contains('poulet-chair:${lesson.number}'));
    });

    test('une ancienne sauvegarde ne peut jamais écraser le résultat du reset', () async {
      final store = FakeStore({});
      // Toute écriture d'une ANCIENNE valeur est bloquée, quelle que soit la clé.
      store.gateIf = (k, v) =>
          (k == 'completed' && (v as List).isNotEmpty) ||
          (k == 'xp' && v != 0) ||
          (k == 'streak' && v != 0) ||
          (k == 'lastDay' && v != '');
      final env = await startWith(store);

      env.state.completeLesson(lesson, 10); // sauvegarde de l'ancien état
      await store.gateReached.future; // elle écrit, bloquée
      var resetDone = false;
      final reset = env.state.resetProgress().then((ok) {
        resetDone = true;
        return ok;
      });
      await drain();

      // Porte fermée : le reset n'a rien écrit et n'est pas terminé.
      // Sans file d'attente, il aurait tout fait pendant drain() : échec ici.
      expect(resetDone, isFalse);
      expect(
          store.log.any((l) =>
              l.startsWith('start progress_') || l == 'start completed=[]' || l == 'start xp=0'),
          isFalse);

      store.gate.complete();
      expect(await reset, isTrue);
      await env.state.pendingSave;

      // Toutes les anciennes écritures sont terminées, aucune n'est en cours.
      expect(store.gatedStarted, greaterThan(0));
      expect(store.gatedEnded, store.gatedStarted);
      expect(store.active, 0);
      expect(store.maxActive, 1);

      final all = await store.getAll();
      expect(all['flutter.completed'], isEmpty);
      expect(all['flutter.xp'], 0);
      expect(all['flutter.streak'], 0);
      expect(all['flutter.lastDay'], '');
      expect(all.containsKey('flutter.progress_reset_pending'), isFalse);
      expect(env.state.totalCompleted, 0);
      await expectCacheMatchesStore(env, store);
    });
  });

  group('resetProgress : refus avant toute modification', () {
    const unreadable = <String, Object>{
      'completed': ['poulet-chair:1', 'poulet-chair:2'],
      'xp': 'pas un nombre',
    };

    Future<void> expectUntouched(FakeStore store, Env env) async {
      final all = await store.getAll();
      expect(all['flutter.completed'], ['poulet-chair:1', 'poulet-chair:2']);
      expect(all['flutter.xp'], 'pas un nombre');
      expect(all.keys.any((k) => k.startsWith('flutter.progress_backup')), isFalse);
      expect(all.containsKey('flutter.progress_reset_pending'), isFalse);
      expect(env.state.progressUnreadable, isTrue);
    }

    test('écriture de la copie en échec', () async {
      final store = FakeStore(unreadable)..failKeys.add('progress_backup');
      final env = await startWith(store);
      expect(() => env.prefs.getInt('xp'), throwsA(anything)); // l'erreur existe vraiment
      expect(await env.state.resetProgress(), isFalse);
      await expectUntouched(store, env);
    });

    test('copie non retrouvée à la relecture', () async {
      final store = FakeStore(unreadable)..lieKeys.add('progress_backup');
      final env = await startWith(store);
      expect(await env.state.resetProgress(), isFalse);
      await expectUntouched(store, env);
    });

    test('clé témoin non confirmée mais absence confirmée : reste sain, rien touché', () async {
      final store = FakeStore({'completed': ['poulet-chair:1'], 'xp': 40})
        ..lieKeys.add('progress_reset_pending');
      final env = await startWith(store);

      expect(await env.state.resetProgress(), isFalse);
      final all = await store.getAll();
      expect(all['flutter.completed'], ['poulet-chair:1']);
      expect(all['flutter.xp'], 40);
      expect(all.containsKey('flutter.progress_backup_1'), isTrue);
      expect(all.containsKey('flutter.progress_reset_pending'), isFalse);
      expect(env.state.xp, 40);
      expect(env.state.progressUnreadable, isFalse);
    });

    test('valeurs non encodables (dépend de jsonEncode)', () async {
      final store = FakeStore({'xp': double.nan});
      final env = await startWith(store);
      expect(() => env.prefs.getInt('xp'), throwsA(anything));
      expect(await env.state.resetProgress(), isFalse);
      final all = await store.getAll();
      final xp = all['flutter.xp'];
      expect(xp is double && xp.isNaN, isTrue);
      expect(all.keys.any((k) => k.startsWith('flutter.progress_')), isFalse);
    });
  });

  group('resetProgress : succès', () {
    test('progression saine : copie, zéros relus, clé témoin retirée', () async {
      final store = FakeStore({'completed': ['poulet-chair:1'], 'xp': 40});
      final env = await startWith(store);

      expect(await env.state.resetProgress(), isTrue);

      final all = await store.getAll();
      expect(all['flutter.completed'], isEmpty);
      expect(all['flutter.xp'], 0);
      expect(all.containsKey('flutter.progress_reset_pending'), isFalse);
      expect(backupOf(all, 1)['xp'], 40);
      expect(backupOf(all, 1)['completed'], ['poulet-chair:1']);
      expect(env.state.progressUnreadable, isFalse);
      await expectCacheMatchesStore(env, store);
    });

    test('progression illisible : copie des valeurs brutes, puis zéros', () async {
      final store = FakeStore({'completed': ['poulet-chair:1', 'poulet-chair:2'], 'xp': 'pas un nombre'});
      final env = await startWith(store);

      expect(await env.state.resetProgress(), isTrue);

      final all = await store.getAll();
      expect(all['flutter.xp'], 0);
      expect(backupOf(all, 1)['xp'], 'pas un nombre');
      expect(env.state.progressUnreadable, isFalse);
    });

    test('une copie existante n\'est jamais écrasée', () async {
      final store = FakeStore({'xp': 40, 'progress_backup_1': 'ancien'});
      final env = await startWith(store);

      expect(await env.state.resetProgress(), isTrue);
      final all = await store.getAll();
      expect(all['flutter.progress_backup_1'], 'ancien');
      expect(backupOf(all, 2)['xp'], 40);
    });

    test('la copie reflète le disque, pas un cache contenant une écriture échouée', () async {
      final store = FakeStore({'completed': ['poulet-chair:1'], 'xp': 40});
      final env = await startWith(store);
      store.failIf = (k, v) => k == 'xp' && v == 50; // la sauvegarde de xp=50 échoue
      env.state.completeLesson(lesson, 10); // cache xp = 50, disque xp = 40
      await env.state.pendingSave;
      store.failIf = null;

      expect(await env.state.resetProgress(), isTrue);
      expect(backupOf(await store.getAll(), 1)['xp'], 40);
    });
  });

  group('resetProgress : échec des zéros', () {
    const healthy = <String, Object>{
      'completed': ['poulet-chair:1', 'poulet-chair:2'],
      'xp': 40,
      'streak': 3,
      'lastDay': '2026-1-1',
    };

    test('progression saine, restauration confirmée : état d\'avant, clé retirée', () async {
      final store = FakeStore(healthy);
      final env = await startWith(store);
      store.failIf = (k, v) => k == 'xp' && v == 0;

      expect(await env.state.resetProgress(), isFalse);

      final all = await store.getAll();
      for (final e in healthy.entries) {
        expect(all['flutter.${e.key}'], e.value, reason: e.key);
      }
      expect(all.containsKey('flutter.progress_reset_pending'), isFalse);
      expect(backupOf(all, 1)['xp'], 40);
      expect(env.state.saveFailed, isTrue);
      expect(env.state.progressUnreadable, isFalse);
      expect(env.state.xp, 40);
      expect(env.state.totalCompleted, 2);
      await expectCacheMatchesStore(env, store);
      expect((await restart(env)).progressUnreadable, isFalse);
    });

    test('progression SAINE, restauration en ÉCHEC, puis redémarrage', () async {
      final store = FakeStore(healthy);
      final env = await startWith(store);
      // Zéro de xp refusé, et restauration de completed refusée : disque partiel.
      store.failIf = (k, v) => (k == 'xp' && v == 0) || (k == 'completed' && (v as List).isNotEmpty);

      // 1. Échec annoncé, progression déclarée non saine.
      expect(await env.state.resetProgress(), isFalse);
      expect(env.state.saveFailed, isTrue);
      expect(env.state.progressUnreadable, isTrue);
      expect(env.state.totalCompleted, 0);

      // 2. Disque partiel, clé témoin présente, copie intacte.
      final all = await store.getAll();
      expect(all['flutter.completed'], isEmpty);
      expect(all['flutter.xp'], 40);
      expect(all['flutter.progress_reset_pending'], 'progress_backup_1');
      expect(backupOf(all, 1)['completed'], ['poulet-chair:1', 'poulet-chair:2']);
      expect(backupOf(all, 1)['xp'], 40);
      expect(backupOf(all, 1)['streak'], 3);
      await expectCacheMatchesStore(env, store);

      // 3. Redémarrage : non saine, aucune écriture de progression.
      final restarted = await restart(env);
      expect(restarted.progressUnreadable, isTrue);
      expect(restarted.totalCompleted, 0);
      restarted.completeLesson(lesson, 10);
      await restarted.pendingSave;
      final afterSave = await store.getAll();
      expect(afterSave['flutter.completed'], isEmpty);
      expect(afterSave['flutter.xp'], 40);

      // 4. Récupération : nouvel essai réussi, première copie conservée.
      store.failIf = null;
      expect(await restarted.resetProgress(), isTrue);
      final after = await store.getAll();
      expect(after['flutter.xp'], 0);
      expect(after.containsKey('flutter.progress_reset_pending'), isFalse);
      expect(after['flutter.progress_backup_1'], all['flutter.progress_backup_1']);
      expect(after.containsKey('flutter.progress_backup_2'), isTrue);
      expect(restarted.progressUnreadable, isFalse);
      expect((await restart(env)).progressUnreadable, isFalse);
    });

    test('restauration "réussie" selon le stockage mais non relue : clé témoin gardée', () async {
      final store = FakeStore(healthy);
      final env = await startWith(store);
      store.failIf = (k, v) => k == 'xp' && v == 0;
      store.lieIf = (k, v) => k == 'completed' && (v as List).isNotEmpty; // dit true, n'écrit rien

      expect(await env.state.resetProgress(), isFalse);

      final all = await store.getAll();
      expect(all['flutter.completed'], isEmpty);
      expect(all['flutter.progress_reset_pending'], 'progress_backup_1');
      expect(env.state.progressUnreadable, isTrue);
      expect((await restart(env)).progressUnreadable, isTrue);
    });

    test('zéros "écrits" selon le stockage mais non relus : pas de faux succès', () async {
      final store = FakeStore(healthy);
      final env = await startWith(store);
      store.lieIf = (k, v) => k == 'xp' && v == 0;

      expect(await env.state.resetProgress(), isFalse);

      final all = await store.getAll();
      expect(all['flutter.xp'], 40);
      expect(all['flutter.completed'], ['poulet-chair:1', 'poulet-chair:2']);
      expect(all.containsKey('flutter.progress_reset_pending'), isFalse);
      expect(env.state.xp, 40);
      expect(env.state.progressUnreadable, isFalse);
    });

    test('progression illisible, restauration confirmée : reste non saine, copie intacte', () async {
      final store = FakeStore({'completed': ['poulet-chair:1', 'poulet-chair:2'], 'xp': 'pas un nombre'});
      final env = await startWith(store);
      store.failIf = (k, v) => k == 'xp' && v == 0;

      expect(await env.state.resetProgress(), isFalse);

      final all = await store.getAll();
      expect(all['flutter.completed'], ['poulet-chair:1', 'poulet-chair:2']);
      expect(all['flutter.xp'], 'pas un nombre');
      expect(all.containsKey('flutter.streak'), isFalse); // absente à l'origine
      expect(all.containsKey('flutter.progress_reset_pending'), isFalse);
      expect(backupOf(all, 1)['xp'], 'pas un nombre');
      expect(env.state.progressUnreadable, isTrue);
      await expectCacheMatchesStore(env, store);
      expect((await restart(env)).progressUnreadable, isTrue);
    });
  });

  group('nouvelles tentatives et clé témoin', () {
    const healthy = <String, Object>{
      'completed': ['poulet-chair:1', 'poulet-chair:2'],
      'xp': 40,
      'streak': 3,
      'lastDay': '2026-1-1',
    };

    /// Premier reset en échec : disque partiel, clé témoin = progress_backup_1.
    Future<Env> firstPartialFailure(FakeStore store) async {
      final env = await startWith(store);
      store.failIf = (k, v) => (k == 'xp' && v == 0) || (k == 'completed' && (v as List).isNotEmpty);
      expect(await env.state.resetProgress(), isFalse);
      final all = await store.getAll();
      expect(all['flutter.progress_reset_pending'], 'progress_backup_1');
      expect(all['flutter.completed'], isEmpty); // partiel
      return env;
    }

    test('2e tentative en échec, redémarrage, référence gardée, puis succès', () async {
      final store = FakeStore(healthy);
      final env = await firstPartialFailure(store);
      final original = (await store.getAll())['flutter.progress_backup_1'];

      // Redémarrage après le premier échec : non saine.
      final s2 = await restart(env);
      expect(s2.progressUnreadable, isTrue);

      // a) Nouvelle tentative : les zéros de xp échouent encore, mais la
      //    réécriture des données partielles réussit.
      store.failIf = (k, v) => k == 'xp' && v == 0;
      store.log.clear();
      expect(await s2.resetProgress(), isFalse);

      final all = await store.getAll();
      expect(all['flutter.completed'], isEmpty);
      expect(all['flutter.xp'], 40);
      // c) La clé témoin d'origine est conservée et n'a jamais été réécrite.
      expect(all['flutter.progress_reset_pending'], 'progress_backup_1');
      expect(store.log.any((l) => l.startsWith('start progress_reset_pending=')), isFalse,
          reason: 'la clé témoin existante ne doit jamais être réécrite');
      expect(all['flutter.progress_backup_1'], original);
      expect(backupOf(all, 2)['completed'], isEmpty); // copie des données partielles
      expect(s2.progressUnreadable, isTrue);
      expect(s2.saveFailed, isTrue);
      expect(s2.totalCompleted, 0);
      await expectCacheMatchesStore(env, store);

      // b) Redémarrage après le 2e échec : toujours non saine, rien n'est écrit.
      final s3 = await restart(env);
      expect(s3.progressUnreadable, isTrue);
      expect(s3.totalCompleted, 0);
      s3.completeLesson(lesson, 10);
      await s3.pendingSave;
      expect((await store.getAll())['flutter.completed'], isEmpty);

      // d) Nouvelle tentative qui réussit : clé retirée seulement maintenant.
      store.failIf = null;
      expect(await s3.resetProgress(), isTrue);
      final done = await store.getAll();
      expect(done['flutter.xp'], 0);
      expect(done['flutter.completed'], isEmpty);
      expect(done.containsKey('flutter.progress_reset_pending'), isFalse);
      expect(done['flutter.progress_backup_1'], original);
      expect(done.containsKey('flutter.progress_backup_3'), isTrue);
      expect(s3.progressUnreadable, isFalse);
      expect((await restart(env)).progressUnreadable, isFalse);
    });

    test('2e tentative refusée avant toute écriture : clé témoin inchangée', () async {
      final store = FakeStore(healthy);
      final env = await firstPartialFailure(store);
      final s2 = await restart(env);
      store.failIf = null;
      store.failKeys.add('progress_backup'); // la nouvelle copie échoue

      expect(await s2.resetProgress(), isFalse);
      final all = await store.getAll();
      expect(all['flutter.progress_reset_pending'], 'progress_backup_1');
      expect(s2.progressUnreadable, isTrue);
    });

    test('zéros confirmés mais retrait de la clé impossible : jamais déclaré sain', () async {
      final store = FakeStore(healthy)..failRemoveKeys.add('progress_reset_pending');
      final env = await startWith(store);

      expect(await env.state.resetProgress(), isFalse);

      final all = await store.getAll();
      expect(all['flutter.progress_reset_pending'], 'progress_backup_1');
      expect(all['flutter.xp'], 40); // restauration relue à l'identique
      expect(env.state.progressUnreadable, isTrue);
      expect((await restart(env)).progressUnreadable, isTrue);
    });

    test('présence de la clé témoin indéterminable : progression non saine', () async {
      final store = FakeStore(healthy);
      final env = await startWith(store);
      // La clé témoin s'écrit, puis le stockage devient illisible.
      store.afterWrite = (k, v) {
        if (k == 'progress_reset_pending') store.readsFail = true;
      };

      expect(await env.state.resetProgress(), isFalse);
      expect(env.state.progressUnreadable, isTrue);

      // Aucune écriture de progression pendant cette session.
      store.log.clear();
      env.state.completeLesson(lesson, 10);
      await env.state.pendingSave;
      expect(store.log.any((l) => l.startsWith('start completed=') || l.startsWith('start xp=')), isFalse);

      store.readsFail = false;
      final all = await store.getAll();
      expect(all['flutter.completed'], ['poulet-chair:1', 'poulet-chair:2']);
      expect(all['flutter.xp'], 40);
    });
  });
}

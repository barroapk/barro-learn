import 'package:barro_learn/data/poultry_course.dart';
import 'package:barro_learn/state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Env {
  Env(this.state, this.prefs);
  final AppState state;
  final SharedPreferences prefs;

  /// Attend la fin de la file, puis relit le stockage lui-même (pas le cache).
  Future<void> settle() async {
    await state.pendingSave;
    await prefs.reload();
  }
}

Future<Env> start(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  final state = AppState.forTesting(); // objet neuf : aucun état partagé entre tests
  await state.load();
  return Env(state, await SharedPreferences.getInstance());
}

void main() {
  final lesson = poultryCourse.allLessons.last; // leçon 15 : jamais déjà faite ici

  test('première installation : la progression est enregistrée', () async {
    final env = await start({});
    env.state.completeLesson(lesson, 10);
    await env.settle();
    expect(env.prefs.getStringList('completed'), contains('poulet-chair:${lesson.number}'));
    expect(env.state.saveFailed, isFalse);
  });

  test('chargement normal : rien n\'est perdu à la sauvegarde', () async {
    final env = await start({
      'completed': ['poulet-chair:1', 'boutique:3'],
      'xp': 40,
    });
    env.state.completeLesson(lesson, 10);
    await env.settle();
    expect(env.prefs.getStringList('completed'), containsAll(['poulet-chair:1', 'boutique:3']));
    expect(env.prefs.getInt('xp'), 50);
  });

  test('ancien format N : converti, puis écrit au format courseId:N', () async {
    final env = await start({'completed': ['1', '2']});
    env.state.setName('Awa');
    await env.settle();
    expect(env.prefs.getStringList('completed')!.toSet(), {'poulet-chair:1', 'poulet-chair:2'});
  });

  test('cours inconnus : les entrées ne sont jamais supprimées', () async {
    final env = await start({'completed': ['inconnu:4', 'poulet-chair:1']});
    env.state.setName('Awa');
    await env.settle();
    expect(env.prefs.getStringList('completed'), contains('inconnu:4'));
  });

  test('progression illisible : aucune écriture de progression', () async {
    final env = await start({
      'completed': ['poulet-chair:1', 'poulet-chair:2'],
      'xp': 'pas un nombre',
    });
    // Précondition : l'erreur de lecture se produit réellement.
    expect(() => env.prefs.getInt('xp'), throwsA(anything));
    expect(env.state.progressUnreadable, isTrue);

    env.state.setName('Nouveau');
    env.state.completeLesson(lesson, 10);
    await env.settle();

    expect(env.prefs.getStringList('completed'), ['poulet-chair:1', 'poulet-chair:2']);
    expect(env.prefs.get('xp'), 'pas un nombre');
    expect(env.prefs.getString('name'), 'Nouveau'); // les réglages restent sauvegardés
  });

  test('réglage illisible : la progression se sauvegarde, le réglage n\'est pas écrasé', () async {
    final env = await start({'completed': ['poulet-chair:1'], 'textScale': 'abc'});
    expect(() => env.prefs.getDouble('textScale'), throwsA(anything));

    env.state.completeLesson(lesson, 10);
    await env.settle();

    expect(env.prefs.getStringList('completed'), contains('poulet-chair:${lesson.number}'));
    expect(env.prefs.get('textScale'), 'abc');
  });

  test('courseId inconnu : conservé tant que l\'utilisateur ne choisit pas', () async {
    final env = await start({'courseId': 'cours-futur', 'completed': ['poulet-chair:1']});
    env.state.setName('Awa');
    await env.settle();
    expect(env.prefs.getString('courseId'), 'cours-futur');

    env.state.openCourse('maraichage'); // choix explicite
    await env.settle();
    expect(env.prefs.getString('courseId'), 'maraichage');
  });

  test('cours boutique : reconnu et conservé', () async {
    final env = await start({'courseId': 'boutique', 'completed': ['boutique:2']});
    expect(env.state.courseId, 'boutique');
    env.state.setName('Awa');
    await env.settle();
    expect(env.prefs.getString('courseId'), 'boutique');
    expect(env.prefs.getStringList('completed'), contains('boutique:2'));
  });

  test('clé témoin présente : progression jamais considérée saine ni réécrite', () async {
    final env = await start({
      'completed': ['poulet-chair:1'],
      'xp': 5,
      'progress_reset_pending': 'progress_backup_1',
    });
    expect(env.state.progressUnreadable, isTrue);
    expect(env.state.totalCompleted, 0);

    env.state.completeLesson(lesson, 10);
    await env.settle();

    expect(env.prefs.getStringList('completed'), ['poulet-chair:1']);
    expect(env.prefs.getInt('xp'), 5);
  });
}

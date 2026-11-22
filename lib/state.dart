import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/course.dart';
import 'data/boutique_course.dart';
import 'data/maraichage_course.dart';
import 'data/poultry_course.dart';

/// Les fonds d'écran proposés dans les paramètres.
enum BackgroundStyle { blanc, feuillage, points }

extension BackgroundStyleLabel on BackgroundStyle {
  String get label {
    switch (this) {
      case BackgroundStyle.blanc:
        return 'Blanc';
      case BackgroundStyle.feuillage:
        return 'Feuillage';
      case BackgroundStyle.points:
        return 'Points';
    }
  }
}

/// Les parcours disponibles, par identifiant de métier (voir catalog.dart).
const Map<String, Course> allCourses = {
  'poulet-chair': poultryCourse,
  'maraichage': maraichageCourse,
  'boutique': boutiqueCourse,
};

/// Progression et réglages de l'apprenant, sauvegardés sur le téléphone.
class AppState extends ChangeNotifier {
  AppState._();
  static final AppState instance = AppState._();

  /// Objet neuf pour les tests (pas de singleton partagé).
  @visibleForTesting
  AppState.forTesting();

  static const xpPerLevel = 300;
  static const _progressKeys = ['completed', 'xp', 'streak', 'lastDay'];
  static const _resetPendingKey = 'progress_reset_pending';

  SharedPreferences? _prefs;

  final Set<String> _completed = {};
  String courseId = 'poulet-chair';
  int xp = 0;
  int streak = 0;
  String _lastDay = '';

  String learnerName = '';
  BackgroundStyle background = BackgroundStyle.blanc;
  double textScale = 1.0;
  bool dataSaver = false;
  bool dailyReminder = false;

  // Protection : un groupe n'est écrit que s'il a été lu sans erreur.
  bool _progressOk = false;
  bool _settingsOk = false;
  bool _writeCourseId = true;

  // File d'attente : sauvegardes et réinitialisations, une par une.
  Future<void> _queue = Future<void>.value();
  bool _flushWaiting = false;

  /// Vrai si la dernière écriture a échoué.
  bool saveFailed = false;

  /// Vrai si la progression du téléphone n'est pas considérée comme saine.
  bool get progressUnreadable => _prefs != null && !_progressOk;

  /// Fin de tout ce qui est déjà demandé dans la file.
  @visibleForTesting
  Future<void> get pendingSave => _queue;

  Course get course => allCourses[courseId] ?? poultryCourse;

  String _key(int n, [String? id]) => '${id ?? courseId}:$n';

  /// Choisit le parcours affiché partout dans l'app.
  void openCourse(String id) {
    if (!allCourses.containsKey(id)) return;
    if (id == courseId && _writeCourseId) return;
    courseId = id;
    _writeCourseId = true;
    _save();
    notifyListeners();
  }

  Future<void> load() async {
    final SharedPreferences p;
    try {
      p = await SharedPreferences.getInstance();
    } catch (_) {
      return; // pas de stockage : l'app marche en mémoire, rien n'est écrit
    }

    // Progression : tout est lu dans des variables locales avant d'être appliqué.
    try {
      if (p.containsKey(_resetPendingKey)) {
        throw StateError('remise à zéro inachevée');
      }
      final completed = (p.getStringList('completed') ?? const <String>[])
          .map((e) => e.contains(':') ? e : 'poulet-chair:$e')
          .toList();
      final x = p.getInt('xp') ?? 0;
      var s = p.getInt('streak') ?? 0;
      final d = p.getString('lastDay') ?? '';
      // Une série s'arrête si on a sauté un jour.
      if (d.isNotEmpty && d != _today() && d != _yesterday()) s = 0;
      _completed
        ..clear()
        ..addAll(completed);
      xp = x;
      streak = s;
      _lastDay = d;
      _progressOk = true;
    } catch (_) {
      _progressOk = false;
    }

    // Réglages
    try {
      final saved = p.getString('courseId');
      final name = p.getString('name') ?? '';
      final bg = p.getString('background');
      final ts = p.getDouble('textScale') ?? 1.0;
      final ds = p.getBool('dataSaver') ?? false;
      final dr = p.getBool('dailyReminder') ?? false;
      if (saved != null) {
        if (allCourses.containsKey(saved)) {
          courseId = saved;
        } else {
          _writeCourseId = false; // cours inconnu : on ne l'écrase pas
        }
      }
      learnerName = name;
      background = BackgroundStyle.values.firstWhere((b) => b.name == bg, orElse: () => BackgroundStyle.blanc);
      textScale = ts;
      dataSaver = ds;
      dailyReminder = dr;
      _settingsOk = true;
    } catch (_) {
      _settingsOk = false;
    }

    _prefs = p;
  }

  Future<T> _enqueue<T>(Future<T> Function() job) {
    final completer = Completer<T>();
    _queue = _queue.then((_) async {
      try {
        completer.complete(await job());
      } catch (e, s) {
        completer.completeError(e, s);
      }
    });
    return completer.future;
  }

  void _save() {
    if (_prefs == null || _flushWaiting) return;
    _flushWaiting = true;
    unawaited(_enqueue<bool>(() async {
      // Dès ce moment, tout nouveau changement déclenche un nouveau passage.
      _flushWaiting = false;
      return _flush();
    }).catchError((_) => false));
  }

  /// Écrit l'état actuel (photo prise maintenant), clé après clé.
  Future<bool> _flush() async {
    final p = _prefs;
    if (p == null) return true;
    final values = <String, Object>{};
    if (_progressOk) {
      values['completed'] = _completed.toList();
      values['xp'] = xp;
      values['streak'] = streak;
      values['lastDay'] = _lastDay;
    }
    if (_settingsOk) {
      if (_writeCourseId) values['courseId'] = courseId;
      values['name'] = learnerName;
      values['background'] = background.name;
      values['textScale'] = textScale;
      values['dataSaver'] = dataSaver;
      values['dailyReminder'] = dailyReminder;
    }
    var ok = true;
    try {
      for (final e in values.entries) {
        if (!await _set(p, e.key, e.value)) ok = false;
      }
    } catch (_) {
      ok = false;
    }
    saveFailed = !ok;
    return ok;
  }

  Future<bool> _set(SharedPreferences p, String key, Object value) {
    if (value is List) return p.setStringList(key, List<String>.from(value));
    if (value is int) return p.setInt(key, value);
    if (value is double) return p.setDouble(key, value);
    if (value is bool) return p.setBool(key, value);
    return p.setString(key, value as String);
  }

  static String _dayKey(DateTime d) => '${d.year}-${d.month}-${d.day}';
  static String _today() => _dayKey(DateTime.now());
  static String _yesterday() => _dayKey(DateTime.now().subtract(const Duration(days: 1)));

  // --- Progression ---

  int get totalCompleted => _completed.length;
  int get completedCount => _completed.where((k) => k.startsWith('$courseId:')).length;
  bool isCompletedIn(String id, int n) => _completed.contains(_key(n, id));
  bool isUnlockedIn(String id, int n) => n == 1 || _completed.contains(_key(n - 1, id));
  bool isCompleted(int lessonNumber) => _completed.contains(_key(lessonNumber));
  bool isUnlocked(int lessonNumber) => lessonNumber == 1 || _completed.contains(_key(lessonNumber - 1));

  Lesson? get nextLesson {
    for (final lesson in course.allLessons) {
      if (!_completed.contains(_key(lesson.number))) return lesson;
    }
    return null;
  }

  Lesson? lessonAfter(Lesson lesson) {
    final all = course.allLessons;
    final i = all.indexWhere((l) => l.number == lesson.number);
    return (i >= 0 && i < all.length - 1) ? all[i + 1] : null;
  }

  CourseModule moduleOf(Lesson lesson) =>
      course.modules.firstWhere((m) => m.lessons.any((l) => l.number == lesson.number));

  bool get allDone => completedCount >= course.lessonCount;

  int completedIn(CourseModule module) => module.lessons.where((l) => _completed.contains(_key(l.number))).length;

  double get courseProgress => course.lessonCount == 0 ? 0 : completedCount / course.lessonCount;
  int get level => xp ~/ xpPerLevel + 1;
  int get xpInLevel => xp % xpPerLevel;

  void completeLesson(Lesson lesson, int earnedXp) {
    final isNew = _completed.add(_key(lesson.number));
    if (isNew) xp += earnedXp;
    final today = _today();
    if (_lastDay != today) {
      streak = _lastDay == _yesterday() ? streak + 1 : 1;
      _lastDay = today;
    }
    _save();
    notifyListeners();
  }

  // --- Réinitialisation sécurisée ---

  /// Réinitialise la progression. Renvoie true seulement si les zéros ont été
  /// relus depuis le stockage et la clé témoin retirée (confirmé par relecture).
  Future<bool> resetProgress() => _enqueue<bool>(_resetJob);

  static const Map<String, Object?> _zeroValues = {
    'completed': <String>[],
    'xp': 0,
    'streak': 0,
    'lastDay': '',
  };

  void _zeroMemory() {
    _completed.clear();
    xp = 0;
    streak = 0;
    _lastDay = '';
  }

  /// Progression non saine pour cette session : rien n'est plus écrit
  /// pour la progression, et la mémoire repart des valeurs par défaut.
  void _markUnhealthy() {
    _zeroMemory();
    _progressOk = false;
    notifyListeners();
  }

  Future<bool> _resetJob() async {
    final p = _prefs;
    if (p == null) {
      _zeroMemory(); // pas de stockage : réinitialisation en mémoire seulement
      notifyListeners();
      return true;
    }

    // 1. Lire le disque lui-même : progression ET clé témoin éventuelle.
    final Map<String, Object?> raw;
    final Object? existingMarker;
    try {
      await p.reload();
      raw = {for (final k in _progressKeys) k: p.get(k)};
      existingMarker = p.get(_resetPendingKey);
    } catch (_) {
      return false; // rien n'a été touché
    }
    final hadMarker = existingMarker != null;

    // 2. Nouvelle copie confirmée (les copies existantes ne sont jamais écrasées).
    final backupKey = await _backupRawProgress(p, raw);
    if (backupKey == null) return false;

    // 3. Clé témoin : réutilisée telle quelle si elle existe, sinon écrite et confirmée.
    final Object marker = existingMarker ?? backupKey;
    if (!hadMarker && !await _setConfirmed(p, _resetPendingKey, backupKey)) {
      // Présence incertaine : on ne reste "sain" que si son absence est confirmée.
      if (!await _removeConfirmed(p, _resetPendingKey)) _markUnhealthy();
      return false;
    }

    // 4. Zéros écrits et relus ; la clé témoin n'est retirée qu'ensuite.
    if (await _writeAndVerify(p, _zeroValues) && await _removeConfirmed(p, _resetPendingKey)) {
      _zeroMemory();
      _progressOk = true;
      saveFailed = false;
      notifyListeners();
      return true;
    }

    // 5. Échec.
    saveFailed = true;
    final restored = await _writeAndVerify(p, raw);

    // Seul cas où la clé peut disparaître : créée par CETTE tentative,
    // progression d'origine relue à l'identique, absence de la clé confirmée.
    if (!hadMarker && restored && await _removeConfirmed(p, _resetPendingKey)) {
      try {
        await p.reload();
      } catch (_) {}
      return false; // mémoire jamais modifiée, _progressOk inchangé
    }

    // Tous les autres cas : la clé témoin reste, avec sa valeur d'origine.
    await _writeAndVerify(p, {_resetPendingKey: marker});
    _markUnhealthy();
    try {
      await p.reload(); // cache = disque
    } catch (_) {}
    return false;
  }

  /// Écrit chaque valeur (null = clé absente), relit le stockage et compare.
  /// Seule la relecture décide du résultat.
  Future<bool> _writeAndVerify(SharedPreferences p, Map<String, Object?> values) async {
    for (final e in values.entries) {
      try {
        final v = e.value;
        if (v == null) {
          await p.remove(e.key);
        } else {
          await _set(p, e.key, v);
        }
      } catch (_) {}
    }
    try {
      await p.reload();
      for (final e in values.entries) {
        final ok = e.value == null ? !p.containsKey(e.key) : _same(p.get(e.key), e.value);
        if (!ok) return false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  static bool _same(Object? a, Object? b) {
    if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (var i = 0; i < a.length; i++) {
        if (a[i] != b[i]) return false;
      }
      return true;
    }
    if (a is double && b is double && a.isNaN && b.isNaN) return true;
    return a == b;
  }

  /// Copie sous la première clé libre progress_backup_N, confirmée par relecture.
  /// Renvoie la clé utilisée, ou null. Jamais d'écrasement.
  Future<String?> _backupRawProgress(SharedPreferences p, Map<String, Object?> raw) async {
    try {
      final json = jsonEncode(raw);
      for (var n = 1; n <= 1000; n++) {
        final key = 'progress_backup_$n';
        if (p.containsKey(key)) continue;
        return await _setConfirmed(p, key, json) ? key : null;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> _setConfirmed(SharedPreferences p, String key, String value) async {
    try {
      await p.setString(key, value);
      await p.reload();
      return p.getString(key) == value;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _removeConfirmed(SharedPreferences p, String key) async {
    try {
      await p.remove(key);
      await p.reload();
      return !p.containsKey(key);
    } catch (_) {
      return false;
    }
  }

  // --- Réglages ---

  void setName(String value) {
    learnerName = value.trim();
    _save();
    notifyListeners();
  }

  void setBackground(BackgroundStyle value) {
    background = value;
    _save();
    notifyListeners();
  }

  void setTextScale(double value) {
    textScale = value;
    _save();
    notifyListeners();
  }

  void setDataSaver(bool value) {
    dataSaver = value;
    _save();
    notifyListeners();
  }

  void setDailyReminder(bool value) {
    dailyReminder = value;
    _save();
    notifyListeners();
  }
}

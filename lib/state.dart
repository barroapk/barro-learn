import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/course.dart';
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
};

/// Progression et réglages de l'apprenant, sauvegardés sur le téléphone.
class AppState extends ChangeNotifier {
  AppState._();
  static final AppState instance = AppState._();

  static const xpPerLevel = 300;

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

  Course get course => allCourses[courseId] ?? poultryCourse;

  String _key(int n, [String? id]) => '${id ?? courseId}:$n';

  /// Choisit le parcours affiché partout dans l'app.
  void openCourse(String id) {
    if (!allCourses.containsKey(id) || id == courseId) return;
    courseId = id;
    _save();
    notifyListeners();
  }

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      _prefs = p;
      _completed
        ..clear()
        ..addAll((p.getStringList('completed') ?? const []).map((e) => e.contains(':') ? e : 'poulet-chair:$e'));
      final saved = p.getString('courseId');
      if (saved != null && allCourses.containsKey(saved)) courseId = saved;
      xp = p.getInt('xp') ?? 0;
      streak = p.getInt('streak') ?? 0;
      _lastDay = p.getString('lastDay') ?? '';
      learnerName = p.getString('name') ?? '';
      final bg = p.getString('background');
      background = BackgroundStyle.values.firstWhere((b) => b.name == bg, orElse: () => BackgroundStyle.blanc);
      textScale = p.getDouble('textScale') ?? 1.0;
      dataSaver = p.getBool('dataSaver') ?? false;
      dailyReminder = p.getBool('dailyReminder') ?? false;
      // Une série s'arrête si on a sauté un jour.
      if (_lastDay.isNotEmpty && _lastDay != _today() && _lastDay != _yesterday()) {
        streak = 0;
      }
    } catch (_) {
      // Sans stockage, l'app marche quand même : la progression reste en mémoire.
    }
  }

  void _save() {
    final p = _prefs;
    if (p == null) return;
    p.setStringList('completed', _completed.toList());
    p.setString('courseId', courseId);
    p.setInt('xp', xp);
    p.setInt('streak', streak);
    p.setString('lastDay', _lastDay);
    p.setString('name', learnerName);
    p.setString('background', background.name);
    p.setDouble('textScale', textScale);
    p.setBool('dataSaver', dataSaver);
    p.setBool('dailyReminder', dailyReminder);
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

  void resetProgress() {
    _completed.clear();
    xp = 0;
    streak = 0;
    _lastDay = '';
    _save();
    notifyListeners();
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

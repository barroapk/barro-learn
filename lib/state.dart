import 'package:flutter/foundation.dart';

import 'data/course.dart';
import 'data/poultry_course.dart';

/// Progression de l'apprenant. En phase 4, elle sera sauvegardée sur le téléphone et dans Supabase.
class AppState extends ChangeNotifier {
  AppState._();
  static final AppState instance = AppState._();

  static const xpPerLevel = 300;

  final Set<int> _completed = {};
  int xp = 0;
  int streak = 1;

  Course get course => poultryCourse;

  int get completedCount => _completed.length;
  bool isCompleted(int lessonNumber) => _completed.contains(lessonNumber);

  /// Une leçon s'ouvre quand la précédente est terminée.
  bool isUnlocked(int lessonNumber) => lessonNumber == 1 || _completed.contains(lessonNumber - 1);

  Lesson? get nextLesson {
    for (final lesson in course.allLessons) {
      if (!_completed.contains(lesson.number)) return lesson;
    }
    return null;
  }

  double get courseProgress => course.lessonCount == 0 ? 0 : completedCount / course.lessonCount;

  int get level => xp ~/ xpPerLevel + 1;
  int get xpInLevel => xp % xpPerLevel;

  void completeLesson(Lesson lesson, int earnedXp) {
    if (_completed.add(lesson.number)) {
      xp += earnedXp;
      notifyListeners();
    }
  }
}

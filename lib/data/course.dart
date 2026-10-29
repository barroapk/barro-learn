/// Les modèles du contenu : un parcours contient des modules, un module des leçons.
/// En phase 2, ces données viendront de Supabase.
library;

class QuizQuestion {
  final String question;
  final List<String> options;
  final int answer; // position de la bonne réponse dans [options]

  const QuizQuestion(this.question, this.options, this.answer);
}

class Lesson {
  final int number;
  final String title;
  final int minutes;
  final String hook;
  final String? videoUrl;
  final List<String> essentials;
  final String task;
  final List<QuizQuestion> quiz;

  const Lesson({
    required this.number,
    required this.title,
    required this.minutes,
    required this.hook,
    this.videoUrl,
    required this.essentials,
    required this.task,
    required this.quiz,
  });
}

class CourseModule {
  final int number;
  final String title;
  final String goal;
  final List<Lesson> lessons;
  final String exercise;

  const CourseModule({
    required this.number,
    required this.title,
    required this.goal,
    required this.lessons,
    required this.exercise,
  });
}

class Course {
  final String title;
  final String universe;
  final String level;
  final String summary;
  final List<CourseModule> modules;

  const Course({
    required this.title,
    required this.universe,
    required this.level,
    required this.summary,
    required this.modules,
  });

  List<Lesson> get allLessons => [for (final m in modules) ...m.lessons];
  int get lessonCount => allLessons.length;
}

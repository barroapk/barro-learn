import 'package:flutter_test/flutter_test.dart';

import 'package:barro_learn/data/poultry_course.dart';

void main() {
  test('Le parcours poulet contient 15 leçons avec 3 questions chacune', () {
    expect(poultryCourse.lessonCount, 15);
    for (final lesson in poultryCourse.allLessons) {
      expect(lesson.essentials.length, 3, reason: 'Leçon ${lesson.number}');
      expect(lesson.quiz.length, 3, reason: 'Leçon ${lesson.number}');
      for (final q in lesson.quiz) {
        expect(q.answer, inInclusiveRange(0, q.options.length - 1), reason: q.question);
      }
    }
  });
}

import 'package:flutter/material.dart';

import '../data/course.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/illustrations.dart';
import 'lesson_screen.dart';
import 'search_screen.dart';

/// Le parcours : couverture, modules dépliables et bouton « Continuer » fixe en bas.
class CourseScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const CourseScreen({super.key, this.onBack});

  @override
  State<CourseScreen> createState() => _CourseScreenState();
}

class _CourseScreenState extends State<CourseScreen> {
  int? _open; // module ouvert ; null = celui en cours ; -1 = aucun

  void _openLesson(Lesson lesson) => Navigator.of(context).push(barroRoute(LessonScreen(lesson: lesson)));

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    return Column(
      children: [
        TabHeader(
          onBack: widget.onBack,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Mon parcours', style: display(22)),
              Text('${state.course.universe} · ${state.course.level}', style: body(12, color: BarroColors.muted)),
            ],
          ),
          actions: [
            RoundIconButton(
              icon: Icons.search,
              tooltip: 'Rechercher une leçon',
              onPressed: () => Navigator.of(context).push(barroRoute(const SearchScreen())),
            ),
          ],
        ),
        Expanded(
          child: ListenableBuilder(
            listenable: state,
            builder: (context, _) {
              final course = state.course;
              final next = state.nextLesson;
              final current = next == null ? null : state.moduleOf(next).number;
              final openNumber = _open ?? current ?? -1;
              final pct = (state.courseProgress * 100).round();
              return Stack(
                children: [
                  ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 112),
                    children: [
                      FadeSlideIn(child: _Cover(level: course.level)),
                      const SizedBox(height: 18),
                      FadeSlideIn(
                        index: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(course.title, style: display(27)),
                            const SizedBox(height: 6),
                            Text('Du poussin d\'un jour à la vente, en 6 semaines environ.',
                                style: body(14, color: BarroColors.muted)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      FadeSlideIn(index: 2, child: _Facts(lessons: course.lessonCount, exercises: course.modules.length)),
                      const SizedBox(height: 16),
                      FadeSlideIn(
                        index: 3,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Text('Ta progression', style: body(14, weight: FontWeight.w700)),
                                const Spacer(),
                                Text('$pct %', style: body(14, color: BarroColors.greenText, weight: FontWeight.w800)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            BarroProgressBar(value: state.courseProgress, height: 8),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      for (var i = 0; i < course.modules.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: FadeSlideIn(
                            index: 4 + i,
                            child: _ModuleCard(
                              module: course.modules[i],
                              open: openNumber == course.modules[i].number,
                              onToggle: () => setState(() {
                                final n = course.modules[i].number;
                                _open = openNumber == n ? -1 : n;
                              }),
                              onOpenLesson: _openLesson,
                            ),
                          ),
                        ),
                      const SizedBox(height: 6),
                      _ExamCard(unlocked: state.allDone),
                    ],
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(top: BorderSide(color: BarroColors.line)),
                      ),
                      child: PrimaryButton(
                        icon: Icons.play_arrow_rounded,
                        label: next == null
                            ? 'Revoir la leçon 1'
                            : state.completedCount == 0
                                ? 'Commencer · Leçon 1'
                                : 'Continuer · Leçon ${next.number}',
                        onPressed: () => _openLesson(next ?? course.allLessons.first),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Cover extends StatelessWidget {
  final String level;

  const _Cover({required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 228,
      decoration: BoxDecoration(color: BarroColors.greenSoft, borderRadius: BorderRadius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const HenScene(height: 228, prop: SceneProp.sun),
          Positioned(
            top: 16,
            left: 16,
            child: Row(
              children: [
                Pill(label: level, background: Colors.white, foreground: BarroColors.greenText),
                const SizedBox(width: 6),
                const Pill(
                  label: 'Sources vérifiées',
                  background: Colors.white,
                  foreground: BarroColors.ink,
                  icon: Icons.verified_user_outlined,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Facts extends StatelessWidget {
  final int lessons;
  final int exercises;

  const _Facts({required this.lessons, required this.exercises});

  @override
  Widget build(BuildContext context) {
    Widget fact(String value, String label, {bool first = false}) => Expanded(
          child: Container(
            padding: EdgeInsets.only(left: first ? 0 : 14),
            decoration: BoxDecoration(
              border: first ? null : const Border(left: BorderSide(color: BarroColors.line)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: display(19)),
                Text(label, style: body(12, color: BarroColors.muted)),
              ],
            ),
          ),
        );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: BarroColors.line),
          bottom: BorderSide(color: BarroColors.line),
        ),
      ),
      child: Row(
        children: [
          fact('$lessons', 'leçons', first: true),
          fact('$exercises', 'exercices pratiques'),
          fact('1', 'attestation'),
        ],
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final CourseModule module;
  final bool open;
  final VoidCallback onToggle;
  final ValueChanged<Lesson> onOpenLesson;

  const _ModuleCard({required this.module, required this.open, required this.onToggle, required this.onOpenLesson});

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    final done = state.completedIn(module);
    final total = module.lessons.length;
    final unlocked = state.isUnlocked(module.lessons.first.number);
    final complete = done == total;

    final Widget badge;
    if (complete) {
      badge = const CircleAvatar(
        radius: 17,
        backgroundColor: BarroColors.green,
        child: Icon(Icons.check, size: 18, color: Colors.white),
      );
    } else if (unlocked) {
      badge = CircleAvatar(
        radius: 17,
        backgroundColor: BarroColors.green,
        child: Text('${module.number}', style: display(14, color: Colors.white)),
      );
    } else {
      badge = Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: BarroColors.line, width: 2)),
        child: Text('${module.number}', style: display(14, color: BarroColors.muted)),
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: open ? BarroColors.soft : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: open ? BarroColors.soft : BarroColors.line),
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    badge,
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(module.title, style: body(15, weight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          if (complete)
                            Text('Terminé · $total leçons', style: body(12, color: BarroColors.greenText, weight: FontWeight.w700))
                          else if (unlocked)
                            Row(
                              children: [
                                SizedBox(width: 72, child: BarroProgressBar(value: done / total, height: 5)),
                                const SizedBox(width: 8),
                                Text('$done sur $total leçons', style: body(12, color: BarroColors.muted)),
                              ],
                            )
                          else
                            Text('$total leçons', style: body(12, color: BarroColors.muted)),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: open && unlocked ? 0.5 : 0,
                      duration: const Duration(milliseconds: 250),
                      child: Icon(unlocked ? Icons.expand_more : Icons.lock_outline, color: BarroColors.faint),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: open
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                    child: Column(
                      children: [
                        for (final l in module.lessons) _LessonRow(lesson: l, onOpen: onOpenLesson),
                        _ExerciseRow(module: module, unlocked: complete),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _LessonRow extends StatelessWidget {
  final Lesson lesson;
  final ValueChanged<Lesson> onOpen;

  const _LessonRow({required this.lesson, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    final done = state.isCompleted(lesson.number);
    final unlocked = state.isUnlocked(lesson.number);
    final current = unlocked && !done;

    final Widget icon;
    if (done) {
      icon = const CircleAvatar(
        radius: 14,
        backgroundColor: BarroColors.greenSoft,
        child: Icon(Icons.check, size: 16, color: BarroColors.greenText),
      );
    } else if (current) {
      icon = const CircleAvatar(
        radius: 14,
        backgroundColor: BarroColors.green,
        child: Icon(Icons.play_arrow_rounded, size: 18, color: Colors.white),
      );
    } else {
      icon = const CircleAvatar(
        radius: 14,
        backgroundColor: BarroColors.soft,
        child: Icon(Icons.lock_outline, size: 14, color: BarroColors.faint),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            if (unlocked) {
              onOpen(lesson);
            } else {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(const SnackBar(content: Text('Termine la leçon précédente pour ouvrir celle-ci.')));
            }
          },
          child: Container(
            constraints: const BoxConstraints(minHeight: 54),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: current ? Border.all(color: BarroColors.green, width: 1.5) : null,
            ),
            child: Row(
              children: [
                icon,
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lesson.title,
                        style: body(14,
                            color: unlocked ? BarroColors.ink : BarroColors.muted,
                            weight: current ? FontWeight.w800 : FontWeight.w600,
                            height: 1.25),
                      ),
                      Text('Leçon ${lesson.number} · ${lesson.minutes} min', style: body(12, color: BarroColors.muted)),
                    ],
                  ),
                ),
                if (current) Text('À faire', style: body(12, color: BarroColors.greenText, weight: FontWeight.w800)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  final CourseModule module;
  final bool unlocked;

  const _ExerciseRow({required this.module, required this.unlocked});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 54),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: unlocked ? BarroColors.orangeSoft : Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: unlocked ? BarroColors.orange : BarroColors.soft,
            child: Icon(Icons.handyman_outlined, size: 15, color: unlocked ? Colors.white : BarroColors.faint),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text('Exercice pratique : ${module.exercise}',
                style: body(14, weight: FontWeight.w700, color: unlocked ? BarroColors.ink : BarroColors.muted)),
          ),
          Text(unlocked ? '+100 XP' : 'Fin du module',
              style: body(12, color: unlocked ? BarroColors.orangeText : BarroColors.faint, weight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _ExamCard extends StatelessWidget {
  final bool unlocked;

  const _ExamCard({required this.unlocked});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: unlocked ? BarroColors.greenDeep : BarroColors.soft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(Icons.workspace_premium_outlined, size: 30, color: unlocked ? BarroColors.sun : BarroColors.faint),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Examen final et attestation',
                    style: body(15, color: unlocked ? Colors.white : BarroColors.ink, weight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text('20 questions · 70 % pour réussir',
                    style: body(12, color: unlocked ? BarroColors.greenMid : BarroColors.muted)),
              ],
            ),
          ),
          if (!unlocked) const Icon(Icons.lock_outline, color: BarroColors.faint),
        ],
      ),
    );
  }
}

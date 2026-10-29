import 'package:flutter/material.dart';

import '../data/course.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'lesson_screen.dart';

/// Onglet « Apprendre » : le parcours, ses modules et ses leçons.
class CourseScreen extends StatelessWidget {
  const CourseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final course = state.course;
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Text('${course.universe} · Mon parcours', style: body(13, color: BarroColors.muted, weight: FontWeight.w600)),
            const SizedBox(height: 12),
            _Hero(course: course, progress: state.courseProgress),
            for (final module in course.modules) ...[
              const SizedBox(height: 24),
              Text('Module ${module.number} · ${module.title}', style: display(18, weight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(module.goal, style: body(13, color: BarroColors.muted)),
              const SizedBox(height: 12),
              for (final lesson in module.lessons) _LessonTile(lesson: lesson),
              _ExerciseTile(title: 'Exercice pratique : ${module.exercise}', module: module),
            ],
            const SizedBox(height: 16),
            _ExamTile(unlocked: state.completedCount == course.lessonCount),
          ],
        );
      },
    );
  }
}

class _Hero extends StatelessWidget {
  final Course course;
  final double progress;

  const _Hero({required this.course, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: BarroColors.emerald, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Pill(label: course.level, background: BarroColors.green, foreground: BarroColors.ink),
              const Pill(
                label: 'Sources vérifiées',
                background: Colors.white,
                foreground: BarroColors.emerald,
                icon: Icons.verified_user_outlined,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(course.title, style: display(24, color: Colors.white)),
          const SizedBox(height: 6),
          Text(course.summary, style: body(13, color: const Color(0xFFA7F3D0))),
          const SizedBox(height: 14),
          Row(
            children: [
              Text('Ta progression', style: body(13, color: Colors.white, weight: FontWeight.w700)),
              const Spacer(),
              Text('${(progress * 100).round()} %', style: body(13, color: Colors.white, weight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 6),
          BarroProgressBar(value: progress, track: const Color(0xFF04402F)),
        ],
      ),
    );
  }
}

class _LessonTile extends StatelessWidget {
  final Lesson lesson;

  const _LessonTile({required this.lesson});

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    final done = state.isCompleted(lesson.number);
    final unlocked = state.isUnlocked(lesson.number);
    final current = unlocked && !done;

    final Color circle;
    final Color circleIcon;
    final IconData icon;
    if (done) {
      circle = BarroColors.green;
      circleIcon = BarroColors.ink;
      icon = Icons.check_rounded;
    } else if (current) {
      circle = BarroColors.blue;
      circleIcon = BarroColors.ink;
      icon = Icons.play_arrow_rounded;
    } else {
      circle = BarroColors.border;
      circleIcon = BarroColors.muted;
      icon = Icons.lock_outline;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: current ? const Color(0xFF10203F) : (done ? BarroColors.surface : BarroColors.surfaceLow),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: current ? const BorderSide(color: BarroColors.blue, width: 2) : BorderSide.none,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (unlocked) {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => LessonScreen(lesson: lesson)));
            } else {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(const SnackBar(content: Text('Termine la leçon précédente pour ouvrir celle-ci.')));
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                CircleAvatar(radius: 16, backgroundColor: circle, child: Icon(icon, size: 17, color: circleIcon)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lesson.title,
                        style: body(15,
                            color: unlocked ? BarroColors.text : BarroColors.muted,
                            weight: current ? FontWeight.w800 : FontWeight.w600,
                            height: 1.25),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Leçon ${lesson.number} · ${lesson.minutes} min${current ? ' · à faire' : ''}',
                        style: body(12, color: current ? const Color(0xFFBFD5FF) : BarroColors.muted),
                      ),
                    ],
                  ),
                ),
                if (current) const Icon(Icons.chevron_right, color: BarroColors.text),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  final String title;
  final CourseModule module;

  const _ExerciseTile({required this.title, required this.module});

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    final unlocked = module.lessons.every((l) => state.isCompleted(l.number));
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: unlocked ? BarroColors.surface : BarroColors.surfaceLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: unlocked ? BarroColors.orange : BarroColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: unlocked ? BarroColors.orange : BarroColors.border,
            child: Icon(Icons.handyman_outlined, size: 17, color: unlocked ? BarroColors.ink : BarroColors.muted),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title,
                style: body(14, color: unlocked ? BarroColors.text : BarroColors.muted, weight: FontWeight.w700)),
          ),
          Text(unlocked ? '+100 XP' : 'Fin du module', style: body(12, color: BarroColors.muted)),
        ],
      ),
    );
  }
}

class _ExamTile extends StatelessWidget {
  final bool unlocked;

  const _ExamTile({required this.unlocked});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: unlocked ? BarroColors.deepViolet : BarroColors.surfaceLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(Icons.workspace_premium_outlined, size: 32, color: unlocked ? Colors.white : BarroColors.muted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Examen final et attestation',
                    style: body(15, color: unlocked ? Colors.white : BarroColors.muted, weight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text('20 questions · 70 % pour réussir',
                    style: body(12, color: unlocked ? const Color(0xFFE4DBFF) : BarroColors.muted)),
              ],
            ),
          ),
          if (!unlocked) const Icon(Icons.lock_outline, color: BarroColors.muted),
        ],
      ),
    );
  }
}

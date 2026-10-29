import 'package:flutter/material.dart';

import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'lesson_screen.dart';

class HomeScreen extends StatelessWidget {
  final ValueChanged<int> onOpenTab;

  const HomeScreen({super.key, required this.onOpenTab});

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final next = state.nextLesson;
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Row(
              children: [
                Text.rich(TextSpan(children: [
                  TextSpan(text: 'BARRO', style: display(26)),
                  TextSpan(text: '.', style: display(26, color: BarroColors.green)),
                ])),
                const Spacer(),
                SquareIconButton(icon: Icons.search, tooltip: 'Rechercher', onPressed: () => onOpenTab(1)),
                const SizedBox(width: 8),
                SquareIconButton(
                  icon: Icons.notifications_none,
                  tooltip: 'Notifications',
                  onPressed: () => showSoon(context, 'Les notifications'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bonjour', style: body(14, color: BarroColors.muted)),
                      const SizedBox(height: 4),
                      Text('Qu\'apprends-tu\naujourd\'hui ?', style: display(28)),
                    ],
                  ),
                ),
                Pill(
                  label: '${state.streak} jour${state.streak > 1 ? 's' : ''}',
                  background: BarroColors.orange,
                  foreground: BarroColors.ink,
                  icon: Icons.local_fire_department,
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (next != null) _ContinueCard(lessonTitle: next.title, lessonNumber: next.number, minutes: next.minutes),
            if (next == null) _DoneCard(onOpenTab: onOpenTab),
            const SizedBox(height: 24),
            Row(
              children: [
                Text('Univers', style: display(19, weight: FontWeight.w600)),
                const Spacer(),
                TextButton(
                  onPressed: () => onOpenTab(1),
                  child: Text('Tout voir', style: body(13, color: BarroColors.green, weight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _UniverseChip(label: 'Métiers', color: BarroColors.green, onTap: () => onOpenTab(2)),
                  _UniverseChip(label: 'Comment faire', color: BarroColors.blue, onTap: () => onOpenTab(1)),
                  _UniverseChip(label: 'Astuces', color: BarroColors.orange, onTap: () => onOpenTab(1)),
                  _UniverseChip(label: 'Histoire & Géo', color: BarroColors.violet, onTap: () => onOpenTab(1)),
                  _UniverseChip(label: 'Sciences', color: BarroColors.pink, onTap: () => onOpenTab(1)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const _TipCard(),
            const SizedBox(height: 24),
            Text('Vidéos qui ouvrent l\'esprit', style: display(19, weight: FontWeight.w600)),
            const SizedBox(height: 12),
            const Row(
              children: [
                Expanded(
                  child: _VideoTeaser(
                    tag: 'Sciences · bientôt',
                    title: 'Pourquoi le ciel est-il bleu ?',
                    color: Color(0xFF1E40AF),
                    tagColor: Color(0xFFBFD5FF),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _VideoTeaser(
                    tag: 'Histoire · bientôt',
                    title: 'Les grands royaumes du Sahel',
                    color: Color(0xFF6D28D9),
                    tagColor: Color(0xFFE4DBFF),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _ContinueCard extends StatelessWidget {
  final String lessonTitle;
  final int lessonNumber;
  final int minutes;

  const _ContinueCard({required this.lessonTitle, required this.lessonNumber, required this.minutes});

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    final lesson = state.course.allLessons.firstWhere((l) => l.number == lessonNumber);
    return Material(
      color: BarroColors.deepBlue,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => LessonScreen(lesson: lesson))),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(state.completedCount == 0 ? 'COMMENCER' : 'CONTINUER',
                      style: body(12, color: const Color(0xFFDBE6FF), weight: FontWeight.w800)),
                  const Spacer(),
                  Text('Leçon $lessonNumber sur ${state.course.lessonCount}',
                      style: body(12, color: const Color(0xFFDBE6FF))),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.play_arrow_rounded, color: BarroColors.deepBlue, size: 30),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(lessonTitle, style: body(17, color: Colors.white, weight: FontWeight.w800, height: 1.25)),
                        const SizedBox(height: 4),
                        Text('${state.course.title} · $minutes min',
                            style: body(13, color: const Color(0xFFDBE6FF))),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              BarroProgressBar(value: state.courseProgress, color: Colors.white, track: const Color(0xFF1D4FC4)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DoneCard extends StatelessWidget {
  final ValueChanged<int> onOpenTab;

  const _DoneCard({required this.onOpenTab});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: BarroColors.emerald, borderRadius: BorderRadius.circular(22)),
      child: Row(
        children: [
          const Icon(Icons.workspace_premium, color: BarroColors.green, size: 40),
          const SizedBox(width: 14),
          Expanded(
            child: Text('Parcours terminé ! Passe ton examen final dans l\'onglet Progrès.',
                style: body(15, color: Colors.white, weight: FontWeight.w700)),
          ),
          IconButton(
            tooltip: 'Voir mes progrès',
            onPressed: () => onOpenTab(3),
            icon: const Icon(Icons.arrow_forward, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _UniverseChip extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _UniverseChip({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: BarroColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(99),
          side: const BorderSide(color: BarroColors.border),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(99),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text(label, style: body(14, weight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: BarroColors.orange, borderRadius: BorderRadius.circular(22)),
      child: Row(
        children: [
          Container(
            width: 84,
            height: 104,
            decoration: BoxDecoration(color: const Color(0xFFFFB27D), borderRadius: BorderRadius.circular(14)),
            child: const Center(
              child: CircleAvatar(
                radius: 20,
                backgroundColor: BarroColors.ink,
                child: Icon(Icons.play_arrow_rounded, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ASTUCE DU JOUR', style: body(12, color: BarroColors.ink, weight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text('Garder ses tomates fraîches plus longtemps, sans frigo',
                    style: body(16, color: BarroColors.ink, weight: FontWeight.w800, height: 1.3)),
                const SizedBox(height: 6),
                Text('+10 XP · bientôt disponible', style: body(13, color: const Color(0xFF1F2937))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoTeaser extends StatelessWidget {
  final String tag;
  final String title;
  final Color color;
  final Color tagColor;

  const _VideoTeaser({required this.tag, required this.title, required this.color, required this.tagColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 170,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(tag, style: body(12, color: tagColor, weight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(title, style: body(15, color: Colors.white, weight: FontWeight.w800, height: 1.25)),
        ],
      ),
    );
  }
}

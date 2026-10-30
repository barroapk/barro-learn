import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../data/course.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/illustrations.dart';
import 'lesson_screen.dart';
import 'metiers_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  final ValueChanged<int> onOpenTab;

  const HomeScreen({super.key, required this.onOpenTab});

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    return Column(
      children: [
        TabHeader(
          title: Text.rich(TextSpan(children: [
            TextSpan(text: 'BARRO', style: display(21, weight: FontWeight.w800)),
            TextSpan(text: '.', style: display(21, color: BarroColors.green, weight: FontWeight.w800)),
          ])),
          actions: [
            RoundIconButton(
              icon: Icons.search,
              tooltip: 'Rechercher',
              onPressed: () => Navigator.of(context).push(barroRoute(const SearchScreen())),
            ),
            AvatarButton(onPressed: () => Navigator.of(context).push(barroRoute(const SettingsScreen()))),
          ],
        ),
        Expanded(
          child: ListenableBuilder(
            listenable: state,
            builder: (context, _) {
              final greeting = state.learnerName.isEmpty ? 'Bonjour' : 'Bonjour ${state.learnerName}';
              final headline = state.completedCount == 0
                  ? 'Apprends un métier, pas à pas'
                  : state.allDone
                      ? 'Bravo, parcours terminé'
                      : 'Continue ton parcours';
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
                children: [
                  FadeSlideIn(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(greeting, style: body(14, color: BarroColors.muted)),
                        const SizedBox(height: 4),
                        Text(headline, style: display(27)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  FadeSlideIn(index: 1, child: _HeroCard(onOpenTab: onOpenTab)),
                  const SizedBox(height: 14),
                  const FadeSlideIn(index: 2, child: StatsStrip()),
                  const SizedBox(height: 14),
                  FadeSlideIn(index: 3, child: _DailyFact(lessons: state.course.allLessons)),
                  const SizedBox(height: 26),
                  FadeSlideIn(
                    index: 4,
                    child: SectionTitle(
                      'Métiers par catégorie',
                      trailing: TextButton(
                        onPressed: () => Navigator.of(context).push(barroRoute(const MetiersScreen())),
                        child: Text('Tout voir', style: body(13, color: BarroColors.greenText, weight: FontWeight.w800)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  for (var i = 0; i < metierCategories.length; i++)
                    FadeSlideIn(
                      index: 5 + i,
                      child: _CategoryRow(
                        category: metierCategories[i],
                        index: i,
                        last: i == metierCategories.length - 1,
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

class _HeroCard extends StatelessWidget {
  final ValueChanged<int> onOpenTab;

  const _HeroCard({required this.onOpenTab});

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    final next = state.nextLesson;
    if (next == null) {
      return Tap(
        onTap: () => onOpenTab(3),
        semanticLabel: 'Voir mes progrès',
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: BarroColors.greenDeep, borderRadius: BorderRadius.circular(26)),
          child: Row(
            children: [
              const Icon(Icons.workspace_premium, color: Color(0xFFFFE3C7), size: 44),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Parcours terminé', style: display(19, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text('L\'examen final arrive bientôt. Vois tes badges dans Progrès.',
                        style: body(13, color: BarroColors.greenMid)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    final module = state.moduleOf(next);
    final starting = state.completedCount == 0;
    return Tap(
      onTap: () => Navigator.of(context).push(barroRoute(LessonScreen(lesson: next))),
      semanticLabel: '${starting ? 'Commencer' : 'Reprendre'} la leçon ${next.number}',
      child: Container(
        constraints: const BoxConstraints(minHeight: 224),
        decoration: BoxDecoration(color: BarroColors.greenSoft, borderRadius: BorderRadius.circular(26)),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              right: -16,
              bottom: -4,
              width: 190,
              height: 158,
              child: HenScene(height: 158, compact: true, prop: propForModule(module.number)),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Pill(
                    label: 'Leçon ${next.number} sur ${state.course.lessonCount}',
                    background: Colors.white,
                    foreground: BarroColors.greenText,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: 196,
                    child: Text(next.title, maxLines: 3, overflow: TextOverflow.ellipsis, style: display(19, height: 1.22)),
                  ),
                  const SizedBox(height: 4),
                  Text(state.course.title, style: body(13, color: BarroColors.inkSoft)),
                  const SizedBox(height: 16),
                  SizedBox(width: 176, child: BarroProgressBar(value: state.courseProgress)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(color: BarroColors.greenDeep, borderRadius: BorderRadius.circular(99)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.play_arrow_rounded, size: 18, color: Colors.white),
                        const SizedBox(width: 6),
                        Text('${starting ? 'Commencer' : 'Reprendre'} · ${next.minutes} min',
                            style: body(14, color: Colors.white, weight: FontWeight.w800, height: 1.2)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// « Le savais-tu ? » : une phrase tirée des leçons, qui change chaque jour.
class _DailyFact extends StatelessWidget {
  final List<Lesson> lessons;

  const _DailyFact({required this.lessons});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final day = now.difference(DateTime(now.year)).inDays;
    final lesson = lessons[day % lessons.length];
    final fact = lesson.essentials[day % lesson.essentials.length];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: BarroColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SoftIcon(icon: Icons.lightbulb_outline, tint: BarroColors.orangeSoft, color: BarroColors.orangeText),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('LE SAVAIS-TU ?', style: eyebrow(color: BarroColors.orangeText)),
                const SizedBox(height: 6),
                Text(fact, style: body(15, weight: FontWeight.w600, height: 1.45)),
                const SizedBox(height: 6),
                Text('Leçon ${lesson.number} · ${lesson.title}',
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: body(12, color: BarroColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final MetierCategory category;
  final int index;
  final bool last;

  const _CategoryRow({required this.category, required this.index, required this.last});

  @override
  Widget build(BuildContext context) {
    final open = category.openCount;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.of(context).push(barroRoute(MetiersScreen(initialCategory: index))),
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          decoration: BoxDecoration(
            border: last ? null : const Border(bottom: BorderSide(color: BarroColors.line)),
          ),
          child: Row(
            children: [
              SoftIcon(icon: category.icon, tint: category.tint, color: category.color),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(category.title, style: body(15, weight: FontWeight.w700)),
                    Text(
                      open > 0
                          ? '${category.metiers.length} métiers · $open ouvert'
                          : '${category.metiers.length} métiers',
                      style: body(12, color: BarroColors.muted),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: BarroColors.faint),
            ],
          ),
        ),
      ),
    );
  }
}

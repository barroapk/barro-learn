import 'dart:async';

import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../data/course.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/illustrations.dart';
import 'lesson_screen.dart';
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
            TextSpan(text: 'BARRO', style: display(26)),
            TextSpan(text: '.', style: display(26, color: BarroColors.green)),
          ])),
          actions: [
            SquareIconButton(
              icon: Icons.search,
              tooltip: 'Rechercher',
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SearchScreen())),
            ),
            SquareIconButton(
              icon: Icons.tune,
              tooltip: 'Paramètres',
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
            ),
          ],
        ),
        Expanded(
          child: ListenableBuilder(
            listenable: state,
            builder: (context, _) {
              final greeting = state.learnerName.isEmpty ? 'Bonjour' : 'Bonjour ${state.learnerName}';
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
                children: [
                  FadeSlideIn(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(greeting, style: body(14, color: BarroColors.muted)),
                              const SizedBox(height: 4),
                              Text('Qu\'apprends-tu\naujourd\'hui ?', style: display(28)),
                            ],
                          ),
                        ),
                        Pill(
                          label: state.streak <= 1 ? '${state.streak} jour' : '${state.streak} jours',
                          background: BarroColors.orange,
                          foreground: BarroColors.ink,
                          icon: Icons.local_fire_department,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  FadeSlideIn(index: 1, child: _Carousel(onOpenTab: onOpenTab)),
                  const SizedBox(height: 26),
                  FadeSlideIn(
                    index: 2,
                    child: SectionTitle(
                      'Métiers par catégorie',
                      trailing: TextButton(
                        onPressed: () => openMetiers(context),
                        child: Text('Tout voir', style: body(13, color: BarroColors.green, weight: FontWeight.w700)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  FadeSlideIn(
                    index: 3,
                    child: SizedBox(
                      height: 150,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: metierCategories.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, i) => _CategoryCard(category: metierCategories[i], index: i),
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),
                  FadeSlideIn(index: 4, child: _DailyFact(lessons: state.course.allLessons)),
                  const SizedBox(height: 26),
                  FadeSlideIn(index: 5, child: const SectionTitle('Univers à explorer')),
                  const SizedBox(height: 10),
                  FadeSlideIn(
                    index: 5,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _UniverseChip(label: 'Comment faire', color: BarroColors.blue, onTap: () => onOpenTab(1)),
                        _UniverseChip(label: 'Astuces du quotidien', color: BarroColors.orange, onTap: () => onOpenTab(1)),
                        _UniverseChip(label: 'Comment ça marche', color: BarroColors.teal, onTap: () => onOpenTab(1)),
                        _UniverseChip(label: 'Histoire & Géo', color: BarroColors.violet, onTap: () => onOpenTab(1)),
                        _UniverseChip(label: 'Sciences & Création', color: BarroColors.pink, onTap: () => onOpenTab(1)),
                      ],
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

/// Bandeau « à la une » qui défile tout seul.
class _Carousel extends StatefulWidget {
  final ValueChanged<int> onOpenTab;

  const _Carousel({required this.onOpenTab});

  @override
  State<_Carousel> createState() => _CarouselState();
}

class _CarouselState extends State<_Carousel> {
  final _controller = PageController(viewportFraction: 0.94);
  Timer? _timer;
  int _page = 0;
  static const _count = 3;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted || !_controller.hasClients) return;
      final next = (_page + 1) % _count;
      _controller.animateToPage(next, duration: const Duration(milliseconds: 500), curve: Curves.easeOutCubic);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    final next = state.nextLesson;
    return Column(
      children: [
        SizedBox(
          height: 196,
          child: PageView(
            controller: _controller,
            onPageChanged: (p) => setState(() => _page = p),
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: next != null ? _ContinueSlide(lesson: next) : _DoneSlide(onOpenTab: widget.onOpenTab),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: _Slide(
                  color: BarroColors.orange,
                  label: 'ASTUCE DU JOUR',
                  title: 'Garder ses tomates fraîches plus longtemps, sans frigo',
                  subtitle: 'Bientôt dans « Astuces du quotidien »',
                  icon: Icons.lightbulb_outline,
                  dark: true,
                  onTap: () => showSoon(context, 'L\'astuce du jour'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: _Slide(
                  color: BarroColors.deepViolet,
                  label: 'BIENTÔT',
                  title: 'Maraîchage : ton jardin potager pas à pas',
                  subtitle: 'Le prochain métier de BARRO',
                  icon: Icons.grass,
                  dark: false,
                  onTap: () => openMetiers(context, category: 0),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < _count; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: i == _page ? 22 : 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: i == _page ? BarroColors.green : BarroColors.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _ContinueSlide extends StatelessWidget {
  final Lesson lesson;

  const _ContinueSlide({required this.lesson});

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    final module = state.moduleOf(lesson);
    return Material(
      color: BarroColors.deepBlue,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => LessonScreen(lesson: lesson))),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 8, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(state.completedCount == 0 ? 'COMMENCE ICI' : 'CONTINUE',
                        style: body(12, color: const Color(0xFFDBE6FF), weight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Text(lesson.title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: body(17, color: Colors.white, weight: FontWeight.w800, height: 1.25)),
                    const Spacer(),
                    Text('Leçon ${lesson.number} sur ${state.course.lessonCount} · ${lesson.minutes} min',
                        style: body(12, color: const Color(0xFFDBE6FF))),
                    const SizedBox(height: 8),
                    BarroProgressBar(value: state.courseProgress, color: Colors.white, track: const Color(0xFF1D4FC4)),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: 130,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 12, 12, 12),
                child: ChickScene(prop: propForModule(module.number), sky: const Color(0xFF1D4FC4), height: 172),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DoneSlide extends StatelessWidget {
  final ValueChanged<int> onOpenTab;

  const _DoneSlide({required this.onOpenTab});

  @override
  Widget build(BuildContext context) {
    return _Slide(
      color: BarroColors.emerald,
      label: 'PARCOURS TERMINÉ',
      title: 'Bravo ! Tu as fini l\'élevage de poulets de chair',
      subtitle: 'Vois tes progrès et ton attestation',
      icon: Icons.workspace_premium,
      dark: false,
      onTap: () => onOpenTab(3),
    );
  }
}

class _Slide extends StatelessWidget {
  final Color color;
  final String label;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool dark;
  final VoidCallback onTap;

  const _Slide({
    required this.color,
    required this.label,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.dark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = dark ? BarroColors.ink : Colors.white;
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Positioned(
              right: -18,
              bottom: -18,
              child: Icon(icon, size: 140, color: fg.withValues(alpha: 0.12)),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: body(12, color: fg, weight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text(title, maxLines: 3, overflow: TextOverflow.ellipsis, style: display(21, color: fg)),
                  const Spacer(),
                  Text(subtitle, style: body(13, color: fg.withValues(alpha: 0.85), weight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final MetierCategory category;
  final int index;

  const _CategoryCard({required this.category, required this.index});

  @override
  Widget build(BuildContext context) {
    final available = category.metiers.where((m) => m.available).length;
    return SizedBox(
      width: 150,
      child: Material(
        color: category.color,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => openMetiers(context, category: index),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(category.icon, color: BarroColors.ink, size: 28),
                const Spacer(),
                Text(category.title, style: body(15, color: BarroColors.ink, weight: FontWeight.w800, height: 1.2)),
                const SizedBox(height: 4),
                Text(
                  available > 0 ? '${category.metiers.length} métiers · $available ouvert' : '${category.metiers.length} métiers',
                  style: body(12, color: const Color(0xFF1F2937), weight: FontWeight.w600),
                ),
              ],
            ),
          ),
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
    final dayOfYear = now.difference(DateTime(now.year)).inDays;
    final lesson = lessons[dayOfYear % lessons.length];
    final fact = lesson.essentials[dayOfYear % lesson.essentials.length];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BarroColors.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: BarroColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: BarroColors.teal, borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.tips_and_updates_outlined, color: BarroColors.ink),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('LE SAVAIS-TU ?', style: body(12, color: BarroColors.teal, weight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(fact, style: body(15, weight: FontWeight.w600, height: 1.4)),
                const SizedBox(height: 6),
                Text('Tiré de la leçon ${lesson.number} · ${lesson.title}', style: body(12, color: BarroColors.muted)),
              ],
            ),
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
    return Material(
      color: BarroColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(99),
        side: const BorderSide(color: BarroColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(99),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(label, style: body(14, weight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

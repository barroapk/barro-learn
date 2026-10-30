import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'course_screen.dart';
import 'search_screen.dart';

/// Tous les métiers, rangés par catégorie, avec des filtres en haut.
class MetiersScreen extends StatefulWidget {
  final int? initialCategory;

  const MetiersScreen({super.key, this.initialCategory});

  @override
  State<MetiersScreen> createState() => _MetiersScreenState();
}

class _MetiersScreenState extends State<MetiersScreen> {
  int? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialCategory;
  }

  @override
  Widget build(BuildContext context) {
    final shown = [
      for (var i = 0; i < metierCategories.length; i++)
        if (_selected == null || _selected == i) i,
    ];
    return BarroPage(
      child: Column(
        children: [
          TabHeader(
            onBack: () => Navigator.of(context).pop(),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Métiers', style: display(22)),
                Text('$metierCount métiers · ${metierCategories.length} catégories',
                    style: body(12, color: BarroColors.muted)),
              ],
            ),
            actions: [
              RoundIconButton(
                icon: Icons.search,
                tooltip: 'Rechercher un métier',
                onPressed: () => Navigator.of(context).push(barroRoute(const SearchScreen())),
              ),
            ],
            bottom: SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _FilterChip(label: 'Tous', selected: _selected == null, onTap: () => setState(() => _selected = null)),
                  for (var i = 0; i < metierCategories.length; i++)
                    _FilterChip(
                      label: metierCategories[i].title,
                      selected: _selected == i,
                      onTap: () => setState(() => _selected = i),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: ListView(
                key: ValueKey(_selected),
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
                children: [
                  for (var k = 0; k < shown.length; k++) ...[
                    FadeSlideIn(index: k, child: _CategorySection(category: metierCategories[shown[k]])),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Tap(
        onTap: onTap,
        semanticLabel: label,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? BarroColors.greenDeep : BarroColors.soft,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            label,
            style: body(13, color: selected ? Colors.white : BarroColors.ink, weight: FontWeight.w700, height: 1.2),
          ),
        ),
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  final MetierCategory category;

  const _CategorySection({required this.category});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SoftIcon(icon: category.icon, tint: category.tint, color: category.color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(category.title, style: display(17)),
                  Text('${category.subtitle} · ${category.metiers.length} métiers',
                      style: body(12, color: BarroColors.muted)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (final m in category.metiers) MetierTile(metier: m, category: category),
      ],
    );
  }
}

/// Une ligne de métier, réutilisée dans la recherche.
class MetierTile extends StatelessWidget {
  final Metier metier;
  final MetierCategory category;

  const MetierTile({super.key, required this.metier, required this.category});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Tap(
        semanticLabel: metier.title,
        onTap: () {
          if (metier.available) {
            Navigator.of(context).push(barroRoute(
              BarroPage(child: CourseScreen(onBack: () => Navigator.of(context).pop())),
            ));
          } else {
            showSoon(context, 'Le parcours « ${metier.title} »');
          }
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: metier.available ? category.tint : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: metier.available ? category.tint : BarroColors.line),
          ),
          child: Row(
            children: [
              SoftIcon(
                icon: metier.icon,
                tint: metier.available ? Colors.white : BarroColors.soft,
                color: metier.available ? category.color : BarroColors.muted,
                size: 44,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(metier.title, style: body(15, weight: FontWeight.w700, height: 1.25)),
                    const SizedBox(height: 2),
                    Text(metier.subtitle, style: body(12, color: BarroColors.muted)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              metier.available
                  ? const Pill(label: 'Ouvert', background: BarroColors.greenDeep, foreground: Colors.white)
                  : Text('Bientôt', style: body(12, color: BarroColors.faint, weight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

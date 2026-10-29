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
  int? _selected; // null = toutes les catégories

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
              children: [
                Text('Métiers', style: display(24)),
                Text('$metierCount métiers · ${metierCategories.length} catégories',
                    style: body(12, color: BarroColors.muted)),
              ],
            ),
            actions: [
              SquareIconButton(
                icon: Icons.search,
                tooltip: 'Rechercher un métier',
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SearchScreen())),
              ),
            ],
            bottom: SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _FilterChip(label: 'Tous', selected: _selected == null, color: BarroColors.text, onTap: () => setState(() => _selected = null)),
                  for (var i = 0; i < metierCategories.length; i++)
                    _FilterChip(
                      label: metierCategories[i].title,
                      selected: _selected == i,
                      color: metierCategories[i].color,
                      onTap: () => setState(() => _selected = i),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                for (final i in shown) ...[
                  FadeSlideIn(index: shown.indexOf(i), child: _CategorySection(category: metierCategories[i])),
                  const SizedBox(height: 24),
                ],
              ],
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
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? color : BarroColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(99),
          side: BorderSide(color: selected ? color : BarroColors.border),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(99),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Center(
              child: Text(
                label,
                style: body(13, color: selected ? BarroColors.ink : BarroColors.text, weight: FontWeight.w700),
              ),
            ),
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
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: category.color, borderRadius: BorderRadius.circular(12)),
              child: Icon(category.icon, color: BarroColors.ink, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(category.title, style: display(18, weight: FontWeight.w600)),
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
      child: Material(
        color: metier.available ? category.tint : BarroColors.surface.withValues(alpha: 0.85),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: metier.available ? category.color : BarroColors.border, width: metier.available ? 2 : 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (metier.available) {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => BarroPage(child: CourseScreen(onBack: () => Navigator.of(context).pop())),
              ));
            } else {
              showSoon(context, 'Le parcours « ${metier.title} »');
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: metier.available ? category.color : BarroColors.border,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(metier.icon, color: metier.available ? BarroColors.ink : BarroColors.muted),
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
                    ? Pill(label: 'Ouvert', background: category.color, foreground: BarroColors.ink)
                    : Text('Bientôt', style: body(12, color: BarroColors.muted, weight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

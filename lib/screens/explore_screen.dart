import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'search_screen.dart';

class _Universe {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color iconBox;
  final bool available;

  const _Universe(this.title, this.subtitle, this.icon, this.color, this.iconBox, {this.available = false});
}

const _universes = [
  _Universe('Métiers', 'Apprendre un métier qui rapporte', Icons.work_outline, BarroColors.green, Color(0xFF7FE7AE),
      available: true),
  _Universe('Comment faire', 'Des tutoriels pas à pas, en pratique', Icons.checklist, BarroColors.blue, Color(0xFF8DB6FF)),
  _Universe('Astuces du quotidien', 'Une astuce utile chaque jour', Icons.lightbulb_outline, BarroColors.orange,
      Color(0xFFFFB98A)),
  _Universe('Comment ça marche', 'Les machines, le corps, la nature', Icons.settings_outlined, BarroColors.teal,
      Color(0xFF81E6D9)),
  _Universe('Histoire & Géographie', 'Comprendre le monde et l\'Afrique', Icons.public, BarroColors.violet,
      Color(0xFFCBB9FD)),
  _Universe('Sciences & Création', 'Expérimenter, inventer, créer', Icons.science_outlined, BarroColors.pink,
      Color(0xFFF9A8D4)),
];

class ExploreScreen extends StatelessWidget {
  final ValueChanged<int> onOpenTab;

  const ExploreScreen({super.key, required this.onOpenTab});

  void _openSearch(BuildContext context) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SearchScreen()));

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabHeader(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Explorer', style: display(26)),
              Text('6 univers · $metierCount métiers', style: body(12, color: BarroColors.muted)),
            ],
          ),
          actions: [SquareIconButton(icon: Icons.search, tooltip: 'Rechercher', onPressed: () => _openSearch(context))],
          bottom: Material(
            color: BarroColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: BarroColors.border),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _openSearch(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: BarroColors.muted),
                    const SizedBox(width: 10),
                    Text('Que veux-tu apprendre ?', style: body(15, color: BarroColors.muted)),
                  ],
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
            children: [
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.86,
                children: [
                  for (var i = 0; i < _universes.length; i++)
                    FadeSlideIn(
                      index: i,
                      child: _UniverseTile(
                        universe: _universes[i],
                        onTap: () => _universes[i].available
                            ? openMetiers(context)
                            : showSoon(context, _universes[i].title),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _UniverseTile extends StatelessWidget {
  final _Universe universe;
  final VoidCallback onTap;

  const _UniverseTile({required this.universe, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: universe.color,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: universe.iconBox, borderRadius: BorderRadius.circular(14)),
                    child: Icon(universe.icon, color: BarroColors.ink),
                  ),
                  const Spacer(),
                  if (!universe.available)
                    Text('Bientôt', style: body(11, color: BarroColors.ink, weight: FontWeight.w800)),
                ],
              ),
              const Spacer(),
              Text(universe.title, style: body(16, color: BarroColors.ink, weight: FontWeight.w800, height: 1.2)),
              const SizedBox(height: 4),
              Text(universe.subtitle, style: body(13, color: const Color(0xFF1F2937), height: 1.3)),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/common.dart';

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

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        Text('Explorer', style: display(30)),
        const SizedBox(height: 4),
        Text('6 univers pour apprendre, comprendre et créer', style: body(14, color: BarroColors.muted)),
        const SizedBox(height: 18),
        TextField(
          style: body(15),
          decoration: InputDecoration(
            hintText: 'Que veux-tu apprendre ?',
            hintStyle: body(15, color: BarroColors.muted),
            prefixIcon: const Icon(Icons.search, color: BarroColors.muted),
            filled: true,
            fillColor: BarroColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: BarroColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: BarroColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: BarroColors.green, width: 2),
            ),
          ),
          onSubmitted: (_) => showSoon(context, 'La recherche'),
        ),
        const SizedBox(height: 18),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.86,
          children: [
            for (final u in _universes)
              _UniverseTile(
                universe: u,
                onTap: () => u.available ? onOpenTab(2) : showSoon(context, u.title),
              ),
          ],
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

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Onglet « Progrès » : niveau, statistiques, défi et attestation.
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final challengeDone = math.min(state.completedCount, 3);
        final allDone = state.completedCount == state.course.lessonCount;
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Row(
              children: [
                Expanded(child: Text('Ton progrès', style: display(30))),
                SquareIconButton(
                  icon: Icons.settings_outlined,
                  tooltip: 'Paramètres',
                  onPressed: () => showSoon(context, 'Les paramètres'),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: BarroColors.green,
                  child: Text('B', style: display(24, color: BarroColors.ink)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text('Apprenant BARRO', style: body(17, weight: FontWeight.w800))),
                          Text('Niveau ${state.level}',
                              style: body(13, color: BarroColors.green, weight: FontWeight.w700)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      BarroProgressBar(value: state.xpInLevel / AppState.xpPerLevel),
                      const SizedBox(height: 4),
                      Text('${state.xpInLevel} / ${AppState.xpPerLevel} XP avant le niveau ${state.level + 1}',
                          style: body(12, color: BarroColors.muted)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(child: _Stat(value: '${state.streak}', label: 'jour de série', color: BarroColors.orange)),
                const SizedBox(width: 10),
                Expanded(child: _Stat(value: '${state.completedCount}', label: 'leçons finies', color: BarroColors.blue)),
                const SizedBox(width: 10),
                Expanded(child: _Stat(value: '${state.xp}', label: 'XP gagnés', color: BarroColors.green)),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: BarroColors.deepViolet, borderRadius: BorderRadius.circular(22)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('DÉFI DE LA SEMAINE',
                          style: body(12, color: const Color(0xFFE4DBFF), weight: FontWeight.w800)),
                      const Spacer(),
                      const Pill(label: '+100 XP', background: Colors.white, foreground: BarroColors.deepViolet),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text('Termine 3 leçons cette semaine', style: body(17, color: Colors.white, weight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      for (var i = 0; i < 3; i++) ...[
                        Expanded(
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: i < challengeDone ? Colors.white : const Color(0xFF7C3AED),
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                        if (i < 2) const SizedBox(width: 6),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('$challengeDone sur 3', style: body(12, color: const Color(0xFFE4DBFF))),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFF10203F), borderRadius: BorderRadius.circular(18)),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: BarroColors.blue, borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.workspace_premium_outlined, color: BarroColors.ink),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Attestation · ${state.course.title}', style: body(14, weight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text(allDone ? 'Examen final disponible' : 'Débloquée après les 15 leçons et l\'examen',
                            style: body(12, color: const Color(0xFFBFD5FF))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text('Classement entre amis : bientôt disponible.', style: body(13, color: BarroColors.muted)),
          ],
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _Stat({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: display(24, color: BarroColors.ink)),
          const SizedBox(height: 2),
          Text(label, style: body(12, color: BarroColors.ink, weight: FontWeight.w600)),
        ],
      ),
    );
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'settings_screen.dart';

/// Onglet « Progrès » : niveau, statistiques, défi, badges et attestation.
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    return Column(
      children: [
        TabHeader(
          title: Text('Ton progrès', style: display(22)),
          actions: [
            RoundIconButton(
              icon: Icons.settings_outlined,
              tooltip: 'Paramètres',
              onPressed: () => Navigator.of(context).push(barroRoute(const SettingsScreen())),
            ),
          ],
        ),
        Expanded(
          child: ListenableBuilder(
            listenable: state,
            builder: (context, _) {
              final name = state.learnerName.isEmpty ? 'Apprenant BARRO' : state.learnerName;
              final challengeDone = math.min(state.completedCount, 3);
              final badges = [
                _BadgeData('Premier pas', Icons.flag_outlined, state.completedCount >= 1, BarroColors.greenText,
                    BarroColors.greenSoft),
                _BadgeData('Module 1', Icons.home_work_outlined, state.completedCount >= 5, BarroColors.blue,
                    BarroColors.blueSoft),
                _BadgeData('3 jours', Icons.local_fire_department, state.streak >= 3, BarroColors.orangeText,
                    BarroColors.orangeSoft),
                _BadgeData('Éleveur', Icons.workspace_premium_outlined, state.allDone, BarroColors.violet,
                    BarroColors.violetSoft),
              ];
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
                children: [
                  FadeSlideIn(
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(color: BarroColors.greenSoft, borderRadius: BorderRadius.circular(26)),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 96,
                            height: 96,
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: state.xpInLevel / AppState.xpPerLevel),
                              duration: const Duration(milliseconds: 900),
                              curve: Curves.easeOutCubic,
                              builder: (context, v, _) => CustomPaint(
                                painter: _RingPainter(v),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('${state.level}', style: display(28, height: 1)),
                                      Text('niveau', style: body(11, color: BarroColors.muted, weight: FontWeight.w700)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: display(19)),
                                const SizedBox(height: 4),
                                Text('${state.xpInLevel} / ${AppState.xpPerLevel} XP',
                                    style: body(14, color: BarroColors.greenText, weight: FontWeight.w800)),
                                const SizedBox(height: 4),
                                Text(
                                  'Encore ${AppState.xpPerLevel - state.xpInLevel} XP pour le niveau ${state.level + 1}',
                                  style: body(12, color: BarroColors.inkSoft),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const FadeSlideIn(index: 1, child: StatsStrip()),
                  const SizedBox(height: 14),
                  FadeSlideIn(
                    index: 2,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: BarroColors.line),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('DÉFI DE LA SEMAINE', style: eyebrow(color: BarroColors.violet)),
                              const Spacer(),
                              const Pill(label: '+100 XP', background: BarroColors.violetSoft, foreground: BarroColors.violet),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Termine 3 leçons', style: display(17)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              for (var i = 0; i < 3; i++) ...[
                                Expanded(
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 400),
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: i < challengeDone ? BarroColors.violet : BarroColors.line,
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                  ),
                                ),
                                if (i < 2) const SizedBox(width: 6),
                              ],
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text('$challengeDone sur 3', style: body(12, color: BarroColors.muted)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  FadeSlideIn(
                    index: 3,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: BarroColors.soft, borderRadius: BorderRadius.circular(20)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const SoftIcon(icon: Icons.egg_outlined, tint: Colors.white, color: BarroColors.greenText),
                              const SizedBox(width: 12),
                              Expanded(child: Text(state.course.title, style: body(15, weight: FontWeight.w800))),
                            ],
                          ),
                          const SizedBox(height: 12),
                          BarroProgressBar(value: state.courseProgress, height: 8),
                          const SizedBox(height: 6),
                          Text('${state.completedCount} sur ${state.course.lessonCount} leçons',
                              style: body(12, color: BarroColors.muted)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const FadeSlideIn(index: 4, child: SectionTitle('Badges')),
                  const SizedBox(height: 12),
                  FadeSlideIn(
                    index: 5,
                    child: Row(
                      children: [for (final b in badges) Expanded(child: _Badge(data: b))],
                    ),
                  ),
                  const SizedBox(height: 24),
                  FadeSlideIn(
                    index: 6,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: state.allDone ? BarroColors.greenDeep : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: state.allDone ? BarroColors.greenDeep : BarroColors.line),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.workspace_premium_outlined,
                              size: 30, color: state.allDone ? BarroColors.sun : BarroColors.faint),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Attestation BARRO',
                                    style: body(15,
                                        color: state.allDone ? Colors.white : BarroColors.ink, weight: FontWeight.w800)),
                                const SizedBox(height: 2),
                                Text(
                                  state.allDone
                                      ? 'Examen final bientôt disponible'
                                      : 'Débloquée après les 15 leçons et l\'examen',
                                  style: body(12, color: state.allDone ? BarroColors.greenMid : BarroColors.muted),
                                ),
                              ],
                            ),
                          ),
                        ],
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

class _RingPainter extends CustomPainter {
  final double value;

  _RingPainter(this.value);

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 9.0;
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(stroke / 2);
    canvas.drawArc(
      arcRect,
      0,
      2 * math.pi,
      false,
      Paint()
        ..color = BarroColors.greenMid
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    if (value > 0) {
      canvas.drawArc(
        arcRect,
        -math.pi / 2,
        2 * math.pi * value,
        false,
        Paint()
          ..color = BarroColors.green
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.value != value;
}

class _BadgeData {
  final String label;
  final IconData icon;
  final bool earned;
  final Color color;
  final Color tint;

  const _BadgeData(this.label, this.icon, this.earned, this.color, this.tint);
}

class _Badge extends StatelessWidget {
  final _BadgeData data;

  const _Badge({required this.data});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${data.label} : ${data.earned ? 'obtenu' : 'à débloquer'}',
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: data.earned ? data.tint : BarroColors.soft,
              shape: BoxShape.circle,
              border: Border.all(color: data.earned ? data.color : BarroColors.line, width: 2),
            ),
            child: Icon(data.earned ? data.icon : Icons.lock_outline,
                color: data.earned ? data.color : BarroColors.faint, size: 26),
          ),
          const SizedBox(height: 6),
          Text(data.label,
              textAlign: TextAlign.center,
              style: body(12, color: data.earned ? BarroColors.ink : BarroColors.muted, weight: FontWeight.w700)),
        ],
      ),
    );
  }
}

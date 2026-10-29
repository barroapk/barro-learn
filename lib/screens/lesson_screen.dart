import 'package:flutter/material.dart';

import '../data/course.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Une leçon BARRO, étape par étape :
/// 1 Accroche + vidéo · 2 L'essentiel · 3 À toi de faire · 4 Quiz · 5 Récompense.
class LessonScreen extends StatefulWidget {
  final Lesson lesson;

  const LessonScreen({super.key, required this.lesson});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  static const _stepCount = 5;
  static const _stepNames = ['Accroche', 'L\'essentiel', 'À toi de faire', 'Quiz', 'Récompense'];

  int _step = 0;
  int _question = 0;
  int? _picked;
  bool _checked = false;
  int _correct = 0;

  Lesson get lesson => widget.lesson;
  int get _earnedXp => 10 + 10 * _correct;

  void _next() {
    setState(() {
      if (_step < 3) {
        _step++;
        return;
      }
      if (_step == 3) {
        if (!_checked) {
          _checked = true;
          if (_picked == lesson.quiz[_question].answer) _correct++;
        } else if (_question < lesson.quiz.length - 1) {
          _question++;
          _picked = null;
          _checked = false;
        } else {
          _step = 4;
        }
      }
    });
  }

  void _finish() {
    AppState.instance.completeLesson(lesson, _earnedXp);
    Navigator.of(context).pop();
  }

  String get _buttonLabel {
    switch (_step) {
      case 0:
        return 'Commencer';
      case 1:
        return 'J\'ai compris';
      case 2:
        return 'C\'est fait';
      case 3:
        if (!_checked) return 'Vérifier';
        return _question < lesson.quiz.length - 1 ? 'Question suivante' : 'Voir mon résultat';
      default:
        return 'Terminer la leçon';
    }
  }

  VoidCallback? get _buttonAction {
    if (_step == 4) return _finish;
    if (_step == 3 && !_checked && _picked == null) return null;
    return _next;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            children: [
              _TopBar(step: _step, stepCount: _stepCount, onClose: () => Navigator.of(context).pop()),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'LEÇON ${lesson.number} · ÉTAPE ${_step + 1} SUR $_stepCount · ${_stepNames[_step].toUpperCase()}',
                  style: body(11, color: BarroColors.muted, weight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween(begin: const Offset(0.06, 0), end: Offset.zero).animate(animation),
                      child: child,
                    ),
                  ),
                  child: SingleChildScrollView(
                    key: ValueKey('$_step-$_question-$_checked'),
                    child: _buildStep(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              PrimaryButton(label: _buttonLabel, onPressed: _buttonAction),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _HookStep(lesson: lesson);
      case 1:
        return _EssentialsStep(lesson: lesson);
      case 2:
        return _TaskStep(lesson: lesson);
      case 3:
        return _QuizStep(
          question: lesson.quiz[_question],
          index: _question,
          total: lesson.quiz.length,
          picked: _picked,
          checked: _checked,
          onPick: (i) {
            if (!_checked) setState(() => _picked = i);
          },
        );
      default:
        return _RewardStep(correct: _correct, total: lesson.quiz.length, xp: _earnedXp);
    }
  }
}

class _TopBar extends StatelessWidget {
  final int step;
  final int stepCount;
  final VoidCallback onClose;

  const _TopBar({required this.step, required this.stepCount, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SquareIconButton(icon: Icons.close, tooltip: 'Fermer la leçon', onPressed: onClose),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            children: [
              for (var i = 0; i < stepCount; i++) ...[
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    height: 6,
                    decoration: BoxDecoration(
                      color: i <= step ? BarroColors.green : BarroColors.border,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                if (i < stepCount - 1) const SizedBox(width: 6),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
        const Pill(label: 'XP', background: BarroColors.orange, foreground: BarroColors.ink, icon: Icons.bolt),
      ],
    );
  }
}

class _HookStep extends StatelessWidget {
  final Lesson lesson;

  const _HookStep({required this.lesson});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(lesson.title, style: display(26)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: BarroColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: BarroColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.help_outline, color: BarroColors.orange),
              const SizedBox(width: 12),
              Expanded(child: Text(lesson.hook, style: body(16, weight: FontWeight.w600, height: 1.45))),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Material(
            color: const Color(0xFF1E40AF),
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => showSoon(context, 'Le lecteur vidéo intégré'),
              child: Stack(
                children: [
                  const Center(
                    child: CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.play_arrow_rounded, size: 36, color: Color(0xFF1E40AF)),
                    ),
                  ),
                  Positioned(
                    left: 14,
                    bottom: 12,
                    child: Pill(
                      label: lesson.videoUrl != null ? 'Démonstration' : 'Vidéo bientôt',
                      background: BarroColors.ink,
                      foreground: Colors.white,
                    ),
                  ),
                  Positioned(
                    right: 14,
                    bottom: 18,
                    child: Text('Lu dans BARRO', style: body(12, color: const Color(0xFFDBE6FF))),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EssentialsStep extends StatelessWidget {
  final Lesson lesson;

  const _EssentialsStep({required this.lesson});

  static const _colors = [BarroColors.green, BarroColors.blue, BarroColors.orange];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('L\'essentiel à retenir', style: display(24)),
        const SizedBox(height: 6),
        Text('3 points, pas un de plus.', style: body(14, color: BarroColors.muted)),
        const SizedBox(height: 16),
        for (var i = 0; i < lesson.essentials.length; i++)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: BarroColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: BarroColors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 15,
                  backgroundColor: _colors[i % 3],
                  child: Text('${i + 1}', style: body(14, color: BarroColors.ink, weight: FontWeight.w800)),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(lesson.essentials[i], style: body(15, height: 1.45))),
              ],
            ),
          ),
      ],
    );
  }
}

class _TaskStep extends StatelessWidget {
  final Lesson lesson;

  const _TaskStep({required this.lesson});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('À toi de faire', style: display(24)),
        const SizedBox(height: 6),
        Text('Une action concrète, dans la vraie vie.', style: body(14, color: BarroColors.muted)),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: BarroColors.deepViolet, borderRadius: BorderRadius.circular(22)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white,
                child: Icon(Icons.photo_camera_outlined, color: BarroColors.deepViolet),
              ),
              const SizedBox(height: 14),
              Text(lesson.task, style: body(17, color: Colors.white, weight: FontWeight.w700, height: 1.4)),
              const SizedBox(height: 12),
              Text('Bientôt : envoie ta photo comme preuve et gagne des XP en plus.',
                  style: body(13, color: const Color(0xFFE4DBFF))),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuizStep extends StatelessWidget {
  final QuizQuestion question;
  final int index;
  final int total;
  final int? picked;
  final bool checked;
  final ValueChanged<int> onPick;

  const _QuizStep({
    required this.question,
    required this.index,
    required this.total,
    required this.picked,
    required this.checked,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final right = picked == question.answer;
    String status = 'Question ${index + 1} sur $total';
    Color statusColor = BarroColors.muted;
    if (checked) {
      status = right ? 'Bravo, bonne réponse !' : 'Pas tout à fait. La bonne réponse est en vert.';
      statusColor = right ? BarroColors.green : BarroColors.red;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(status, style: body(13, color: statusColor, weight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(question.question, style: display(22)),
        const SizedBox(height: 18),
        for (var i = 0; i < question.options.length; i++) _option(i),
      ],
    );
  }

  Widget _option(int i) {
    Color border = BarroColors.border;
    Color background = BarroColors.surface;
    IconData mark = Icons.radio_button_unchecked;
    Color markColor = BarroColors.muted;

    if (!checked && picked == i) {
      border = BarroColors.blue;
      background = const Color(0xFF10203F);
      mark = Icons.radio_button_checked;
      markColor = BarroColors.blue;
    }
    if (checked && i == question.answer) {
      border = BarroColors.green;
      background = const Color(0xFF0E2A1D);
      mark = Icons.check_circle;
      markColor = BarroColors.green;
    } else if (checked && picked == i) {
      border = BarroColors.red;
      background = const Color(0xFF2E1420);
      mark = Icons.cancel;
      markColor = BarroColors.red;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: border, width: 2),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => onPick(i),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Icon(mark, color: markColor),
                const SizedBox(width: 12),
                Expanded(child: Text(question.options[i], style: body(15, weight: FontWeight.w600))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RewardStep extends StatelessWidget {
  final int correct;
  final int total;
  final int xp;

  const _RewardStep({required this.correct, required this.total, required this.xp});

  @override
  Widget build(BuildContext context) {
    final message = correct == total
        ? 'Parfait ! Tu as tout bon.'
        : correct == 0
            ? 'Pas grave : relis l\'essentiel et réessaie plus tard.'
            : 'Bien joué, tu progresses.';
    return Column(
      children: [
        const SizedBox(height: 24),
        Container(
          width: 140,
          height: 140,
          decoration: const BoxDecoration(color: BarroColors.orange, shape: BoxShape.circle),
          child: const Icon(Icons.emoji_events, size: 72, color: BarroColors.ink),
        ),
        const SizedBox(height: 24),
        Text('+$xp XP', style: display(44, color: BarroColors.green)),
        const SizedBox(height: 8),
        Text('$correct bonne${correct > 1 ? 's' : ''} réponse${correct > 1 ? 's' : ''} sur $total',
            style: body(16, weight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center, style: body(14, color: BarroColors.muted)),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: BarroColors.surface, borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              const Icon(Icons.lock_open, color: BarroColors.blue),
              const SizedBox(width: 10),
              Expanded(child: Text('La leçon suivante est débloquée.', style: body(14, weight: FontWeight.w600))),
            ],
          ),
        ),
      ],
    );
  }
}

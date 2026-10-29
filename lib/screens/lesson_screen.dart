import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/course.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/illustrations.dart';

/// Une leçon BARRO racontée comme une petite histoire, en 6 étapes.
class LessonScreen extends StatefulWidget {
  final Lesson lesson;

  const LessonScreen({super.key, required this.lesson});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  static const _stepNames = ['Le savais-tu ?', 'La démonstration', 'L\'essentiel', 'À toi de faire', 'Quiz', 'Bravo'];

  int _step = 0;
  int _revealed = 1;
  int _question = 0;
  int? _picked;
  bool _checked = false;
  int _correct = 0;
  bool _saved = false;

  Lesson get lesson => widget.lesson;
  int get _earnedXp => 10 + 10 * _correct;
  bool get _lastQuestion => _question == lesson.quiz.length - 1;

  void _next() {
    setState(() {
      switch (_step) {
        case 2:
          if (_revealed < lesson.essentials.length) {
            _revealed++;
          } else {
            _step++;
          }
          break;
        case 4:
          if (!_checked) {
            _checked = true;
            if (_picked == lesson.quiz[_question].answer) _correct++;
          } else if (!_lastQuestion) {
            _question++;
            _picked = null;
            _checked = false;
          } else {
            _step = 5;
          }
          break;
        default:
          if (_step < 5) _step++;
      }
    });
    if (_step == 5 && !_saved) {
      _saved = true;
      AppState.instance.completeLesson(lesson, _earnedXp);
    }
  }

  void _goToNextLesson() {
    final next = AppState.instance.lessonAfter(lesson);
    if (next == null) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => LessonScreen(lesson: next)));
  }

  String get _buttonLabel {
    switch (_step) {
      case 0:
        return 'Découvrir';
      case 1:
        return 'Continuer';
      case 2:
        return _revealed < lesson.essentials.length ? 'Point suivant' : 'J\'ai compris';
      case 3:
        return 'Je vais le faire';
      case 4:
        if (!_checked) return 'Vérifier';
        return _lastQuestion ? 'Voir mon résultat' : 'Question suivante';
      default:
        return AppState.instance.lessonAfter(lesson) != null ? 'Leçon suivante' : 'Terminer le parcours';
    }
  }

  VoidCallback? get _buttonAction {
    if (_step == 5) return _goToNextLesson;
    if (_step == 4 && !_checked && _picked == null) return null;
    return _next;
  }

  @override
  Widget build(BuildContext context) {
    final module = AppState.instance.moduleOf(lesson);
    return BarroPage(
      child: Stack(
        children: [
          Column(
            children: [
              TabHeader(
                title: _StepBar(step: _step, count: _stepNames.length),
                actions: [Pill(label: '+$_earnedXp XP', background: BarroColors.orange, foreground: BarroColors.ink)],
                onBack: () => Navigator.of(context).pop(),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'MODULE ${module.number} · LEÇON ${lesson.number} · ${_stepNames[_step].toUpperCase()}',
                    style: body(11, color: BarroColors.muted, weight: FontWeight.w800),
                  ),
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween(begin: const Offset(0.08, 0), end: Offset.zero).animate(animation),
                      child: child,
                    ),
                  ),
                  child: SingleChildScrollView(
                    key: ValueKey('$_step-$_question-$_checked-$_revealed'),
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    child: _buildStep(module),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Column(
                  children: [
                    PrimaryButton(
                      label: _buttonLabel,
                      onPressed: _buttonAction,
                      icon: _step == 5 ? Icons.arrow_forward : null,
                    ),
                    if (_step == 5)
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('Retour au parcours', style: body(14, color: BarroColors.muted, weight: FontWeight.w700)),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (_step == 5) const Positioned.fill(child: Confetti()),
        ],
      ),
    );
  }

  Widget _buildStep(CourseModule module) {
    switch (_step) {
      case 0:
        return _HookStep(lesson: lesson, module: module);
      case 1:
        return _VideoStep(lesson: lesson);
      case 2:
        return _EssentialsStep(
          lesson: lesson,
          revealed: _revealed,
          onReveal: () => setState(() {
            if (_revealed < lesson.essentials.length) _revealed++;
          }),
        );
      case 3:
        return _TaskStep(lesson: lesson);
      case 4:
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
        return _RewardStep(
          correct: _correct,
          total: lesson.quiz.length,
          xp: _earnedXp,
          next: AppState.instance.lessonAfter(lesson),
        );
    }
  }
}

class _StepBar extends StatelessWidget {
  final int step;
  final int count;

  const _StepBar({required this.step, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < count; i++) ...[
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 6,
              decoration: BoxDecoration(
                color: i <= step ? BarroColors.green : BarroColors.border,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          if (i < count - 1) const SizedBox(width: 5),
        ],
      ],
    );
  }
}

class _HookStep extends StatelessWidget {
  final Lesson lesson;
  final CourseModule module;

  const _HookStep({required this.lesson, required this.module});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeSlideIn(child: ChickScene(prop: propForModule(module.number), height: 190)),
        const SizedBox(height: 18),
        FadeSlideIn(index: 1, child: Text(lesson.title, style: display(26))),
        const SizedBox(height: 14),
        FadeSlideIn(
          index: 2,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: BarroColors.orange, borderRadius: BorderRadius.circular(20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lightbulb, color: BarroColors.ink, size: 20),
                    const SizedBox(width: 8),
                    Text('LE SAVAIS-TU ?', style: body(12, color: BarroColors.ink, weight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(lesson.hook, style: body(16, color: BarroColors.ink, weight: FontWeight.w700, height: 1.45)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        FadeSlideIn(
          index: 3,
          child: Text('${lesson.minutes} minutes · 3 points à retenir · 3 questions',
              style: body(13, color: BarroColors.muted)),
        ),
      ],
    );
  }
}

class _VideoStep extends StatelessWidget {
  final Lesson lesson;

  const _VideoStep({required this.lesson});

  Future<void> _open(BuildContext context) async {
    final url = lesson.videoUrl;
    if (url == null) {
      showSoon(context, 'La vidéo de cette leçon');
      return;
    }
    var ok = false;
    try {
      ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      ok = false;
    }
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Impossible d\'ouvrir YouTube. Vérifie ta connexion.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasVideo = lesson.videoUrl != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Regarde avant de lire', style: display(24)),
        const SizedBox(height: 6),
        Text('Une courte démonstration montre les gestes de la leçon.', style: body(14, color: BarroColors.muted)),
        const SizedBox(height: 16),
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Material(
            color: BarroColors.deepBlue,
            borderRadius: BorderRadius.circular(22),
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () => _open(context),
              child: Stack(
                children: [
                  const Center(
                    child: CircleAvatar(
                      radius: 34,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.play_arrow_rounded, size: 40, color: BarroColors.deepBlue),
                    ),
                  ),
                  Positioned(
                    left: 14,
                    bottom: 12,
                    child: Pill(
                      label: hasVideo ? 'Ouvrir la vidéo' : 'Vidéo bientôt',
                      background: BarroColors.ink,
                      foreground: Colors.white,
                      icon: hasVideo ? Icons.smart_display_outlined : Icons.schedule,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          hasVideo
              ? 'La vidéo s\'ouvre dans YouTube. Reviens ensuite ici pour la suite de la leçon.'
              : 'Pas encore de vidéo pour cette leçon : passe directement à l\'essentiel.',
          style: body(13, color: BarroColors.muted),
        ),
      ],
    );
  }
}

class _EssentialsStep extends StatelessWidget {
  final Lesson lesson;
  final int revealed;
  final VoidCallback onReveal;

  const _EssentialsStep({required this.lesson, required this.revealed, required this.onReveal});

  static const _colors = [BarroColors.green, BarroColors.blue, BarroColors.orange];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('L\'essentiel', style: display(24)),
        const SizedBox(height: 6),
        Text('Découvre les points un par un.', style: body(14, color: BarroColors.muted)),
        const SizedBox(height: 16),
        for (var i = 0; i < lesson.essentials.length; i++)
          i < revealed
              ? FadeSlideIn(
                  index: i == revealed - 1 ? 0 : -4,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: _colors[i % 3], borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 15,
                          backgroundColor: BarroColors.ink,
                          child: Text('${i + 1}', style: body(14, color: Colors.white, weight: FontWeight.w800)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(lesson.essentials[i],
                              style: body(16, color: BarroColors.ink, weight: FontWeight.w700, height: 1.45)),
                        ),
                      ],
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: BarroColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: const BorderSide(color: BarroColors.border),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: i == revealed ? onReveal : null,
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          children: [
                            Icon(i == revealed ? Icons.touch_app_outlined : Icons.lock_outline, color: BarroColors.muted),
                            const SizedBox(width: 12),
                            Text(
                              i == revealed ? 'Point ${i + 1} · touche pour découvrir' : 'Point ${i + 1}',
                              style: body(15, color: BarroColors.muted, weight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
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
        Text('Ce qu\'on fait de ses mains, on ne l\'oublie pas.', style: body(14, color: BarroColors.muted)),
        const SizedBox(height: 16),
        FadeSlideIn(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: BarroColors.deepViolet, borderRadius: BorderRadius.circular(24)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.photo_camera_outlined, color: BarroColors.deepViolet, size: 26),
                ),
                const SizedBox(height: 16),
                Text(lesson.task, style: body(18, color: Colors.white, weight: FontWeight.w800, height: 1.4)),
                const SizedBox(height: 14),
                Text('Bientôt : envoie ta photo comme preuve et gagne des XP en plus.',
                    style: body(13, color: const Color(0xFFE4DBFF))),
              ],
            ),
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
        Row(
          children: [
            for (var i = 0; i < total; i++)
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: i < index || (i == index && checked) ? BarroColors.green : BarroColors.border,
                  shape: BoxShape.circle,
                ),
              ),
            const SizedBox(width: 6),
            Expanded(child: Text(status, style: body(13, color: statusColor, weight: FontWeight.w800))),
          ],
        ),
        const SizedBox(height: 12),
        Text(question.question, style: display(22)),
        const SizedBox(height: 18),
        for (var i = 0; i < question.options.length; i++) FadeSlideIn(index: i, child: _option(i)),
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
      child: AnimatedScale(
        scale: !checked && picked == i ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 150),
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
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
      ),
    );
  }
}

class _RewardStep extends StatelessWidget {
  final int correct;
  final int total;
  final int xp;
  final Lesson? next;

  const _RewardStep({required this.correct, required this.total, required this.xp, required this.next});

  @override
  Widget build(BuildContext context) {
    final message = correct == total
        ? 'Parfait, tu as tout bon !'
        : correct == 0
            ? 'Pas grave : relis l\'essentiel plus tard, ça rentrera.'
            : 'Bien joué, tu progresses.';
    return Column(
      children: [
        const SizedBox(height: 8),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.6, end: 1),
          duration: const Duration(milliseconds: 600),
          curve: Curves.elasticOut,
          builder: (context, s, child) => Transform.scale(scale: s, child: child),
          child: Container(
            width: 130,
            height: 130,
            decoration: const BoxDecoration(color: BarroColors.orange, shape: BoxShape.circle),
            child: const Icon(Icons.emoji_events, size: 68, color: BarroColors.ink),
          ),
        ),
        const SizedBox(height: 18),
        TweenAnimationBuilder<int>(
          tween: IntTween(begin: 0, end: xp),
          duration: const Duration(milliseconds: 900),
          builder: (context, v, _) => Text('+$v XP', style: display(44, color: BarroColors.green)),
        ),
        const SizedBox(height: 6),
        Text('$correct bonne${correct > 1 ? 's' : ''} réponse${correct > 1 ? 's' : ''} sur $total',
            style: body(16, weight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(message, textAlign: TextAlign.center, style: body(14, color: BarroColors.muted)),
        const SizedBox(height: 20),
        if (next != null)
          FadeSlideIn(
            index: 3,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF10203F),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: BarroColors.blue, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('DANS LA PROCHAINE LEÇON', style: body(12, color: const Color(0xFFBFD5FF), weight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(next!.title, style: body(17, weight: FontWeight.w800, height: 1.3)),
                  const SizedBox(height: 6),
                  Text(next!.hook, style: body(14, color: const Color(0xFFBFD5FF), height: 1.4)),
                ],
              ),
            ),
          ),
        if (next == null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: BarroColors.emerald, borderRadius: BorderRadius.circular(20)),
            child: Text('Tu as fini les 15 leçons ! L\'examen final arrive bientôt pour obtenir ton attestation.',
                style: body(15, color: Colors.white, weight: FontWeight.w700)),
          ),
      ],
    );
  }
}

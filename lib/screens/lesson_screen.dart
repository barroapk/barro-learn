import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/course.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/illustrations.dart';

/// Une leçon racontée comme une story, en 6 étapes :
/// Intro · Vidéo · L'essentiel · À toi · Quiz · Bravo.
class LessonScreen extends StatefulWidget {
  final Lesson lesson;

  const LessonScreen({super.key, required this.lesson});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  static const _stepCount = 6;

  int _step = 0;
  int _revealed = 1;
  int _question = 0;
  int _correct = 0;
  int _combo = 0;
  int? _picked;
  bool _checked = false;
  bool _committed = false;
  bool _saved = false;

  Lesson get lesson => widget.lesson;
  int get _earnedXp => 10 + 10 * _correct + (_committed ? 5 : 0);
  bool get _lastQuestion => _question == lesson.quiz.length - 1;

  void _next() {
    switch (_step) {
      case 2:
        if (_revealed < lesson.essentials.length) {
          setState(() => _revealed++);
          HapticFeedback.selectionClick();
          return;
        }
        break;
      case 4:
        if (!_checked) {
          final right = _picked == lesson.quiz[_question].answer;
          setState(() {
            _checked = true;
            if (right) {
              _correct++;
              _combo++;
            } else {
              _combo = 0;
            }
          });
          if (right) {
            HapticFeedback.lightImpact();
          } else {
            HapticFeedback.mediumImpact();
          }
          return;
        }
        if (!_lastQuestion) {
          setState(() {
            _question++;
            _picked = null;
            _checked = false;
          });
          return;
        }
        break;
    }
    if (_step < _stepCount - 1) {
      setState(() => _step++);
      if (_step == _stepCount - 1 && !_saved) {
        _saved = true;
        AppState.instance.completeLesson(lesson, _earnedXp);
        HapticFeedback.heavyImpact();
      }
    }
  }

  void _goToNextLesson() {
    final next = AppState.instance.lessonAfter(lesson);
    if (next == null) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pushReplacement(barroRoute(LessonScreen(lesson: next)));
  }

  String get _buttonLabel {
    switch (_step) {
      case 0:
        return 'Découvrir la leçon';
      case 1:
        return lesson.videoUrl != null ? 'J\'ai regardé, continuer' : 'Continuer';
      case 2:
        return _revealed < lesson.essentials.length ? 'Point suivant' : 'J\'ai compris';
      case 3:
        return _committed ? 'C\'est noté, au quiz !' : 'Passer au quiz';
      case 4:
        if (!_checked) return 'Vérifier';
        return _lastQuestion ? 'Voir mon résultat' : 'Question suivante';
      default:
        return AppState.instance.lessonAfter(lesson) != null ? 'Leçon suivante' : 'Terminer le parcours';
    }
  }

  VoidCallback? get _buttonAction {
    if (_step == _stepCount - 1) return _goToNextLesson;
    if (_step == 4 && !_checked && _picked == null) return null;
    return _next;
  }

  @override
  Widget build(BuildContext context) {
    final module = AppState.instance.moduleOf(lesson);
    final q = lesson.quiz[_question];
    return BarroPage(
      child: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                child: Row(
                  children: [
                    RoundIconButton(icon: Icons.close, tooltip: 'Fermer la leçon', onPressed: () => Navigator.of(context).pop()),
                    const SizedBox(width: 12),
                    Expanded(child: _StoryBar(step: _step, count: _stepCount)),
                    const SizedBox(width: 12),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
                      child: Pill(
                        key: ValueKey(_earnedXp),
                        label: '+$_earnedXp XP',
                        background: BarroColors.orangeSoft,
                        foreground: BarroColors.orangeText,
                        icon: Icons.bolt,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween(begin: const Offset(0.06, 0), end: Offset.zero).animate(animation),
                      child: child,
                    ),
                  ),
                  child: SingleChildScrollView(
                    key: ValueKey('$_step-$_question'),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: _buildStep(module),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_step == 4 && _checked)
                      FadeSlideIn(
                        key: ValueKey('fb-$_question'),
                        child: _Feedback(
                          right: _picked == q.answer,
                          combo: _combo,
                          answer: q.options[q.answer],
                        ),
                      ),
                    PrimaryButton(
                      label: _buttonLabel,
                      onPressed: _buttonAction,
                      icon: _step == _stepCount - 1 ? Icons.arrow_forward : null,
                    ),
                    if (_step == _stepCount - 1)
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('Retour au parcours',
                            style: body(14, color: BarroColors.muted, weight: FontWeight.w700)),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (_step == _stepCount - 1) const Positioned.fill(child: Confetti()),
        ],
      ),
    );
  }

  Widget _buildStep(CourseModule module) {
    switch (_step) {
      case 0:
        return _IntroStep(lesson: lesson, module: module);
      case 1:
        return _VideoStep(lesson: lesson);
      case 2:
        return _EssentialsStep(
          lesson: lesson,
          revealed: _revealed,
          onReveal: () {
            if (_revealed < lesson.essentials.length) {
              setState(() => _revealed++);
              HapticFeedback.selectionClick();
            }
          },
        );
      case 3:
        return _ActionStep(
          lesson: lesson,
          committed: _committed,
          onToggle: () {
            setState(() => _committed = !_committed);
            HapticFeedback.selectionClick();
          },
        );
      case 4:
        return _QuizStep(
          question: lesson.quiz[_question],
          index: _question,
          total: lesson.quiz.length,
          picked: _picked,
          checked: _checked,
          onPick: (i) {
            if (_checked) return;
            setState(() => _picked = i);
            HapticFeedback.selectionClick();
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

/// Barre de progression façon story, un segment par étape.
class _StoryBar extends StatelessWidget {
  final int step;
  final int count;

  const _StoryBar({required this.step, required this.count});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Étape ${step + 1} sur $count',
      child: Row(
        children: [
          for (var i = 0; i < count; i++) ...[
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 5,
                decoration: BoxDecoration(
                  color: i <= step ? BarroColors.green : BarroColors.line,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            if (i < count - 1) const SizedBox(width: 4),
          ],
        ],
      ),
    );
  }
}

class _IntroStep extends StatelessWidget {
  final Lesson lesson;
  final CourseModule module;

  const _IntroStep({required this.lesson, required this.module});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeSlideIn(
          child: Container(
            height: 210,
            decoration: BoxDecoration(color: BarroColors.greenSoft, borderRadius: BorderRadius.circular(28)),
            clipBehavior: Clip.antiAlias,
            child: HenScene(height: 210, prop: propForModule(module.number)),
          ),
        ),
        const SizedBox(height: 18),
        FadeSlideIn(index: 1, child: Text('MODULE ${module.number} · LEÇON ${lesson.number}', style: eyebrow())),
        const SizedBox(height: 6),
        FadeSlideIn(index: 1, child: Text(lesson.title, style: display(27))),
        const SizedBox(height: 16),
        FadeSlideIn(
          index: 2,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: BarroColors.orangeSoft, borderRadius: BorderRadius.circular(20)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb, color: BarroColors.orangeText),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('LE SAVAIS-TU ?', style: eyebrow(color: BarroColors.orangeText)),
                      const SizedBox(height: 6),
                      Text(lesson.hook, style: body(16, weight: FontWeight.w600, height: 1.45)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        FadeSlideIn(
          index: 3,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Meta(icon: Icons.schedule, label: '${lesson.minutes} min'),
              _Meta(icon: Icons.format_list_numbered, label: '${lesson.essentials.length} points clés'),
              _Meta(icon: Icons.quiz_outlined, label: '${lesson.quiz.length} questions'),
            ],
          ),
        ),
      ],
    );
  }
}

class _Meta extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Meta({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: BarroColors.soft, borderRadius: BorderRadius.circular(99)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: BarroColors.muted),
          const SizedBox(width: 6),
          Text(label, style: body(13, weight: FontWeight.w700, height: 1.2)),
        ],
      ),
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
        Text('Regarde la démonstration', style: display(24)),
        const SizedBox(height: 6),
        Text('Quelques minutes pour voir les bons gestes.', style: body(14, color: BarroColors.muted)),
        const SizedBox(height: 16),
        FadeSlideIn(
          child: Tap(
            onTap: () => _open(context),
            semanticLabel: hasVideo ? 'Ouvrir la vidéo' : 'Vidéo bientôt disponible',
            child: AspectRatio(
              aspectRatio: 16 / 10,
              child: Container(
                decoration: BoxDecoration(color: BarroColors.greenDeep, borderRadius: BorderRadius.circular(26)),
                child: Stack(
                  children: [
                    const Center(child: PulsePlay()),
                    Positioned(
                      left: 14,
                      bottom: 14,
                      child: Pill(
                        label: hasVideo ? 'S\'ouvre dans YouTube' : 'Vidéo bientôt',
                        background: Colors.white,
                        foreground: BarroColors.greenDeep,
                        icon: hasVideo ? Icons.smart_display_outlined : Icons.schedule,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          hasVideo
              ? 'Regarde la vidéo, puis reviens ici : la suite de la leçon t\'attend.'
              : 'Pas encore de vidéo pour cette leçon : passe directement à l\'essentiel.',
          style: body(14, color: BarroColors.muted),
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

  @override
  Widget build(BuildContext context) {
    final total = lesson.essentials.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('L\'essentiel', style: display(24)),
        const SizedBox(height: 6),
        Text('$total points à retenir. Découvre-les un par un.', style: body(14, color: BarroColors.muted)),
        const SizedBox(height: 16),
        for (var i = 0; i < total; i++)
          i < revealed
              ? FadeSlideIn(child: _EssentialCard(number: i + 1, text: lesson.essentials[i]))
              : _HiddenCard(number: i + 1, active: i == revealed, onTap: onReveal),
        if (revealed == total)
          FadeSlideIn(
            index: 2,
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: BarroColors.green, size: 20),
                const SizedBox(width: 8),
                Text('Bravo, tu connais l\'essentiel.', style: body(14, color: BarroColors.greenText, weight: FontWeight.w800)),
              ],
            ),
          ),
      ],
    );
  }
}

class _EssentialCard extends StatelessWidget {
  final int number;
  final String text;

  const _EssentialCard({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: BarroColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 34, child: Text('$number', style: display(30, color: BarroColors.green, height: 1.0))),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: body(16, weight: FontWeight.w600, height: 1.5))),
        ],
      ),
    );
  }
}

class _HiddenCard extends StatelessWidget {
  final int number;
  final bool active;
  final VoidCallback onTap;

  const _HiddenCard({required this.number, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Tap(
        onTap: active ? onTap : null,
        semanticLabel: 'Découvrir le point $number',
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: BarroColors.soft,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: active ? BarroColors.green : BarroColors.soft, width: 1.5),
          ),
          child: Row(
            children: [
              Icon(active ? Icons.touch_app_outlined : Icons.lock_outline,
                  color: active ? BarroColors.greenText : BarroColors.faint),
              const SizedBox(width: 12),
              Text(
                active ? 'Point $number · touche pour découvrir' : 'Point $number',
                style: body(15, color: active ? BarroColors.greenText : BarroColors.faint, weight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionStep extends StatelessWidget {
  final Lesson lesson;
  final bool committed;
  final VoidCallback onToggle;

  const _ActionStep({required this.lesson, required this.committed, required this.onToggle});

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
            decoration: BoxDecoration(color: BarroColors.greenSoft, borderRadius: BorderRadius.circular(24)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.photo_camera_outlined, color: BarroColors.greenText),
                ),
                const SizedBox(height: 16),
                Text(lesson.task, style: display(19, weight: FontWeight.w600, height: 1.35)),
                const SizedBox(height: 12),
                Text('Bientôt : envoie ta photo comme preuve et gagne des XP en plus.',
                    style: body(13, color: BarroColors.inkSoft)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        FadeSlideIn(
          index: 1,
          child: Tap(
            onTap: onToggle,
            semanticLabel: 'Je m\'engage à le faire aujourd\'hui',
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: committed ? BarroColors.greenDeep : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: committed ? BarroColors.greenDeep : BarroColors.line),
              ),
              child: Row(
                children: [
                  Icon(committed ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: committed ? Colors.white : BarroColors.faint),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Je m\'engage à le faire aujourd\'hui',
                        style: body(15, color: committed ? Colors.white : BarroColors.ink, weight: FontWeight.w700)),
                  ),
                  Text('+5 XP',
                      style: body(13, color: committed ? BarroColors.sun : BarroColors.orangeText, weight: FontWeight.w800)),
                ],
              ),
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

  static const _letters = ['A', 'B', 'C', 'D', 'E'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 0; i < total; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: i == index ? 22 : 8,
                height: 8,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: i < index || (i == index && checked)
                      ? BarroColors.green
                      : (i == index ? BarroColors.greenMid : BarroColors.line),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            const Spacer(),
            Text('Question ${index + 1}/$total', style: body(13, color: BarroColors.muted, weight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 16),
        Text(question.question, style: display(22, height: 1.25)),
        const SizedBox(height: 18),
        for (var i = 0; i < question.options.length; i++)
          FadeSlideIn(index: i, child: _option(i, _letters[i % _letters.length])),
      ],
    );
  }

  Widget _option(int i, String letter) {
    Color bg = Colors.white;
    Color border = BarroColors.line;
    Color badgeBg = BarroColors.soft;
    Color badgeFg = BarroColors.ink;
    Widget badgeChild = Text(letter, style: display(14, color: badgeFg));
    double opacity = 1;

    final isAnswer = i == question.answer;
    final isPicked = picked == i;

    if (!checked && isPicked) {
      border = BarroColors.green;
      badgeBg = BarroColors.green;
      badgeChild = Text(letter, style: display(14, color: Colors.white));
    }
    if (checked) {
      if (isAnswer) {
        bg = BarroColors.greenSoft;
        border = BarroColors.green;
        badgeBg = BarroColors.green;
        badgeChild = const Icon(Icons.check, size: 16, color: Colors.white);
      } else if (isPicked) {
        bg = BarroColors.redSoft;
        border = BarroColors.red;
        badgeBg = BarroColors.red;
        badgeChild = const Icon(Icons.close, size: 16, color: Colors.white);
      } else {
        opacity = 0.55;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: opacity,
        child: Tap(
          onTap: () => onPick(i),
          semanticLabel: 'Réponse $letter : ${question.options[i]}',
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: border, width: isPicked || (checked && isAnswer) ? 2 : 1),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: badgeBg, shape: BoxShape.circle),
                  child: badgeChild,
                ),
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

class _Feedback extends StatelessWidget {
  final bool right;
  final int combo;
  final String answer;

  const _Feedback({required this.right, required this.combo, required this.answer});

  @override
  Widget build(BuildContext context) {
    final text = right
        ? (combo >= 2 ? 'Bonne réponse ! $combo d\'affilée' : 'Bonne réponse !')
        : 'Presque. La bonne réponse : $answer';
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: right ? BarroColors.greenSoft : BarroColors.redSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(right ? Icons.check_circle : Icons.info_outline, color: right ? BarroColors.green : BarroColors.red),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: body(14, color: right ? BarroColors.greenText : BarroColors.red, weight: FontWeight.w800)),
          ),
          if (right) Text('+10 XP', style: body(13, color: BarroColors.greenText, weight: FontWeight.w800)),
        ],
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
    final streak = AppState.instance.streak;
    final message = correct == total
        ? 'Parfait, tu as tout bon !'
        : correct == 0
            ? 'Pas grave : relis l\'essentiel, ça va rentrer.'
            : 'Bien joué, tu progresses.';
    final nextLesson = next;
    return Column(
      children: [
        const SizedBox(height: 8),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.5, end: 1),
          duration: const Duration(milliseconds: 700),
          curve: Curves.elasticOut,
          builder: (context, s, child) => Transform.scale(scale: s, child: child),
          child: Container(
            width: 116,
            height: 116,
            decoration: const BoxDecoration(color: BarroColors.greenDeep, shape: BoxShape.circle),
            child: const Icon(Icons.emoji_events, size: 58, color: BarroColors.sun),
          ),
        ),
        const SizedBox(height: 16),
        TweenAnimationBuilder<int>(
          tween: IntTween(begin: 0, end: xp),
          duration: const Duration(milliseconds: 900),
          builder: (context, v, _) => Text('+$v XP', style: display(44, color: BarroColors.green, weight: FontWeight.w800)),
        ),
        const SizedBox(height: 4),
        Text('$correct bonne${correct > 1 ? 's' : ''} réponse${correct > 1 ? 's' : ''} sur $total',
            style: body(16, weight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(message, textAlign: TextAlign.center, style: body(14, color: BarroColors.muted)),
        const SizedBox(height: 14),
        Pill(
          label: 'Série : $streak jour${streak > 1 ? 's' : ''}',
          background: BarroColors.orangeSoft,
          foreground: BarroColors.orangeText,
          icon: Icons.local_fire_department,
        ),
        const SizedBox(height: 20),
        if (nextLesson != null)
          FadeSlideIn(
            index: 3,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: BarroColors.line),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('DANS LA PROCHAINE LEÇON', style: eyebrow()),
                        const SizedBox(height: 6),
                        Text(nextLesson.title, style: display(17, height: 1.25)),
                        const SizedBox(height: 6),
                        Text(nextLesson.hook,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: body(14, color: BarroColors.muted, height: 1.4)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(color: BarroColors.greenSoft, borderRadius: BorderRadius.circular(18)),
                    clipBehavior: Clip.antiAlias,
                    child: HenScene(
                      height: 84,
                      compact: true,
                      prop: propForModule(AppState.instance.moduleOf(nextLesson).number),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: BarroColors.greenDeep, borderRadius: BorderRadius.circular(20)),
            child: Text('Tu as fini les 15 leçons ! L\'examen final arrive bientôt pour obtenir ton attestation.',
                style: body(15, color: Colors.white, weight: FontWeight.w700)),
          ),
      ],
    );
  }
}

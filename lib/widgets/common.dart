import 'package:flutter/material.dart';

import '../state.dart';
import '../theme.dart';
import 'backgrounds.dart';

/// Transition fluide entre les écrans : fondu et léger glissement.
Route<T> barroRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 240),
    pageBuilder: (context, animation, secondary) => page,
    transitionsBuilder: (context, animation, secondary, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween(begin: const Offset(0.05, 0), end: Offset.zero).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// Initiale affichée dans l'avatar.
String initialOf(String name) {
  final n = name.trim();
  return n.isEmpty ? 'B' : n.characters.first.toUpperCase();
}

/// Zone touchable qui se tasse légèrement quand on appuie dessus.
class Tap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;

  const Tap({super.key, required this.child, this.onTap, this.semanticLabel});

  @override
  State<Tap> createState() => _TapState();
}

class _TapState extends State<Tap> {
  bool _down = false;

  void _set(bool v) {
    if (widget.onTap == null || _down == v) return;
    setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: widget.onTap != null,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _down ? 0.97 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Barre de progression arrondie et animée.
class BarroProgressBar extends StatelessWidget {
  final double value;
  final Color color;
  final Color track;
  final double height;

  const BarroProgressBar({
    super.key,
    required this.value,
    this.color = BarroColors.green,
    this.track = BarroColors.greenMid,
    this.height = 6,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value.clamp(0.0, 1.0).toDouble()),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutCubic,
        builder: (context, v, _) => LinearProgressIndicator(
          value: v,
          minHeight: height,
          color: color,
          backgroundColor: track,
        ),
      ),
    );
  }
}

/// Petite étiquette arrondie.
class Pill extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final IconData? icon;

  const Pill({super.key, required this.label, required this.background, required this.foreground, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(99)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 5),
          ],
          Text(label, style: body(12, color: foreground, weight: FontWeight.w800, height: 1.2)),
        ],
      ),
    );
  }
}

/// Bouton rond à icône, bordé.
class RoundIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const RoundIconButton({super.key, required this.icon, required this.tooltip, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(side: BorderSide(color: BarroColors.line)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(width: 44, height: 44, child: Icon(icon, size: 20, color: BarroColors.ink)),
        ),
      ),
    );
  }
}

/// Avatar rond avec l'initiale de l'apprenant.
class AvatarButton extends StatelessWidget {
  final VoidCallback onPressed;

  const AvatarButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) => Tooltip(
        message: 'Mon profil et paramètres',
        child: Material(
          color: BarroColors.greenDeep,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Center(child: Text(initialOf(state.learnerName), style: display(16, color: Colors.white))),
            ),
          ),
        ),
      ),
    );
  }
}

/// Gros bouton d'action, vert profond.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color color;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color = BarroColors.greenDeep,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: BarroColors.line,
          disabledForegroundColor: BarroColors.faint,
          shape: const StadiumBorder(),
          elevation: 0,
          textStyle: body(16, weight: FontWeight.w800),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
            Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }
}

/// En-tête fixe en haut de chaque écran : il ne défile pas avec le contenu.
class TabHeader extends StatelessWidget {
  final Widget title;
  final List<Widget> actions;
  final VoidCallback? onBack;
  final Widget? bottom;

  const TabHeader({super.key, required this.title, this.actions = const [], this.onBack, this.bottom});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: BarroColors.line)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Row(
              children: [
                if (onBack != null) ...[
                  RoundIconButton(icon: Icons.arrow_back, tooltip: 'Retour', onPressed: onBack!),
                  const SizedBox(width: 12),
                ],
                Expanded(child: title),
                for (final a in actions) ...[const SizedBox(width: 10), a],
              ],
            ),
          ),
          if (bottom != null) ...[const SizedBox(height: 12), bottom!],
        ],
      ),
    );
  }
}

/// Page secondaire (ouverte par-dessus les onglets).
class BarroPage extends StatelessWidget {
  final Widget child;

  const BarroPage({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BarroColors.bg,
      body: BarroBackground(child: SafeArea(child: child)),
    );
  }
}

/// Apparition douce, décalée selon [index]. Coupée si l'utilisateur réduit les animations.
class FadeSlideIn extends StatelessWidget {
  final Widget child;
  final int index;

  const FadeSlideIn({super.key, required this.child, this.index = 0});

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 360 + (index < 0 ? 0 : (index > 10 ? 10 : index)) * 70),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, (1 - v) * 16), child: child),
      ),
      child: child,
    );
  }
}

/// Titre de section.
class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;

  const SectionTitle(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: Text(text, style: display(17))),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Carré arrondi teinté avec une icône.
class SoftIcon extends StatelessWidget {
  final IconData icon;
  final Color tint;
  final Color color;
  final double size;

  const SoftIcon({super.key, required this.icon, required this.tint, required this.color, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(size * 0.3)),
      child: Icon(icon, size: size * 0.5, color: color),
    );
  }
}

/// Bande « série · leçons · XP », partagée par l'accueil et les progrès.
class StatsStrip extends StatelessWidget {
  const StatsStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppState.instance;
    Widget cell(int value, String label, Color color, {bool divider = true}) {
      return Expanded(
        child: Container(
          decoration: BoxDecoration(
            border: divider ? const Border(right: BorderSide(color: BarroColors.line)) : null,
          ),
          child: Column(
            children: [
              TweenAnimationBuilder<int>(
                tween: IntTween(begin: 0, end: value),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (context, v, _) => Text('$v', style: display(20, color: color)),
              ),
              const SizedBox(height: 2),
              Text(label, style: body(12, color: BarroColors.muted)),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(color: BarroColors.soft, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          cell(s.streak, s.streak > 1 ? 'jours de série' : 'jour de série', BarroColors.orangeText),
          cell(s.completedCount, 'leçons finies', BarroColors.ink),
          cell(s.xp, 'XP gagnés', BarroColors.greenText, divider: false),
        ],
      ),
    );
  }
}

void showSoon(BuildContext context, String what) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text('$what arrive bientôt sur BARRO.')));
}

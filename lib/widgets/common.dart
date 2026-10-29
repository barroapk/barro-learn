import 'package:flutter/material.dart';

import '../theme.dart';
import 'backgrounds.dart';

/// Barre de progression arrondie.
class BarroProgressBar extends StatelessWidget {
  final double value;
  final Color color;
  final Color track;
  final double height;

  const BarroProgressBar({
    super.key,
    required this.value,
    this.color = BarroColors.green,
    this.track = BarroColors.border,
    this.height = 8,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value.clamp(0.0, 1.0).toDouble()),
        duration: const Duration(milliseconds: 700),
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

/// Petite étiquette arrondie (ex. « 5 jours », « +20 XP »).
class Pill extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final IconData? icon;

  const Pill({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(99)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: foreground),
            const SizedBox(width: 6),
          ],
          Text(label, style: body(13, color: foreground, weight: FontWeight.w800)),
        ],
      ),
    );
  }
}

/// Bouton carré à icône (recherche, notifications, retour…).
class SquareIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const SquareIconButton({super.key, required this.icon, required this.tooltip, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: BarroColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: BarroColors.border),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed,
          child: SizedBox(width: 44, height: 44, child: Icon(icon, size: 20, color: BarroColors.text)),
        ),
      ),
    );
  }
}

/// Gros bouton d'action en bas d'écran.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final IconData? icon;

  const PrimaryButton({super.key, required this.label, required this.onPressed, this.color = BarroColors.green, this.icon});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: BarroColors.ink,
          disabledBackgroundColor: BarroColors.border,
          disabledForegroundColor: BarroColors.muted,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: body(16, weight: FontWeight.w800),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            if (icon != null) ...[const SizedBox(width: 8), Icon(icon, size: 20)],
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
      decoration: BoxDecoration(
        color: BarroColors.bg.withValues(alpha: 0.94),
        border: const Border(bottom: BorderSide(color: BarroColors.border)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (onBack != null) ...[
                SquareIconButton(icon: Icons.arrow_back, tooltip: 'Retour', onPressed: onBack!),
                const SizedBox(width: 12),
              ],
              Expanded(child: title),
              for (final a in actions) ...[const SizedBox(width: 8), a],
            ],
          ),
          if (bottom != null) ...[const SizedBox(height: 12), bottom!],
        ],
      ),
    );
  }
}

/// Une page secondaire (ouverte par-dessus les onglets) avec le fond d'écran choisi.
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

/// Apparition douce, décalée selon [index]. Désactivée si l'utilisateur coupe les animations.
class FadeSlideIn extends StatelessWidget {
  final Widget child;
  final int index;

  const FadeSlideIn({super.key, required this.child, this.index = 0});

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 380 + index * 90),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, (1 - v) * 18), child: child),
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
      children: [
        Expanded(child: Text(text, style: display(19, weight: FontWeight.w600))),
        if (trailing != null) trailing!,
      ],
    );
  }
}

void showSoon(BuildContext context, String what) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text('$what arrive bientôt sur BARRO.')));
}

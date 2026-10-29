import 'package:flutter/material.dart';

import '../theme.dart';

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
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0).toDouble(),
        minHeight: height,
        color: color,
        backgroundColor: track,
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

  const PrimaryButton({super.key, required this.label, required this.onPressed, this.color = BarroColors.green});

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
        child: Text(label),
      ),
    );
  }
}

void showSoon(BuildContext context, String what) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text('$what arrive bientôt sur BARRO.')));
}

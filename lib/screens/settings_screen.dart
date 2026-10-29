import 'package:flutter/material.dart';

import '../state.dart';
import '../theme.dart';
import '../widgets/backgrounds.dart';
import '../widgets/common.dart';

/// Paramètres de l'apprenant, sauvegardés sur le téléphone.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _name = TextEditingController(text: AppState.instance.learnerName);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _confirmReset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: BarroColors.surface,
        title: Text('Recommencer à zéro ?', style: display(20)),
        content: Text('Tes leçons terminées, tes XP et ta série seront effacés. Tes réglages restent.',
            style: body(14, color: BarroColors.muted)),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: BarroColors.red, foregroundColor: BarroColors.ink),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Tout effacer'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      AppState.instance.resetProgress();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Progression effacée.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    return BarroPage(
      child: Column(
        children: [
          TabHeader(
            onBack: () => Navigator.of(context).pop(),
            title: Text('Paramètres', style: display(24)),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: state,
              builder: (context, _) => ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                children: [
                  const _Group('Profil'),
                  _Card(
                    children: [
                      Text('Ton prénom', style: body(14, weight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _name,
                        style: body(15),
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          hintText: 'Ex. Aminata',
                          hintStyle: body(15, color: BarroColors.muted),
                          filled: true,
                          fillColor: BarroColors.bg,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onSubmitted: state.setName,
                        onChanged: state.setName,
                      ),
                      const SizedBox(height: 6),
                      Text('Il s\'affiche sur l\'accueil et sur ta page de progrès.', style: body(12, color: BarroColors.muted)),
                    ],
                  ),
                  const _Group('Apparence'),
                  _Card(
                    children: [
                      Text('Fond d\'écran', style: body(14, weight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      GridView.count(
                        crossAxisCount: 4,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 0.62,
                        children: [
                          for (final style in BackgroundStyle.values)
                            _BackgroundChoice(
                              style: style,
                              selected: state.background == style,
                              onTap: () => state.setBackground(style),
                            ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text('Taille du texte', style: body(14, weight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<double>(
                          segments: const [
                            ButtonSegment(value: 0.9, label: Text('Petit')),
                            ButtonSegment(value: 1.0, label: Text('Normal')),
                            ButtonSegment(value: 1.15, label: Text('Grand')),
                          ],
                          selected: {state.textScale},
                          showSelectedIcon: false,
                          onSelectionChanged: (s) => state.setTextScale(s.first),
                        ),
                      ),
                    ],
                  ),
                  const _Group('Vidéos et rappels'),
                  _Card(
                    padding: EdgeInsets.zero,
                    children: [
                      SwitchListTile(
                        value: state.dataSaver,
                        onChanged: state.setDataSaver,
                        title: Text('Économiser les données', style: body(15, weight: FontWeight.w700)),
                        subtitle: Text('Vidéos en qualité réduite. Actif avec le lecteur intégré (phase 2).',
                            style: body(12, color: BarroColors.muted)),
                      ),
                      const Divider(height: 1, color: BarroColors.border),
                      SwitchListTile(
                        value: state.dailyReminder,
                        onChanged: state.setDailyReminder,
                        title: Text('Rappel quotidien', style: body(15, weight: FontWeight.w700)),
                        subtitle: Text('Une notification pour garder ta série. Arrive avec la phase 4.',
                            style: body(12, color: BarroColors.muted)),
                      ),
                    ],
                  ),
                  const _Group('Langue'),
                  _Card(
                    padding: EdgeInsets.zero,
                    children: [
                      _LanguageRow(label: 'Français', selected: true, onTap: () {}),
                      const Divider(height: 1, color: BarroColors.border),
                      _LanguageRow(label: 'Mooré', selected: false, onTap: () => showSoon(context, 'Le mooré')),
                      const Divider(height: 1, color: BarroColors.border),
                      _LanguageRow(label: 'Dioula', selected: false, onTap: () => showSoon(context, 'Le dioula')),
                    ],
                  ),
                  const _Group('Progression'),
                  _Card(
                    padding: EdgeInsets.zero,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.restart_alt, color: BarroColors.red),
                        title: Text('Recommencer à zéro', style: body(15, color: BarroColors.red, weight: FontWeight.w700)),
                        subtitle: Text('Efface leçons terminées, XP et série.', style: body(12, color: BarroColors.muted)),
                        onTap: _confirmReset,
                      ),
                    ],
                  ),
                  const _Group('À propos'),
                  _Card(
                    children: [
                      Text('BARRO · version 0.2', style: body(15, weight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text('Apprendre, comprendre, créer. Une application de KOUNADIA SERVICE, Burkina Faso.',
                          style: body(13, color: BarroColors.muted)),
                      const SizedBox(height: 8),
                      Text('Les chiffres des leçons viennent de sources vérifiées. Pour les vaccins et les soins, demande toujours conseil à un vétérinaire.',
                          style: body(12, color: BarroColors.muted)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  final String text;

  const _Group(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
      child: Text(text.toUpperCase(), style: body(12, color: BarroColors.muted, weight: FontWeight.w800)),
    );
  }
}

class _Card extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsets padding;

  const _Card({required this.children, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: BarroColors.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: BarroColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}

class _BackgroundChoice extends StatelessWidget {
  final BackgroundStyle style;
  final bool selected;
  final VoidCallback onTap;

  const _BackgroundChoice({required this.style, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: 'Fond ${style.label}',
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: selected ? BarroColors.green : BarroColors.border, width: selected ? 3 : 1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: CustomPaint(painter: BackgroundPainter(style), size: Size.infinite),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(style.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: body(11, color: selected ? BarroColors.green : BarroColors.muted, weight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageRow({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label, style: body(15, weight: FontWeight.w600)),
      trailing: selected
          ? const Icon(Icons.check_circle, color: BarroColors.green)
          : Text('Bientôt', style: body(12, color: BarroColors.muted, weight: FontWeight.w700)),
      onTap: onTap,
    );
  }
}

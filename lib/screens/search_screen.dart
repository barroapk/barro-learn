import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../data/course.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'lesson_screen.dart';
import 'metiers_screen.dart';

/// Recherche dans les métiers et dans les leçons.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';

  static const _suggestions = ['poulet', 'chaleur', 'vaccin', 'prix', 'savon', 'solaire'];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static String _norm(String s) {
    const from = 'àâäéèêëîïôöùûüç';
    const to = 'aaaeeeeiioouuuc';
    var out = s.toLowerCase();
    for (var i = 0; i < from.length; i++) {
      out = out.replaceAll(from[i], to[i]);
    }
    return out;
  }

  void _setQuery(String q) {
    _controller.text = q;
    _controller.selection = TextSelection.collapsed(offset: q.length);
    setState(() => _query = q);
  }

  @override
  Widget build(BuildContext context) {
    final q = _norm(_query.trim());
    final metierHits = <(Metier, MetierCategory)>[];
    final lessonHits = <Lesson>[];
    if (q.isNotEmpty) {
      for (final c in metierCategories) {
        for (final m in c.metiers) {
          if (_norm('${m.title} ${m.subtitle} ${c.title}').contains(q)) metierHits.add((m, c));
        }
      }
      for (final l in AppState.instance.course.allLessons) {
        if (_norm('${l.title} ${l.hook} ${l.essentials.join(' ')}').contains(q)) lessonHits.add(l);
      }
    }

    return BarroPage(
      child: Column(
        children: [
          TabHeader(
            onBack: () => Navigator.of(context).pop(),
            title: TextField(
              controller: _controller,
              autofocus: true,
              style: body(16),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Métier, leçon, mot-clé…',
                hintStyle: body(16, color: BarroColors.muted),
                isDense: true,
                filled: true,
                fillColor: BarroColors.surface,
                prefixIcon: const Icon(Icons.search, color: BarroColors.muted),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Effacer',
                        icon: const Icon(Icons.close, color: BarroColors.muted),
                        onPressed: () => _setQuery(''),
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: BarroColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: BarroColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: BarroColors.green, width: 2),
                ),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                if (q.isEmpty) ...[
                  Text('Recherches fréquentes', style: body(13, color: BarroColors.muted, weight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final s in _suggestions)
                        ActionChip(
                          label: Text(s, style: body(14, weight: FontWeight.w600)),
                          backgroundColor: BarroColors.surface,
                          side: const BorderSide(color: BarroColors.border),
                          onPressed: () => _setQuery(s),
                        ),
                    ],
                  ),
                ],
                if (q.isNotEmpty && metierHits.isEmpty && lessonHits.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: Text('Aucun résultat pour « $_query ». Essaie un autre mot, par exemple « poulet ».',
                        style: body(15, color: BarroColors.muted)),
                  ),
                if (metierHits.isNotEmpty) ...[
                  Text('Métiers', style: display(18, weight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  for (final hit in metierHits) MetierTile(metier: hit.$1, category: hit.$2),
                  const SizedBox(height: 16),
                ],
                if (lessonHits.isNotEmpty) ...[
                  Text('Leçons', style: display(18, weight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  for (final l in lessonHits) _LessonHit(lesson: l),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonHit extends StatelessWidget {
  final Lesson lesson;

  const _LessonHit({required this.lesson});

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    final unlocked = state.isUnlocked(lesson.number);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: BarroColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          leading: CircleAvatar(
            backgroundColor: unlocked ? BarroColors.blue : BarroColors.border,
            child: Icon(unlocked ? Icons.play_arrow_rounded : Icons.lock_outline,
                color: unlocked ? BarroColors.ink : BarroColors.muted),
          ),
          title: Text(lesson.title, style: body(15, weight: FontWeight.w700)),
          subtitle: Text('Leçon ${lesson.number} · Poulets de chair', style: body(12, color: BarroColors.muted)),
          onTap: () {
            if (unlocked) {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => LessonScreen(lesson: lesson)));
            } else {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(const SnackBar(content: Text('Cette leçon s\'ouvre quand tu as fini la précédente.')));
            }
          },
        ),
      ),
    );
  }
}

/// Raccourci utilisé par l'accueil pour ouvrir une catégorie.
void openMetiers(BuildContext context, {int? category}) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => MetiersScreen(initialCategory: category)));
}

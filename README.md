# BARRO — Apprendre, comprendre, créer

Application mobile de micro-apprentissage pratique pour l'Afrique (Flutter). Projet de KOUNADIA SERVICE.

## Ce qui marche (phase 1)

- 4 onglets : Accueil, Explorer, Apprendre, Progrès.
- Parcours 1 « Élevage de poulets de chair » : 3 modules, 15 leçons.
- Leçon pas à pas : accroche + vidéo, l'essentiel, à toi de faire, quiz, récompense en XP.
- Les leçons se débloquent l'une après l'autre.

## Compiler

Chaque envoi sur la branche `main` lance GitHub Actions (onglet **Actions**), qui génère la partie Android, vérifie le code, lance les tests et compile l'APK. L'APK se télécharge dans l'artefact **barro-apk** du dernier lancement.

## Organisation du code

| Dossier | Contenu |
| --- | --- |
| `lib/main.dart` | Démarrage et les 4 onglets |
| `lib/theme.dart` | Couleurs et polices |
| `lib/state.dart` | Progression de l'apprenant (XP, leçons finies) |
| `lib/data/` | Modèles et contenu du parcours poulet |
| `lib/screens/` | Un fichier par écran |
| `lib/widgets/` | Petits éléments réutilisés |

## Prochaines phases

2. Contenu dans Supabase + lecteur YouTube intégré
3. Illustrations dessinées pour chaque leçon
4. XP, séries, badges et progression sauvegardée
5. Espace administrateur
6. Test avec 10 à 20 apprenants

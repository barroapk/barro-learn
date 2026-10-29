import 'package:flutter/material.dart';

import 'screens/course_screen.dart';
import 'screens/explore_screen.dart';
import 'screens/home_screen.dart';
import 'screens/progress_screen.dart';
import 'theme.dart';

void main() {
  runApp(const BarroApp());
}

class BarroApp extends StatelessWidget {
  const BarroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BARRO',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const HomeShell(),
    );
  }
}

/// La coque de l'app : les 4 onglets du bas.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  void _openTab(int index) => setState(() => _tab = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _tab,
          children: [
            HomeScreen(onOpenTab: _openTab),
            ExploreScreen(onOpenTab: _openTab),
            const CourseScreen(),
            const ProgressScreen(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: _openTab,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Accueil'),
          NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore), label: 'Explorer'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'Apprendre'),
          NavigationDestination(icon: Icon(Icons.emoji_events_outlined), selectedIcon: Icon(Icons.emoji_events), label: 'Progrès'),
        ],
      ),
    );
  }
}

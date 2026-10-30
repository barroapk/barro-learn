import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/course_screen.dart';
import 'screens/explore_screen.dart';
import 'screens/home_screen.dart';
import 'screens/progress_screen.dart';
import 'state.dart';
import 'theme.dart';
import 'widgets/backgrounds.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  await AppState.instance.load();
  runApp(const BarroApp());
}

class BarroApp extends StatelessWidget {
  const BarroApp({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) => MaterialApp(
        title: 'BARRO',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        builder: (context, child) {
          final mq = MediaQuery.of(context);
          return MediaQuery(
            data: mq.copyWith(textScaler: TextScaler.linear(state.textScale)),
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: const HomeShell(),
      ),
    );
  }
}

/// La coque de l'app : le fond et les 4 onglets du bas, avec un fondu entre onglets.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  void _openTab(int index) {
    if (index == _tab) return;
    setState(() => _tab = index);
  }

  Widget _screen() {
    switch (_tab) {
      case 1:
        return ExploreScreen(onOpenTab: _openTab);
      case 2:
        return const CourseScreen();
      case 3:
        return const ProgressScreen();
      default:
        return HomeScreen(onOpenTab: _openTab);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BarroColors.bg,
      body: BarroBackground(
        child: SafeArea(
          bottom: false,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: KeyedSubtree(key: ValueKey(_tab), child: _screen()),
          ),
        ),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: BarroColors.line))),
        child: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: _openTab,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Accueil'),
            NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore), label: 'Explorer'),
            NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'Apprendre'),
            NavigationDestination(
                icon: Icon(Icons.emoji_events_outlined), selectedIcon: Icon(Icons.emoji_events), label: 'Progrès'),
          ],
        ),
      ),
    );
  }
}

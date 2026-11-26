import 'package:flutter/material.dart';

import 'live_teacher/live_teacher_screen.dart';
import 'theme.dart';

/// Point d'entrée de l'APK de test « BARRO Live » (n'affecte pas l'app BARRO).
void main() {
  runApp(MaterialApp(
    title: 'BARRO Live',
    debugShowCheckedModeBanner: false,
    theme: buildTheme(),
    home: const LiveTeacherScreen(),
  ));
}

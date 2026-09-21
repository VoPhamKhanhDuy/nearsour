import 'package:flutter/material.dart';

import 'screens/welcome/welcome_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const NearSoulApp());
}

class NearSoulApp extends StatelessWidget {
  const NearSoulApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NearSoul',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const WelcomeScreen(),
    );
  }
}

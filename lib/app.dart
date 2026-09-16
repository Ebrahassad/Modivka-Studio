import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

class ModivkaApp extends StatelessWidget {
  const ModivkaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Modivka Studio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFF7C4DFF),
        scaffoldBackgroundColor: const Color(0xFF0B0B10),
      ),
      home: const HomeScreen(),
    );
  }
}

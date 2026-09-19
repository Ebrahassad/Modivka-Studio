import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

class ModivkaApp extends StatelessWidget {
  const ModivkaApp({super.key});

  static const _background = Color(0xFF08070D);
  static const _surface = Color(0xFF10101A);
  static const _primary = Color(0xFF6557FF);
  static const _secondary = Color(0xFFA649FF);

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _primary,
      brightness: Brightness.dark,
    ).copyWith(
      primary: _primary,
      secondary: _secondary,
      surface: _surface,
      onSurface: Colors.white,
    );

    return MaterialApp(
      title: 'Modivka Studio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: scheme,
        scaffoldBackgroundColor: _background,
        canvasColor: _background,
        dividerColor: Colors.white12,
        splashFactory: InkSparkle.splashFactory,
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFF11111A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            borderSide: BorderSide(color: Colors.white12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            borderSide: BorderSide(color: _primary, width: 1.5),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

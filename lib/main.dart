import 'package:flutter/material.dart';

import 'screens/practice_screen.dart';

void main() {
  runApp(const SciBowlQuizzerApp());
}

class SciBowlQuizzerApp extends StatelessWidget {
  const SciBowlQuizzerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SciBowl Quizzer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF116466),
          surface: const Color(0xFFFAFAF7),
        ),
        scaffoldBackgroundColor: const Color(0xFFFAFAF7),
        fontFamily: 'Roboto',
        cardTheme: const CardThemeData(elevation: 0, margin: EdgeInsets.zero),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        segmentedButtonTheme: SegmentedButtonThemeData(
          style: ButtonStyle(
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),
        useMaterial3: true,
      ),
      home: const PracticeScreen(),
    );
  }
}

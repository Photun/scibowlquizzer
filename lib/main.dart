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
      theme: _buildDarkTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: ThemeMode.dark,
      home: const PracticeScreen(),
    );
  }
}

ThemeData _buildDarkTheme() {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF2EE6A6),
      brightness: Brightness.dark,
      surface: const Color(0xFF101722),
    ),
    scaffoldBackgroundColor: const Color(0xFF071018),
    fontFamily: 'Roboto',
    cardTheme: const CardThemeData(elevation: 0, margin: EdgeInsets.zero),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 48),
        foregroundColor: const Color(0xFF061014),
        backgroundColor: const Color(0xFF2EE6A6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: const Color(0xFFBFFFE7),
        backgroundColor: const Color(0xFF152334),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFF2EE6A6).withValues(alpha: 0.18);
          }
          return const Color(0xFF121C28);
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFFBFFFE7);
          }
          return const Color(0xFFD5DEE8);
        }),
        side: WidgetStateProperty.resolveWith((states) {
          final color = states.contains(WidgetState.selected)
              ? const Color(0xFF2EE6A6)
              : const Color(0xFF263545);
          return BorderSide(color: color);
        }),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    ),
    useMaterial3: true,
  );
}

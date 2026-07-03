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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF116466)),
        useMaterial3: true,
      ),
      home: const PracticeScreen(),
    );
  }
}

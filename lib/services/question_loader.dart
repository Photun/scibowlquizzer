import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/science_question.dart';

class QuestionLoader {
  const QuestionLoader({this.assetPath = 'assets/questions/questions.json'});

  final String assetPath;

  Future<List<ScienceQuestion>> load({bool includeNeedsReview = false}) async {
    final rawJson = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(rawJson) as List<dynamic>;

    final questions = decoded
        .map((item) => ScienceQuestion.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);

    if (includeNeedsReview) {
      return questions;
    }

    return questions
        .where((question) => !question.needsReview)
        .toList(growable: false);
  }
}

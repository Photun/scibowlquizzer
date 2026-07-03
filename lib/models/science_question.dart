enum QuestionType {
  multipleChoice('Multiple Choice'),
  shortAnswer('Short Answer');

  const QuestionType(this.label);

  final String label;

  static QuestionType fromJson(String value) {
    return QuestionType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => QuestionType.shortAnswer,
    );
  }
}

class QuestionChoice {
  const QuestionChoice({required this.label, required this.text});

  final String label;
  final String text;

  String get displayText => '$label) $text';

  factory QuestionChoice.fromJson(Map<String, dynamic> json) {
    return QuestionChoice(
      label: json['label'] as String,
      text: json['text'] as String,
    );
  }
}

class ScienceQuestion {
  const ScienceQuestion({
    required this.id,
    required this.setId,
    required this.questionNumber,
    required this.category,
    required this.type,
    required this.question,
    required this.answer,
    required this.answerLabel,
    required this.choices,
  });

  final String id;
  final String setId;
  final String questionNumber;
  final String category;
  final QuestionType type;
  final String question;
  final String answer;
  final String? answerLabel;
  final List<QuestionChoice> choices;

  bool get hasChoices =>
      type == QuestionType.multipleChoice && choices.isNotEmpty;
  String get sourceLabel => 'Set $setId • #$questionNumber';

  factory ScienceQuestion.fromJson(Map<String, dynamic> json) {
    return ScienceQuestion(
      id: json['id'] as String,
      setId: json['setId'] as String? ?? '',
      questionNumber: json['questionNumber'] as String? ?? '',
      category: json['category'] as String? ?? 'General Science',
      type: QuestionType.fromJson(json['type'] as String? ?? 'shortAnswer'),
      question: json['question'] as String,
      answer: json['answer'] as String,
      answerLabel: json['answerLabel'] as String?,
      choices: (json['choices'] as List<dynamic>? ?? const [])
          .map(
            (choice) => QuestionChoice.fromJson(choice as Map<String, dynamic>),
          )
          .toList(growable: false),
    );
  }
}

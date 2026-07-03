import 'dart:math';

import 'package:flutter/material.dart';

import '../models/science_question.dart';
import '../services/question_loader.dart';

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  final _loader = const QuestionLoader();
  final _random = Random();

  List<ScienceQuestion> _questions = const [];
  ScienceQuestion? _current;
  QuestionType? _typeFilter;
  String _category = 'All';
  bool _showAnswer = false;
  String? _selectedChoiceLabel;
  int _attempted = 0;
  int _correct = 0;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    final questions = await _loader.load();
    if (!mounted) {
      return;
    }

    setState(() {
      _questions = questions;
      _current = questions.firstOrNull;
    });
  }

  Map<String, int> get _categoryCounts {
    final counts = <String, int>{};
    for (final question in _questions) {
      counts.update(question.category, (count) => count + 1, ifAbsent: () => 1);
    }
    return counts;
  }

  List<String> get _categories {
    final categories = _categoryCounts.keys.toList()..sort();
    return ['All', ...categories];
  }

  List<ScienceQuestion> get _filteredQuestions {
    return _questions
        .where((question) {
          final matchesCategory =
              _category == 'All' || question.category == _category;
          final matchesType =
              _typeFilter == null || question.type == _typeFilter;
          return matchesCategory && matchesType;
        })
        .toList(growable: false);
  }

  void _nextQuestion() {
    final pool = _filteredQuestions;
    if (pool.isEmpty) {
      setState(() {
        _current = null;
        _showAnswer = false;
        _selectedChoiceLabel = null;
      });
      return;
    }

    final current = _current;
    final usablePool = current == null || pool.length == 1
        ? pool
        : pool
              .where((question) => question.id != current.id)
              .toList(growable: false);

    setState(() {
      _current = usablePool[_random.nextInt(usablePool.length)];
      _showAnswer = false;
      _selectedChoiceLabel = null;
    });
  }

  void _chooseCategory(String category) {
    setState(() {
      _category = category;
      _showAnswer = false;
      _selectedChoiceLabel = null;
    });
    _nextQuestion();
  }

  void _chooseType(QuestionType? type) {
    setState(() {
      _typeFilter = type;
      _showAnswer = false;
      _selectedChoiceLabel = null;
    });
    _nextQuestion();
  }

  void _checkChoice(QuestionChoice choice) {
    final current = _current;
    if (current == null || _showAnswer) {
      return;
    }

    final isCorrect = choice.label == current.answerLabel;
    setState(() {
      _selectedChoiceLabel = choice.label;
      _showAnswer = true;
      _attempted += 1;
      if (isCorrect) {
        _correct += 1;
      }
    });
  }

  void _revealAnswer() {
    setState(() {
      _showAnswer = true;
    });
  }

  void _markShortAnswer(bool correct) {
    setState(() {
      _attempted += 1;
      if (correct) {
        _correct += 1;
      }
    });
    _nextQuestion();
  }

  @override
  Widget build(BuildContext context) {
    final current = _current;
    final filteredCount = _filteredQuestions.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Science Bowl Practice'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: Text('$_correct / $_attempted')),
          ),
        ],
      ),
      body: SafeArea(
        child: _questions.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _PracticeSummary(
                    totalCount: _questions.length,
                    filteredCount: filteredCount,
                    attempted: _attempted,
                    correct: _correct,
                  ),
                  const SizedBox(height: 16),
                  _CategoryFilter(
                    categories: _categories,
                    counts: _categoryCounts,
                    selectedCategory: _category,
                    totalCount: _questions.length,
                    onChanged: _chooseCategory,
                  ),
                  const SizedBox(height: 12),
                  _TypeFilter(
                    selectedType: _typeFilter,
                    onChanged: _chooseType,
                  ),
                  const SizedBox(height: 16),
                  if (current == null)
                    const Center(child: Text('No questions match this filter.'))
                  else
                    _QuestionCard(
                      question: current,
                      selectedChoiceLabel: _selectedChoiceLabel,
                      showAnswer: _showAnswer,
                      onChoiceSelected: _checkChoice,
                      onRevealAnswer: _revealAnswer,
                      onShortAnswerMarked: _markShortAnswer,
                      onNextQuestion: _nextQuestion,
                    ),
                ],
              ),
      ),
    );
  }
}

class _PracticeSummary extends StatelessWidget {
  const _PracticeSummary({
    required this.totalCount,
    required this.filteredCount,
    required this.attempted,
    required this.correct,
  });

  final int totalCount;
  final int filteredCount;
  final int attempted;
  final int correct;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accuracy = attempted == 0 ? 0 : (correct / attempted * 100).round();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 24,
          runSpacing: 12,
          children: [
            _SummaryStat(label: 'Bank', value: '$totalCount'),
            _SummaryStat(label: 'Filtered', value: '$filteredCount'),
            _SummaryStat(label: 'Score', value: '$correct / $attempted'),
            _SummaryStat(label: 'Accuracy', value: '$accuracy%'),
          ],
        ),
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 120,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelMedium),
          Text(value, style: theme.textTheme.titleLarge),
        ],
      ),
    );
  }
}

class _CategoryFilter extends StatelessWidget {
  const _CategoryFilter({
    required this.categories,
    required this.counts,
    required this.selectedCategory,
    required this.totalCount,
    required this.onChanged,
  });

  final List<String> categories;
  final Map<String, int> counts;
  final String selectedCategory;
  final int totalCount;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SegmentedButton<String>(
        segments: [
          for (final category in categories)
            ButtonSegment<String>(
              value: category,
              label: Text(
                '$category (${category == 'All' ? totalCount : counts[category]})',
              ),
            ),
        ],
        selected: {selectedCategory},
        showSelectedIcon: false,
        onSelectionChanged: (selection) => onChanged(selection.first),
      ),
    );
  }
}

class _TypeFilter extends StatelessWidget {
  const _TypeFilter({required this.selectedType, required this.onChanged});

  final QuestionType? selectedType;
  final ValueChanged<QuestionType?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SegmentedButton<QuestionType?>(
        segments: const [
          ButtonSegment<QuestionType?>(value: null, label: Text('All Types')),
          ButtonSegment<QuestionType?>(
            value: QuestionType.multipleChoice,
            label: Text('Multiple Choice'),
          ),
          ButtonSegment<QuestionType?>(
            value: QuestionType.shortAnswer,
            label: Text('Short Answer'),
          ),
        ],
        selected: {selectedType},
        showSelectedIcon: false,
        onSelectionChanged: (selection) => onChanged(selection.first),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.question,
    required this.selectedChoiceLabel,
    required this.showAnswer,
    required this.onChoiceSelected,
    required this.onRevealAnswer,
    required this.onShortAnswerMarked,
    required this.onNextQuestion,
  });

  final ScienceQuestion question;
  final String? selectedChoiceLabel;
  final bool showAnswer;
  final ValueChanged<QuestionChoice> onChoiceSelected;
  final VoidCallback onRevealAnswer;
  final ValueChanged<bool> onShortAnswerMarked;
  final VoidCallback onNextQuestion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text(question.category)),
                Chip(label: Text(question.type.label)),
                Chip(label: Text(question.sourceLabel)),
              ],
            ),
            const SizedBox(height: 16),
            Text(question.question, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 20),
            if (question.hasChoices)
              for (final choice in question.choices) ...[
                FilledButton.tonal(
                  onPressed: showAnswer ? null : () => onChoiceSelected(choice),
                  style: FilledButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    backgroundColor: _choiceColor(context, choice),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(choice.displayText),
                  ),
                ),
                const SizedBox(height: 8),
              ]
            else
              FilledButton.icon(
                onPressed: showAnswer ? null : onRevealAnswer,
                icon: const Icon(Icons.visibility),
                label: const Text('Reveal answer'),
              ),
            if (showAnswer) ...[
              const SizedBox(height: 16),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Answer: ${question.answer}',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ),
              if (!question.hasChoices) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => onShortAnswerMarked(true),
                        icon: const Icon(Icons.check),
                        label: const Text('Got it'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: () => onShortAnswerMarked(false),
                        icon: const Icon(Icons.close),
                        label: const Text('Missed'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onNextQuestion,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Skip / next'),
            ),
          ],
        ),
      ),
    );
  }

  Color? _choiceColor(BuildContext context, QuestionChoice choice) {
    if (!showAnswer) {
      return null;
    }

    if (choice.label == question.answerLabel) {
      return Theme.of(context).colorScheme.primaryContainer;
    }

    if (choice.label == selectedChoiceLabel) {
      return Theme.of(context).colorScheme.errorContainer;
    }

    return null;
  }
}

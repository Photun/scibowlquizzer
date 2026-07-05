import 'dart:math';

import 'package:flutter/material.dart';

import '../models/science_question.dart';
import '../services/question_loader.dart';

const _appBackground = Color(0xFF071018);
const _panel = Color(0xFF101A26);
const _panelElevated = Color(0xFF142131);
const _panelSoft = Color(0xFF182637);
const _line = Color(0xFF26384A);
const _textStrong = Color(0xFFF5F8FB);
const _textMuted = Color(0xFFAAB8C6);
const _accent = Color(0xFF2EE6A6);
const _accentBlue = Color(0xFF6DA8FF);
const _warning = Color(0xFFFFC857);
const _danger = Color(0xFFFF6B6B);

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
  int _streak = 0;

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

  List<ScienceQuestion> get _filteredQuestions =>
      _questionsFor(category: _category, type: _typeFilter);

  List<ScienceQuestion> _questionsFor({
    required String category,
    required QuestionType? type,
  }) {
    return _questions
        .where((question) {
          final matchesCategory =
              category == 'All' || question.category == category;
          final matchesType = type == null || question.type == type;
          return matchesCategory && matchesType;
        })
        .toList(growable: false);
  }

  ScienceQuestion? _pickQuestion(List<ScienceQuestion> pool) {
    if (pool.isEmpty) {
      return null;
    }

    final current = _current;
    final usablePool = current == null || pool.length == 1
        ? pool
        : pool
              .where((question) => question.id != current.id)
              .toList(growable: false);

    return usablePool[_random.nextInt(usablePool.length)];
  }

  void _nextQuestion() {
    final next = _pickQuestion(_filteredQuestions);
    setState(() {
      _current = next;
      _showAnswer = false;
      _selectedChoiceLabel = null;
    });
  }

  void _chooseCategory(String category) {
    final pool = _questionsFor(category: category, type: _typeFilter);
    setState(() {
      _category = category;
      _current = _pickQuestion(pool);
      _showAnswer = false;
      _selectedChoiceLabel = null;
    });
  }

  void _chooseType(QuestionType? type) {
    final pool = _questionsFor(category: _category, type: type);
    setState(() {
      _typeFilter = type;
      _current = _pickQuestion(pool);
      _showAnswer = false;
      _selectedChoiceLabel = null;
    });
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
        _streak += 1;
      } else {
        _streak = 0;
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
        _streak += 1;
      } else {
        _streak = 0;
      }
    });
    _nextQuestion();
  }

  void _resetSession() {
    setState(() {
      _attempted = 0;
      _correct = 0;
      _streak = 0;
      _showAnswer = false;
      _selectedChoiceLabel = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredCount = _filteredQuestions.length;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF071018),
                    Color(0xFF0D1722),
                    Color(0xFF09131D),
                    Color(0xFF101827),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: ColorFiltered(
              colorFilter: const ColorFilter.mode(
                Color(0xFF071018),
                BlendMode.multiply,
              ),
              child: Image.asset(
                'assets/images/science_texture.png',
                fit: BoxFit.cover,
                opacity: const AlwaysStoppedAnimation(0.2),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: _appBackground.withValues(alpha: 0.72),
              ),
            ),
          ),
          SafeArea(
            child: _questions.isEmpty
                ? const _LoadingView()
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 920;

                      return SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          isWide ? 32 : 16,
                          20,
                          isWide ? 32 : 16,
                          28,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1180),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _TopBar(
                                  totalCount: _questions.length,
                                  attempted: _attempted,
                                  correct: _correct,
                                  streak: _streak,
                                  onReset: _resetSession,
                                ),
                                const SizedBox(height: 22),
                                if (isWide)
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        width: 318,
                                        child: _ControlPanel(
                                          totalCount: _questions.length,
                                          filteredCount: filteredCount,
                                          attempted: _attempted,
                                          correct: _correct,
                                          streak: _streak,
                                          categories: _categories,
                                          counts: _categoryCounts,
                                          selectedCategory: _category,
                                          selectedType: _typeFilter,
                                          onCategoryChanged: _chooseCategory,
                                          onTypeChanged: _chooseType,
                                        ),
                                      ),
                                      const SizedBox(width: 22),
                                      Expanded(
                                        child: _QuestionArea(
                                          current: _current,
                                          selectedChoiceLabel:
                                              _selectedChoiceLabel,
                                          showAnswer: _showAnswer,
                                          onChoiceSelected: _checkChoice,
                                          onRevealAnswer: _revealAnswer,
                                          onShortAnswerMarked: _markShortAnswer,
                                          onNextQuestion: _nextQuestion,
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      _ControlPanel(
                                        totalCount: _questions.length,
                                        filteredCount: filteredCount,
                                        attempted: _attempted,
                                        correct: _correct,
                                        streak: _streak,
                                        categories: _categories,
                                        counts: _categoryCounts,
                                        selectedCategory: _category,
                                        selectedType: _typeFilter,
                                        onCategoryChanged: _chooseCategory,
                                        onTypeChanged: _chooseType,
                                      ),
                                      const SizedBox(height: 16),
                                      _QuestionArea(
                                        current: _current,
                                        selectedChoiceLabel:
                                            _selectedChoiceLabel,
                                        showAnswer: _showAnswer,
                                        onChoiceSelected: _checkChoice,
                                        onRevealAnswer: _revealAnswer,
                                        onShortAnswerMarked: _markShortAnswer,
                                        onNextQuestion: _nextQuestion,
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.totalCount,
    required this.attempted,
    required this.correct,
    required this.streak,
    required this.onReset,
  });

  final int totalCount;
  final int attempted;
  final int correct;
  final int streak;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accuracy = attempted == 0 ? 0 : (correct / attempted * 100).round();

    return Wrap(
      spacing: 16,
      runSpacing: 14,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2EE6A6), Color(0xFF2B7FFF)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _accent.withValues(alpha: 0.32),
                    blurRadius: 28,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const SizedBox(
                width: 52,
                height: 52,
                child: Icon(Icons.bolt, color: Colors.white, size: 28),
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Science Bowl Practice',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                    color: _textStrong,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_formatCount(totalCount)} questions ready',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: _textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _HeaderPill(
              icon: Icons.check_circle,
              label: '$correct / $attempted',
            ),
            _HeaderPill(
              icon: Icons.local_fire_department,
              label: '$streak streak',
            ),
            _HeaderPill(icon: Icons.speed, label: '$accuracy%'),
            Tooltip(
              message: 'Reset session',
              child: IconButton.filledTonal(
                onPressed: onReset,
                icon: const Icon(Icons.refresh),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeaderPill extends StatelessWidget {
  const _HeaderPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: _panelElevated.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: _accent),
            const SizedBox(width: 7),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(color: _textStrong),
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlPanel extends StatelessWidget {
  const _ControlPanel({
    required this.totalCount,
    required this.filteredCount,
    required this.attempted,
    required this.correct,
    required this.streak,
    required this.categories,
    required this.counts,
    required this.selectedCategory,
    required this.selectedType,
    required this.onCategoryChanged,
    required this.onTypeChanged,
  });

  final int totalCount;
  final int filteredCount;
  final int attempted;
  final int correct;
  final int streak;
  final List<String> categories;
  final Map<String, int> counts;
  final String selectedCategory;
  final QuestionType? selectedType;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<QuestionType?> onTypeChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PracticeSummary(
          totalCount: totalCount,
          filteredCount: filteredCount,
          attempted: attempted,
          correct: correct,
          streak: streak,
        ),
        const SizedBox(height: 16),
        _TypeFilter(selectedType: selectedType, onChanged: onTypeChanged),
        const SizedBox(height: 16),
        _CategoryGrid(
          categories: categories,
          counts: counts,
          selectedCategory: selectedCategory,
          totalCount: totalCount,
          onChanged: onCategoryChanged,
        ),
      ],
    );
  }
}

class _PracticeSummary extends StatelessWidget {
  const _PracticeSummary({
    required this.totalCount,
    required this.filteredCount,
    required this.attempted,
    required this.correct,
    required this.streak,
  });

  final int totalCount;
  final int filteredCount;
  final int attempted;
  final int correct;
  final int streak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accuracy = attempted == 0 ? 0.0 : correct / attempted;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: _panel.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _AccuracyRing(value: accuracy),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$correct correct',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: _textStrong,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$attempted attempted',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: _textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _MetricTile(
                  icon: Icons.inventory_2,
                  label: 'Bank',
                  value: _formatCount(totalCount),
                ),
                _MetricTile(
                  icon: Icons.filter_alt,
                  label: 'Active',
                  value: _formatCount(filteredCount),
                ),
                _MetricTile(
                  icon: Icons.local_fire_department,
                  label: 'Streak',
                  value: '$streak',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AccuracyRing extends StatelessWidget {
  const _AccuracyRing({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = (value * 100).round();

    return SizedBox(
      width: 78,
      height: 78,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 78,
            height: 78,
            child: CircularProgressIndicator(
              value: value,
              strokeWidth: 8,
              strokeCap: StrokeCap.round,
              backgroundColor: _panelSoft,
              color: _accent,
            ),
          ),
          Text(
            '$percent%',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: _textStrong,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 86,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _panelSoft.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _line.withValues(alpha: 0.8)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: _accent),
              const SizedBox(height: 8),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(color: _textMuted),
              ),
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: _textStrong,
                ),
              ),
            ],
          ),
        ),
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
          ButtonSegment<QuestionType?>(
            value: null,
            icon: Icon(Icons.all_inclusive),
            label: Text('All'),
          ),
          ButtonSegment<QuestionType?>(
            value: QuestionType.multipleChoice,
            icon: Icon(Icons.list_alt),
            label: Text('Multiple'),
          ),
          ButtonSegment<QuestionType?>(
            value: QuestionType.shortAnswer,
            icon: Icon(Icons.edit_note),
            label: Text('Short'),
          ),
        ],
        selected: {selectedType},
        showSelectedIcon: false,
        onSelectionChanged: (selection) => onChanged(selection.first),
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 560 ? 2 : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: categories.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: columns == 1 ? 4.6 : 3.2,
          ),
          itemBuilder: (context, index) {
            final category = categories[index];
            return _CategoryTile(
              category: category,
              count: category == 'All' ? totalCount : counts[category] ?? 0,
              selected: category == selectedCategory,
              onTap: () => onChanged(category),
            );
          },
        );
      },
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String category;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visual = _categoryVisual(category);
    final foreground = selected ? Colors.white : _textStrong;

    return Material(
      color: selected
          ? visual.color.withValues(alpha: 0.92)
          : _panelElevated.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(16),
      elevation: selected ? 6 : 0,
      shadowColor: visual.color.withValues(alpha: 0.45),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.16)
                      : visual.color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SizedBox(
                  width: 38,
                  height: 38,
                  child: Icon(
                    visual.icon,
                    color: selected ? Colors.white : visual.color,
                    size: 21,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatCount(count),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: selected
                            ? Colors.white.withValues(alpha: 0.84)
                            : _textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuestionArea extends StatelessWidget {
  const _QuestionArea({
    required this.current,
    required this.selectedChoiceLabel,
    required this.showAnswer,
    required this.onChoiceSelected,
    required this.onRevealAnswer,
    required this.onShortAnswerMarked,
    required this.onNextQuestion,
  });

  final ScienceQuestion? current;
  final String? selectedChoiceLabel;
  final bool showAnswer;
  final ValueChanged<QuestionChoice> onChoiceSelected;
  final VoidCallback onRevealAnswer;
  final ValueChanged<bool> onShortAnswerMarked;
  final VoidCallback onNextQuestion;

  @override
  Widget build(BuildContext context) {
    final question = current;
    if (question == null) {
      return const _EmptyQuestionState();
    }

    return _QuestionCard(
      question: question,
      selectedChoiceLabel: selectedChoiceLabel,
      showAnswer: showAnswer,
      onChoiceSelected: onChoiceSelected,
      onRevealAnswer: onRevealAnswer,
      onShortAnswerMarked: onShortAnswerMarked,
      onNextQuestion: onNextQuestion,
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

  bool get _answeredCorrectly =>
      selectedChoiceLabel != null &&
      selectedChoiceLabel == question.answerLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visual = _categoryVisual(question.category);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: _panel.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.48),
            blurRadius: 34,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: visual.color.withValues(alpha: 0.12),
            blurRadius: 42,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: visual.color.withValues(alpha: 0.16),
                border: Border(left: BorderSide(color: visual.color, width: 7)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _InfoChip(
                      icon: visual.icon,
                      label: question.category,
                      color: visual.color,
                    ),
                    _InfoChip(
                      icon: question.hasChoices
                          ? Icons.list_alt
                          : Icons.edit_note,
                      label: question.type.label,
                      color: const Color(0xFF5E548E),
                    ),
                    _InfoChip(
                      icon: Icons.tag,
                      label: question.sourceLabel,
                      color: const Color(0xFF6C757D),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SelectableText(
                    question.question,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      height: 1.24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                      color: _textStrong,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (question.hasChoices)
                    for (final choice in question.choices) ...[
                      _ChoiceButton(
                        choice: choice,
                        selectedChoiceLabel: selectedChoiceLabel,
                        answerLabel: question.answerLabel,
                        showAnswer: showAnswer,
                        onTap: () => onChoiceSelected(choice),
                      ),
                      const SizedBox(height: 10),
                    ]
                  else
                    _RevealButton(
                      showAnswer: showAnswer,
                      onRevealAnswer: onRevealAnswer,
                    ),
                  if (showAnswer) ...[
                    const SizedBox(height: 18),
                    _AnswerPanel(
                      answer: question.answer,
                      correct: question.hasChoices ? _answeredCorrectly : null,
                    ),
                    if (!question.hasChoices) ...[
                      const SizedBox(height: 14),
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
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.tonalIcon(
                      onPressed: onNextQuestion,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Skip / next'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({
    required this.choice,
    required this.selectedChoiceLabel,
    required this.answerLabel,
    required this.showAnswer,
    required this.onTap,
  });

  final QuestionChoice choice;
  final String? selectedChoiceLabel;
  final String? answerLabel;
  final bool showAnswer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCorrect = showAnswer && choice.label == answerLabel;
    final isWrongSelection =
        showAnswer && choice.label == selectedChoiceLabel && !isCorrect;
    final stateColor = isCorrect
        ? _accent
        : isWrongSelection
        ? _danger
        : _line;

    return Material(
      color: isCorrect
          ? _accent.withValues(alpha: 0.14)
          : isWrongSelection
          ? _danger.withValues(alpha: 0.14)
          : _panelElevated.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: showAnswer ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: stateColor, width: isCorrect ? 2 : 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: stateColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: Center(
                      child: Text(
                        choice.label,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: stateColor,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    choice.text,
                    style: theme.textTheme.titleMedium?.copyWith(
                      height: 1.3,
                      color: _textStrong,
                    ),
                  ),
                ),
                if (isCorrect || isWrongSelection) ...[
                  const SizedBox(width: 10),
                  Icon(
                    isCorrect ? Icons.check_circle : Icons.cancel,
                    color: stateColor,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RevealButton extends StatelessWidget {
  const _RevealButton({required this.showAnswer, required this.onRevealAnswer});

  final bool showAnswer;
  final VoidCallback onRevealAnswer;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: showAnswer ? null : onRevealAnswer,
      icon: const Icon(Icons.visibility),
      label: const Text('Reveal answer'),
    );
  }
}

class _AnswerPanel extends StatelessWidget {
  const _AnswerPanel({required this.answer, required this.correct});

  final String answer;
  final bool? correct;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = correct == null
        ? _accentBlue
        : correct!
        ? _accent
        : _danger;
    final label = correct == null
        ? 'Answer'
        : correct!
        ? 'Correct'
        : 'Review';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              correct == null
                  ? Icons.lightbulb
                  : correct!
                  ? Icons.check_circle
                  : Icons.psychology_alt,
              color: color,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    answer,
                    style: theme.textTheme.titleMedium?.copyWith(
                      height: 1.32,
                      color: _textStrong,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: _panelElevated.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.34)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: _textStrong,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 46,
        height: 46,
        child: CircularProgressIndicator(strokeWidth: 5),
      ),
    );
  }
}

class _EmptyQuestionState extends StatelessWidget {
  const _EmptyQuestionState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: _panel.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 40, color: _textMuted),
            const SizedBox(height: 12),
            Text(
              'No questions match this filter.',
              style: theme.textTheme.titleMedium?.copyWith(color: _textStrong),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryVisual {
  const _CategoryVisual({required this.icon, required this.color});

  final IconData icon;
  final Color color;
}

_CategoryVisual _categoryVisual(String category) {
  return switch (category) {
    'Life Science' => const _CategoryVisual(
      icon: Icons.biotech,
      color: Color(0xFF43D17A),
    ),
    'Physical Science' => const _CategoryVisual(
      icon: Icons.science,
      color: Color(0xFF2DD4D7),
    ),
    'Earth Science' => const _CategoryVisual(
      icon: Icons.terrain,
      color: Color(0xFFE0905D),
    ),
    'Earth and Space' => const _CategoryVisual(
      icon: Icons.public,
      color: Color(0xFF74A7FF),
    ),
    'Energy' => const _CategoryVisual(icon: Icons.bolt, color: _warning),
    'Math' => const _CategoryVisual(
      icon: Icons.calculate,
      color: Color(0xFFB08CFF),
    ),
    'General Science' => const _CategoryVisual(
      icon: Icons.hub,
      color: Color(0xFFFF7A66),
    ),
    _ => const _CategoryVisual(
      icon: Icons.all_inclusive,
      color: Color(0xFF2EE6A6),
    ),
  };
}

String _formatCount(int value) {
  final raw = value.toString();
  final buffer = StringBuffer();

  for (var i = 0; i < raw.length; i += 1) {
    if (i > 0 && (raw.length - i) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(raw[i]);
  }

  return buffer.toString();
}

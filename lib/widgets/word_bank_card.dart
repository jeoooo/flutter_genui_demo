import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import 'quiz_shared.dart';

CatalogItem wordBankCardItem(void Function(bool) onAnswered) => CatalogItem(
  name: 'WordBankCard',
  dataSchema: S.object(
    properties: {
      'statement': S.string(),
      'wordBank': S.list(items: S.string()),
      'correctAnswer': S.string(),
      'explanation': S.string(),
    },
    required: ['statement', 'wordBank', 'correctAnswer'],
  ),
  widgetBuilder: (context) {
    final data = context.data as Map<String, Object?>;
    final wordBank =
        (data['wordBank'] as List? ?? []).map((w) => '$w').toList();
    return WordBankCard(
      statement: '${data['statement'] ?? ''}',
      wordBank: wordBank,
      correctAnswer: '${data['correctAnswer'] ?? ''}',
      explanation: data['explanation'] as String?,
      onAnswered: onAnswered,
    );
  },
);

class WordBankCard extends StatefulWidget {
  const WordBankCard({
    required this.statement,
    required this.wordBank,
    required this.correctAnswer,
    required this.onAnswered,
    this.explanation,
    super.key,
  });

  final String statement;
  final List<String> wordBank;
  final String correctAnswer;
  final String? explanation;
  final void Function(bool) onAnswered;

  @override
  State<WordBankCard> createState() => _WordBankCardState();
}

class _WordBankCardState extends State<WordBankCard> {
  String? _picked;
  late final List<String> _shuffled;

  @override
  void initState() {
    super.initState();
    _shuffled = [...widget.wordBank]..shuffle();
  }

  void _pick(String word) {
    if (_picked != null) return;
    final correct = word.trim().toLowerCase() ==
        widget.correctAnswer.trim().toLowerCase();
    setState(() => _picked = word);
    widget.onAnswered(correct);
  }

  bool get _isCorrect =>
      _picked?.trim().toLowerCase() ==
      widget.correctAnswer.trim().toLowerCase();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final answered = _picked != null;

    final display = answered
        ? widget.statement.replaceFirst('___', _picked!)
        : widget.statement;

    return QuizCard(
      question: display,
      children: [
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _shuffled.map((word) {
            final isPicked = _picked == word;
            final isCorrectWord = word.trim().toLowerCase() ==
                widget.correctAnswer.trim().toLowerCase();

            Color? bg;
            Color? fg;
            if (answered) {
              if (isCorrectWord) {
                bg = colors.primaryContainer;
                fg = colors.onPrimaryContainer;
              } else if (isPicked) {
                bg = colors.errorContainer;
                fg = colors.onErrorContainer;
              }
            }

            return ActionChip(
              label: Text(
                word,
                style: fg != null ? TextStyle(color: fg) : null,
              ),
              backgroundColor: bg,
              side: answered && isCorrectWord
                  ? BorderSide(color: colors.primary)
                  : null,
              onPressed: answered ? null : () => _pick(word),
            );
          }).toList(),
        ),
        if (answered)
          ExplanationBox(
            isCorrect: _isCorrect,
            text: _isCorrect
                ? widget.explanation ?? 'Correct!'
                : 'Correct answer: ${widget.correctAnswer}'
                    '${widget.explanation != null ? '\n\n${widget.explanation}' : ''}',
          ),
      ],
    );
  }
}

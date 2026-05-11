import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import 'quiz_shared.dart';

CatalogItem fillInBlankCardItem(void Function(bool) onAnswered) => CatalogItem(
  name: 'FillInTheBlankCard',
  dataSchema: S.object(
    properties: {
      'statement': S.string(),
      'correctAnswer': S.string(),
      'hint': S.string(),
      'explanation': S.string(),
    },
    required: ['statement', 'correctAnswer'],
  ),
  widgetBuilder: (context) {
    final data = context.data as Map<String, Object?>;
    return FillInTheBlankCard(
      statement: '${data['statement'] ?? ''}',
      correctAnswer: '${data['correctAnswer'] ?? ''}',
      hint: data['hint'] as String?,
      explanation: data['explanation'] as String?,
      onAnswered: onAnswered,
    );
  },
);

class FillInTheBlankCard extends StatefulWidget {
  const FillInTheBlankCard({
    required this.statement,
    required this.correctAnswer,
    required this.onAnswered,
    this.hint,
    this.explanation,
    super.key,
  });

  final String statement;
  final String correctAnswer;
  final String? hint;
  final String? explanation;
  final void Function(bool) onAnswered;

  @override
  State<FillInTheBlankCard> createState() => _FillInTheBlankCardState();
}

class _FillInTheBlankCardState extends State<FillInTheBlankCard> {
  final _controller = TextEditingController();
  bool? _isCorrect;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_isCorrect != null) return;
    final correct = _controller.text.trim().toLowerCase() ==
        widget.correctAnswer.trim().toLowerCase();
    setState(() => _isCorrect = correct);
    widget.onAnswered(correct);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final answered = _isCorrect != null;

    return QuizCard(
      question: widget.statement,
      children: [
        TextField(
          controller: _controller,
          enabled: !answered,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            hintText: widget.hint ?? 'Type your answer…',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: colors.primary, width: 2),
            ),
            suffixIcon: answered
                ? Icon(
                    _isCorrect! ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    color: _isCorrect! ? colors.primary : colors.error,
                  )
                : null,
          ),
        ),
        const SizedBox(height: 8),
        if (!answered)
          SizedBox(
            width: double.infinity,
            child: FilledButton(onPressed: _submit, child: const Text('Submit')),
          ),
        if (answered)
          ExplanationBox(
            isCorrect: _isCorrect!,
            text: _isCorrect!
                ? widget.explanation ?? 'Correct!'
                : 'Correct answer: ${widget.correctAnswer}'
                    '${widget.explanation != null ? '\n\n${widget.explanation}' : ''}',
          ),
      ],
    );
  }
}

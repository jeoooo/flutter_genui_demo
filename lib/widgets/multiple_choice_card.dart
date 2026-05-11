import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import 'quiz_shared.dart';

CatalogItem multipleChoiceCardItem(void Function(bool) onAnswered) => CatalogItem(
  name: 'MultipleChoiceCard',
  dataSchema: S.object(
    properties: {
      'question': S.string(),
      'choices': S.list(
        items: S.object(
          properties: {'id': S.string(), 'text': S.string()},
          required: ['id', 'text'],
        ),
      ),
      'correctChoiceId': S.string(),
      'explanation': S.string(),
    },
    required: ['question', 'choices', 'correctChoiceId'],
  ),
  widgetBuilder: (context) {
    final data = context.data as Map<String, Object?>;
    final choices = (data['choices'] as List? ?? [])
        .whereType<Map<Object?, Object?>>()
        .map((c) => (id: '${c['id']}', text: '${c['text']}'))
        .toList();
    return MultipleChoiceCard(
      question: '${data['question'] ?? ''}',
      choices: choices,
      correctId: '${data['correctChoiceId'] ?? ''}',
      explanation: data['explanation'] as String?,
      onAnswered: onAnswered,
    );
  },
);

class MultipleChoiceCard extends StatefulWidget {
  const MultipleChoiceCard({
    required this.question,
    required this.choices,
    required this.correctId,
    required this.onAnswered,
    this.explanation,
    super.key,
  });

  final String question;
  final List<({String id, String text})> choices;
  final String correctId;
  final String? explanation;
  final void Function(bool) onAnswered;

  @override
  State<MultipleChoiceCard> createState() => _MultipleChoiceCardState();
}

class _MultipleChoiceCardState extends State<MultipleChoiceCard> {
  String? _picked;

  void _pick(String id) {
    if (_picked != null) return;
    setState(() => _picked = id);
    widget.onAnswered(id == widget.correctId);
  }

  @override
  Widget build(BuildContext context) {
    return QuizCard(
      question: widget.question,
      children: [
        for (final choice in widget.choices)
          ChoiceTile(
            label: choice.id.toUpperCase(),
            text: choice.text,
            state: _picked == null
                ? TileState.idle
                : choice.id == widget.correctId
                    ? TileState.correct
                    : choice.id == _picked
                        ? TileState.wrong
                        : TileState.idle,
            onTap: _picked == null ? () => _pick(choice.id) : null,
          ),
        if (_picked != null && widget.explanation != null)
          ExplanationBox(
            isCorrect: _picked == widget.correctId,
            text: widget.explanation!,
          ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import 'quiz_shared.dart';

CatalogItem trueFalseCardItem(void Function(bool) onAnswered) => CatalogItem(
  name: 'TrueFalseCard',
  dataSchema: S.object(
    properties: {
      'statement': S.string(),
      'isTrue': S.boolean(),
      'explanation': S.string(),
    },
    required: ['statement', 'isTrue'],
  ),
  widgetBuilder: (context) {
    final data = context.data as Map<String, Object?>;
    return TrueFalseCard(
      statement: '${data['statement'] ?? ''}',
      isTrue: data['isTrue'] == true,
      explanation: data['explanation'] as String?,
      onAnswered: onAnswered,
    );
  },
);

class TrueFalseCard extends StatefulWidget {
  const TrueFalseCard({
    required this.statement,
    required this.isTrue,
    required this.onAnswered,
    this.explanation,
    super.key,
  });

  final String statement;
  final bool isTrue;
  final String? explanation;
  final void Function(bool) onAnswered;

  @override
  State<TrueFalseCard> createState() => _TrueFalseCardState();
}

class _TrueFalseCardState extends State<TrueFalseCard> {
  bool? _picked;

  void _pick(bool value) {
    if (_picked != null) return;
    setState(() => _picked = value);
    widget.onAnswered(value == widget.isTrue);
  }

  @override
  Widget build(BuildContext context) {
    return QuizCard(
      question: widget.statement,
      children: [
        Row(
          children: [
            Expanded(
              child: ChoiceTile(
                label: '✓',
                text: 'True',
                state: _picked == null
                    ? TileState.idle
                    : widget.isTrue
                        ? TileState.correct
                        : _picked == true
                            ? TileState.wrong
                            : TileState.idle,
                onTap: _picked == null ? () => _pick(true) : null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ChoiceTile(
                label: '✗',
                text: 'False',
                state: _picked == null
                    ? TileState.idle
                    : !widget.isTrue
                        ? TileState.correct
                        : _picked == false
                            ? TileState.wrong
                            : TileState.idle,
                onTap: _picked == null ? () => _pick(false) : null,
              ),
            ),
          ],
        ),
        if (_picked != null && widget.explanation != null)
          ExplanationBox(
            isCorrect: _picked == widget.isTrue,
            text: widget.explanation!,
          ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import 'quiz_shared.dart';

CatalogItem orderTheStepsCardItem(void Function(bool) onAnswered) => CatalogItem(
  name: 'OrderTheStepsCard',
  dataSchema: S.object(
    properties: {
      'question': S.string(),
      'steps': S.list(
        items: S.object(
          properties: {'id': S.string(), 'text': S.string()},
          required: ['id', 'text'],
        ),
      ),
      'explanation': S.string(),
    },
    required: ['question', 'steps'],
  ),
  widgetBuilder: (context) {
    final data = context.data as Map<String, Object?>;
    final steps = (data['steps'] as List? ?? [])
        .whereType<Map<Object?, Object?>>()
        .map((s) => (id: '${s['id']}', text: '${s['text']}'))
        .toList();
    return OrderTheStepsCard(
      question: '${data['question'] ?? ''}',
      steps: steps,
      explanation: data['explanation'] as String?,
      onAnswered: onAnswered,
    );
  },
);

class OrderTheStepsCard extends StatefulWidget {
  const OrderTheStepsCard({
    required this.question,
    required this.steps,
    required this.onAnswered,
    this.explanation,
    super.key,
  });

  final String question;
  final List<({String id, String text})> steps; // provided in correct order
  final String? explanation;
  final void Function(bool) onAnswered;

  @override
  State<OrderTheStepsCard> createState() => _OrderTheStepsCardState();
}

class _OrderTheStepsCardState extends State<OrderTheStepsCard> {
  // Indices into widget.steps, representing the user's current ordering.
  late List<int> _order;
  bool _submitted = false;
  bool _isCorrect = false;

  @override
  void initState() {
    super.initState();
    _order = List.generate(widget.steps.length, (i) => i)..shuffle();
  }

  void _submit() {
    // Correct if the user's order matches [0, 1, 2, ...] (the original order).
    final correct = _order.asMap().entries.every((e) => e.key == e.value);
    setState(() {
      _submitted = true;
      _isCorrect = correct;
    });
    widget.onAnswered(correct);
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (_submitted) return;
    if (newIndex > oldIndex) newIndex--;
    setState(() {
      final item = _order.removeAt(oldIndex);
      _order.insert(newIndex, item);
    });
  }

  @override
  Widget build(BuildContext context) {
    return QuizCard(
      question: widget.question,
      children: [
        ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          onReorder: _onReorder,
          children: [
            for (int i = 0; i < _order.length; i++)
              _StepTile(
                key: ValueKey(_order[i]),
                number: i + 1,
                text: widget.steps[_order[i]].text,
                result: _submitted
                    ? (_order[i] == i ? TileState.correct : TileState.wrong)
                    : TileState.idle,
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (!_submitted)
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submit,
              child: const Text('Check Order'),
            ),
          ),
        if (_submitted && widget.explanation != null)
          ExplanationBox(isCorrect: _isCorrect, text: widget.explanation!),
      ],
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.number,
    required this.text,
    required this.result,
    super.key,
  });

  final int number;
  final String text;
  final TileState result;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    Color? bg;
    if (result == TileState.correct) bg = colors.primaryContainer;
    if (result == TileState.wrong) bg = colors.errorContainer;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg ?? colors.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          QuizBadge(
            id: '$number',
            highlight: result == TileState.correct,
            error: result == TileState.wrong,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
          if (result == TileState.correct)
            Icon(Icons.check_circle_rounded, color: colors.primary, size: 18),
          if (result == TileState.wrong)
            Icon(Icons.cancel_rounded, color: colors.error, size: 18),
          if (result == TileState.idle)
            Icon(Icons.drag_handle_rounded, color: colors.outline, size: 18),
        ],
      ),
    );
  }
}

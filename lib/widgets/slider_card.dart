import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import 'quiz_shared.dart';

CatalogItem sliderCardItem(void Function(bool) onAnswered) => CatalogItem(
  name: 'SliderCard',
  dataSchema: S.object(
    properties: {
      'question': S.string(),
      'min': S.integer(),
      'max': S.integer(),
      'correctValue': S.integer(),
      'unit': S.string(),
      'tolerance': S.integer(),
      'explanation': S.string(),
    },
    required: ['question', 'min', 'max', 'correctValue'],
  ),
  widgetBuilder: (context) {
    final data = context.data as Map<String, Object?>;
    return SliderCard(
      question: '${data['question'] ?? ''}',
      min: (data['min'] as num? ?? 0).toInt(),
      max: (data['max'] as num? ?? 100).toInt(),
      correctValue: (data['correctValue'] as num? ?? 0).toInt(),
      unit: data['unit'] as String? ?? '',
      tolerance: (data['tolerance'] as num? ?? 0).toInt(),
      explanation: data['explanation'] as String?,
      onAnswered: onAnswered,
    );
  },
);

class SliderCard extends StatefulWidget {
  const SliderCard({
    required this.question,
    required this.min,
    required this.max,
    required this.correctValue,
    required this.onAnswered,
    this.unit = '',
    this.tolerance = 0,
    this.explanation,
    super.key,
  });

  final String question;
  final int min;
  final int max;
  final int correctValue;
  final String unit;
  final int tolerance;
  final String? explanation;
  final void Function(bool) onAnswered;

  @override
  State<SliderCard> createState() => _SliderCardState();
}

class _SliderCardState extends State<SliderCard> {
  late double _value;
  bool _submitted = false;
  bool _isCorrect = false;

  @override
  void initState() {
    super.initState();
    // Start in the middle
    _value = ((widget.min + widget.max) / 2).roundToDouble();
  }

  String _format(double v) {
    final s = v.toInt().toString();
    return widget.unit.isEmpty ? s : '$s ${widget.unit}';
  }

  void _submit() {
    if (_submitted) return;
    final diff = (_value.toInt() - widget.correctValue).abs();
    final correct = diff <= widget.tolerance;
    setState(() {
      _submitted = true;
      _isCorrect = correct;
    });
    widget.onAnswered(correct);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return QuizCard(
      question: widget.question,
      children: [
        const SizedBox(height: 8),
        Center(
          child: Text(
            _format(_value),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _submitted
                      ? (_isCorrect ? colors.primary : colors.error)
                      : colors.onSurface,
                ),
          ),
        ),
        Slider(
          value: _value,
          min: widget.min.toDouble(),
          max: widget.max.toDouble(),
          divisions: (widget.max - widget.min).clamp(1, 500),
          onChanged: _submitted ? null : (v) => setState(() => _value = v),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_format(widget.min.toDouble()),
                style: TextStyle(fontSize: 12, color: colors.outline)),
            Text(_format(widget.max.toDouble()),
                style: TextStyle(fontSize: 12, color: colors.outline)),
          ],
        ),
        const SizedBox(height: 12),
        if (!_submitted)
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submit,
              child: const Text('Submit'),
            ),
          ),
        if (_submitted)
          ExplanationBox(
            isCorrect: _isCorrect,
            text: _isCorrect
                ? widget.explanation ?? 'Correct!'
                : 'The answer is ${_format(widget.correctValue.toDouble())}.'
                    '${widget.explanation != null ? '\n\n${widget.explanation}' : ''}',
          ),
      ],
    );
  }
}

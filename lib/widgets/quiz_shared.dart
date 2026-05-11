import 'package:flutter/material.dart';

enum TileState { idle, correct, wrong }

class QuizCard extends StatelessWidget {
  const QuizCard({required this.question, required this.children, super.key});

  final String question;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }
}

class ChoiceTile extends StatelessWidget {
  const ChoiceTile({
    required this.label,
    required this.text,
    required this.state,
    required this.onTap,
    super.key,
  });

  final String label;
  final String text;
  final TileState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    Color? bg;
    if (state == TileState.correct) bg = colors.primaryContainer;
    if (state == TileState.wrong) bg = colors.errorContainer;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bg ?? colors.surfaceContainerHighest.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Row(
            children: [
              QuizBadge(
                id: label,
                highlight: state == TileState.correct,
                error: state == TileState.wrong,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(text)),
              if (state == TileState.correct)
                Icon(Icons.check_circle_rounded, color: colors.primary, size: 20),
              if (state == TileState.wrong)
                Icon(Icons.cancel_rounded, color: colors.error, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class QuizBadge extends StatelessWidget {
  const QuizBadge({
    required this.id,
    required this.highlight,
    required this.error,
    super.key,
  });

  final String id;
  final bool highlight;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final Color bg;
    final Color fg;

    if (highlight) {
      bg = colors.primary;
      fg = colors.onPrimary;
    } else if (error) {
      bg = colors.error;
      fg = colors.onError;
    } else {
      bg = colors.secondaryContainer;
      fg = colors.onSecondaryContainer;
    }

    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Text(
        id,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

class ExplanationBox extends StatelessWidget {
  const ExplanationBox({required this.isCorrect, required this.text, super.key});

  final bool isCorrect;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCorrect
            ? colors.primaryContainer.withValues(alpha: 0.5)
            : colors.errorContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isCorrect ? Icons.lightbulb_rounded : Icons.info_rounded,
            size: 16,
            color: isCorrect ? colors.primary : colors.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import 'quiz_shared.dart';

Widget _wrap(Widget child) => MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.grey.shade100,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );

@Preview(name: 'QuizCard – basic')
Widget quizCardBasic() => _wrap(
      const QuizCard(
        question: 'What is the powerhouse of the cell?',
        children: [Text('(answer choices would appear here)')],
      ),
    );

@Preview(name: 'ChoiceTile – idle')
Widget choiceTileIdle() => _wrap(
      const ChoiceTile(label: 'A', text: 'Mitochondria', state: TileState.idle, onTap: null),
    );

@Preview(name: 'ChoiceTile – correct')
Widget choiceTileCorrect() => _wrap(
      const ChoiceTile(label: 'A', text: 'Mitochondria', state: TileState.correct, onTap: null),
    );

@Preview(name: 'ChoiceTile – wrong')
Widget choiceTileWrong() => _wrap(
      const ChoiceTile(label: 'B', text: 'Nucleus', state: TileState.wrong, onTap: null),
    );

@Preview(name: 'ExplanationBox – correct')
Widget explanationBoxCorrect() => _wrap(
      const ExplanationBox(
        isCorrect: true,
        text: 'The mitochondria generates most of the cell\'s ATP through cellular respiration.',
      ),
    );

@Preview(name: 'ExplanationBox – incorrect')
Widget explanationBoxIncorrect() => _wrap(
      const ExplanationBox(
        isCorrect: false,
        text: 'Correct answer: Mitochondria\n\nThe nucleus stores DNA but does not produce energy.',
      ),
    );

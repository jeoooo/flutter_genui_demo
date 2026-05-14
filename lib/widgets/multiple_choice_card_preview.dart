import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import 'multiple_choice_card.dart';

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

@Preview(name: 'Unanswered')
Widget multipleChoiceUnanswered() => _wrap(
      MultipleChoiceCard(
        question: 'Which planet is known as the Red Planet?',
        choices: const [
          (id: 'a', text: 'Venus'),
          (id: 'b', text: 'Mars'),
          (id: 'c', text: 'Jupiter'),
          (id: 'd', text: 'Saturn'),
        ],
        correctId: 'b',
        explanation: 'Mars appears red due to iron oxide on its surface.',
        onAnswered: (_) {},
      ),
    );

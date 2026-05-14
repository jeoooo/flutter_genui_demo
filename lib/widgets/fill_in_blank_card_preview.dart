import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import 'fill_in_blank_card.dart';

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

@Preview(name: 'With hint')
Widget fillInBlankWithHint() => _wrap(
      FillInTheBlankCard(
        statement: 'The chemical symbol for water is ___.',
        correctAnswer: 'H2O',
        hint: 'Two hydrogen, one oxygen',
        explanation: 'Water (H₂O) is composed of two hydrogen atoms bonded to one oxygen atom.',
        onAnswered: (_) {},
      ),
    );

@Preview(name: 'No hint')
Widget fillInBlankNoHint() => _wrap(
      FillInTheBlankCard(
        statement: 'The speed of light in a vacuum is approximately ___ km/s.',
        correctAnswer: '300000',
        explanation: 'Light travels at approximately 299,792 km/s in a vacuum.',
        onAnswered: (_) {},
      ),
    );

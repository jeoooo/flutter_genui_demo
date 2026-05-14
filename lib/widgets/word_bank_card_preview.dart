import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import 'word_bank_card.dart';

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

@Preview(name: 'Vocabulary fill-in')
Widget wordBankVocabulary() => _wrap(
      WordBankCard(
        statement: 'The process by which plants make food using sunlight is called ___.',
        wordBank: const ['Respiration', 'Photosynthesis', 'Fermentation', 'Transpiration'],
        correctAnswer: 'Photosynthesis',
        explanation:
            'Photosynthesis converts light energy into chemical energy stored as glucose.',
        onAnswered: (_) {},
      ),
    );

@Preview(name: 'Geography fill-in')
Widget wordBankGeography() => _wrap(
      WordBankCard(
        statement: 'The capital of Australia is ___.',
        wordBank: const ['Sydney', 'Melbourne', 'Canberra', 'Brisbane'],
        correctAnswer: 'Canberra',
        explanation:
            'Canberra has been the capital of Australia since 1913, chosen as a compromise between Sydney and Melbourne.',
        onAnswered: (_) {},
      ),
    );

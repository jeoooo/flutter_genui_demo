import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import 'true_false_card.dart';

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

@Preview(name: 'True statement')
Widget trueFalseTrue() => _wrap(
      TrueFalseCard(
        statement: 'The Great Wall of China is visible from space with the naked eye.',
        isTrue: false,
        explanation:
            'This is a common myth. The wall is too narrow to be seen from orbit without aid.',
        onAnswered: (_) {},
      ),
    );

@Preview(name: 'False statement')
Widget trueFalseFalse() => _wrap(
      TrueFalseCard(
        statement: 'Sound travels faster in water than in air.',
        isTrue: true,
        explanation:
            'Sound travels about 4x faster in water (~1480 m/s) than in air (~343 m/s).',
        onAnswered: (_) {},
      ),
    );

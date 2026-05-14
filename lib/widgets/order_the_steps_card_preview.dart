import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import 'order_the_steps_card.dart';

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

@Preview(name: 'Scientific method')
Widget orderTheStepsScientificMethod() => _wrap(
      OrderTheStepsCard(
        question: 'Arrange the steps of the scientific method in order.',
        steps: const [
          (id: '1', text: 'Make an observation'),
          (id: '2', text: 'Form a hypothesis'),
          (id: '3', text: 'Design and run an experiment'),
          (id: '4', text: 'Analyze results and draw conclusions'),
        ],
        explanation: 'The scientific method follows a logical sequence from observation to conclusion.',
        onAnswered: (_) {},
      ),
    );

@Preview(name: 'Boiling water')
Widget orderTheStepsBoilingWater() => _wrap(
      OrderTheStepsCard(
        question: 'Put the steps to boil water in the correct order.',
        steps: const [
          (id: '1', text: 'Fill a pot with water'),
          (id: '2', text: 'Place the pot on the stove'),
          (id: '3', text: 'Turn on the heat'),
          (id: '4', text: 'Wait for bubbles to form'),
        ],
        onAnswered: (_) {},
      ),
    );

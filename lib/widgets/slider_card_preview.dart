import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import 'slider_card.dart';

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

@Preview(name: 'Temperature – with unit & tolerance')
Widget sliderTemperature() => _wrap(
      SliderCard(
        question: 'At what temperature does water boil at sea level?',
        min: 50,
        max: 150,
        correctValue: 100,
        unit: '°C',
        tolerance: 2,
        explanation: 'Water boils at 100 °C (212 °F) at standard atmospheric pressure.',
        onAnswered: (_) {},
      ),
    );

@Preview(name: 'Year – no unit')
Widget sliderYear() => _wrap(
      SliderCard(
        question: 'In what year did the first moon landing occur?',
        min: 1950,
        max: 1990,
        correctValue: 1969,
        tolerance: 0,
        explanation: 'Apollo 11 landed on the Moon on July 20, 1969.',
        onAnswered: (_) {},
      ),
    );

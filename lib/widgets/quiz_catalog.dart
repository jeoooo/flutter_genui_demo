import 'package:genui/genui.dart';

import 'fill_in_blank_card.dart';
import 'multiple_choice_card.dart';
import 'order_the_steps_card.dart';
import 'slider_card.dart';
import 'true_false_card.dart';
import 'word_bank_card.dart';

// Assembles all question formats into a single catalog.
// To add a new format: create its file in this folder, then add it here.
Catalog buildQuizCatalog({required void Function(bool isCorrect) onAnswered}) {
  return BasicCatalogItems.asCatalog().copyWith(newItems: [
    multipleChoiceCardItem(onAnswered),
    trueFalseCardItem(onAnswered),
    fillInBlankCardItem(onAnswered),
    orderTheStepsCardItem(onAnswered),
    wordBankCardItem(onAnswered),
    sliderCardItem(onAnswered),
  ]);
}

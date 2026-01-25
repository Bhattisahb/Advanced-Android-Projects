import 'dart:math';
import 'question.dart';

class QuizGenerator {
  static List<Question> generateQuestions(int tableNumber) {
    final random = Random();
    final questions = <Question>[];

    // Generate 10 questions
    for (int i = 0; i < 10; i++) {
      // Random multiplier from 1 to 10
      final multiplier = random.nextInt(10) + 1;
      final correctAnswer = tableNumber * multiplier;

      // Generate 4 options including the correct answer
      final options = <int>{correctAnswer};

      // Generate 3 random wrong options
      while (options.length < 4) {
        // Wrong options should be different from correct answer
        // Generate random number around the correct answer
        int wrongOption;
        if (random.nextBool()) {
          wrongOption = correctAnswer + random.nextInt(30) + 1;
        } else {
          wrongOption = correctAnswer - random.nextInt(30) - 1;
        }

        // Ensure wrong option is not negative and not equal to correct answer
        if (wrongOption > 0 && wrongOption != correctAnswer) {
          options.add(wrongOption);
        }
      }

      // Convert to list and shuffle
      final optionsList = options.toList();
      optionsList.shuffle(random);

      questions.add(
        Question(
          num1: tableNumber,
          num2: multiplier,
          correctAnswer: correctAnswer,
          options: optionsList,
        ),
      );
    }

    return questions;
  }
}

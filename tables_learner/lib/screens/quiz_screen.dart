import 'package:flutter/material.dart';
import '../models/quiz_generator.dart';
import '../models/question.dart';
import 'result_screen.dart';

class QuizScreen extends StatefulWidget {
  final int tableNumber;

  const QuizScreen({
    super.key,
    required this.tableNumber,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late List<Question> questions;
  int currentQuestionIndex = 0;
  int correctAnswers = 0;
  int? selectedAnswer;

  @override
  void initState() {
    super.initState();
    questions = QuizGenerator.generateQuestions(widget.tableNumber);
  }

  void _selectAnswer(int answer) {
    setState(() {
      selectedAnswer = answer;

      // Check if answer is correct
      if (answer == questions[currentQuestionIndex].correctAnswer) {
        correctAnswers++;
      }

      // Move to next question after a short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _nextQuestion();
        }
      });
    });
  }

  void _nextQuestion() {
    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        selectedAnswer = null;
      });
    } else {
      // Quiz finished
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            tableNumber: widget.tableNumber,
            correctAnswers: correctAnswers,
            totalQuestions: questions.length,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final question = questions[currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Maths Tables Quiz'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.blue.shade600,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.blue.shade100],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Progress section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Question ${currentQuestionIndex + 1}/${questions.length}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade600,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${((currentQuestionIndex + 1) / questions.length * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: LinearProgressIndicator(
                  value: (currentQuestionIndex + 1) / questions.length,
                  minHeight: 10,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                ),
              ),
              const SizedBox(height: 40),

              // Question container
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blue.shade100,
                      Colors.blue.shade50,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.shade300.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.blue.shade300,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'What is:',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${question.num1} × ${question.num2}',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Options
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: question.options.length,
                  itemBuilder: (context, index) {
                    final option = question.options[index];
                    final isSelected = selectedAnswer == option;
                    final isCorrect = option == question.correctAnswer;

                    Color backgroundColor;
                    Color borderColor;
                    Color textColor = Colors.white;

                    if (selectedAnswer == null) {
                      backgroundColor = Colors.blue.shade500;
                      borderColor = Colors.blue.shade600;
                    } else if (isSelected) {
                      if (isCorrect) {
                        backgroundColor = Colors.green.shade500;
                        borderColor = Colors.green.shade600;
                      } else {
                        backgroundColor = Colors.red.shade500;
                        borderColor = Colors.red.shade600;
                      }
                    } else if (isCorrect && selectedAnswer != null) {
                      backgroundColor = Colors.green.shade500;
                      borderColor = Colors.green.shade600;
                    } else {
                      backgroundColor = Colors.grey.shade400;
                      borderColor = Colors.grey.shade500;
                    }

                    return GestureDetector(
                      onTap: selectedAnswer == null ? () => _selectAnswer(option) : null,
                      child: Container(
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: borderColor,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: backgroundColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: selectedAnswer == null
                                ? () => _selectAnswer(option)
                                : null,
                            borderRadius: BorderRadius.circular(12),
                            child: Center(
                              child: Text(
                                '$option',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

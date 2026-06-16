import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class QuizPage extends StatefulWidget {
  final String subjectId;
  final String quizId;

  const QuizPage({super.key, required this.subjectId, required this.quizId});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  bool _isAttempting = false;
  String _quizState = 'Not attempt yet';
  String _grade = '-';
  String _review = '-';

  // Track selected answer index for each of the 3 questions (null = not selected)
  final List<int?> _selectedAnswers = [null, null, null];

  final List<Map<String, dynamic>> _questions = [
    {
      'questionNumber': 1,
      'text': 'Why company always tend to deliver poor software?',
      'options': [
        'a. Ambiguous communication',
        'b. Overwhelming complexity',
        'c. Weak and incorrect design',
        'd. All answers in the list',
      ],
    },
    {
      'questionNumber': 2,
      'text': 'Why company always tend to deliver poor software?',
      'options': [
        'a. Ambiguous communication',
        'b. Overwhelming complexity',
        'c. Weak and incorrect design',
        'd. All answers in the list',
      ],
    },
    {
      'questionNumber': 3,
      'text': 'Why company always tend to deliver poor software?',
      'options': [
        'a. Ambiguous communication',
        'b. Overwhelming complexity',
        'c. Weak and incorrect design',
        'd. All answers in the list',
      ],
    },
  ];

  void _startAttempt() {
    setState(() {
      _isAttempting = true;
    });
  }

  void _submitQuiz() {
    setState(() {
      _isAttempting = false;
      _quizState = 'Finished';
      _grade = '10/10 (100%)';
      _review = 'Review';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Quiz submitted successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF4CE6FC), // Vivid Turquoise SAMS Header theme
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.only(top: 24, left: 16, right: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'SAMS',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Inter',
                  color: Colors.black,
                  letterSpacing: -0.5,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.menu, color: Colors.black, size: 30),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back Arrow + Title Row
              Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.black,
                      size: 28,
                    ),
                    onPressed: () {
                      if (_isAttempting) {
                        setState(() {
                          _isAttempting = false;
                        });
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Quiz 1',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Inter',
                      color: Colors.black,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (!_isAttempting) ...[
                // Info Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Open : Monday, 16/3/2026, 11:59 pm',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Due : Monday, 6/4/2026, 1.00 pm',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Case Study greenish/yellow button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(
                      0xFFA3E635,
                    ), // Yellowish/lime green matches Image 1
                    foregroundColor: Colors.black,
                    elevation: 2,
                    shadowColor: Colors.black12,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                      side: const BorderSide(color: Colors.black87, width: 1.2),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                  ),
                  onPressed: _startAttempt,
                  child: const Text(
                    'Attempt',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
                const SizedBox(height: 36),

                // Previous attempts list
                const Text(
                  'Summary of previous attempt',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Inter',
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 14),

                // Attempt Summary Table exactly matching Image 1
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400, width: 1.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Table(
                    columnWidths: const {
                      0: FixedColumnWidth(110),
                      1: FlexColumnWidth(),
                    },
                    border: TableBorder.symmetric(
                      inside: BorderSide(
                        color: Colors.grey.shade400,
                        width: 1.2,
                      ),
                    ),
                    children: [
                      _buildTableRow(
                        'State',
                        _quizState,
                        isBoldState: _quizState == 'Finished',
                      ),
                      _buildTableRow('Grade', _grade),
                      _buildTableRow(
                        'Review',
                        _review,
                        isReviewButton: _review == 'Review',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 64),

                // Back to course button
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE2E8F0),
                      foregroundColor: Colors.black,
                      elevation: 2,
                      shadowColor: Colors.black12,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                        side: const BorderSide(color: Colors.black38, width: 1),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Back to the course',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                // List of question widgets from Image 2
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _questions.length,
                  itemBuilder: (context, qIndex) {
                    final question = _questions[qIndex];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 22.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Question Prompt in Light gray box
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFF1F5F9,
                              ), // matches light gray prompt card
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Question ${question['questionNumber']}',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  question['text'],
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    height: 1.3,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Multiple choice radio items List matching Image 2
                          Padding(
                            padding: const EdgeInsets.only(left: 6.0),
                            child: Column(
                              children: List.generate(
                                question['options'].length,
                                (oIndex) {
                                  final optionText =
                                      question['options'][oIndex];
                                  final isSelected =
                                      _selectedAnswers[qIndex] == oIndex;
                                  return InkWell(
                                    onTap: () {
                                      setState(() {
                                        _selectedAnswers[qIndex] = oIndex;
                                      });
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 6.0,
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 14,
                                            height: 14,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: isSelected
                                                  ? const Color(0xFF22D3EE)
                                                  : Colors.grey.shade300,
                                              border: Border.all(
                                                color: isSelected
                                                    ? const Color(0xFF0891B2)
                                                    : Colors.grey.shade400,
                                                width: 1.2,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              optionText,
                                              style: const TextStyle(
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Submit Button style
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(
                        0xFF86EFAC,
                      ), // Soft mint green
                      foregroundColor: Colors.black,
                      elevation: 2,
                      shadowColor: Colors.black12,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                        side: const BorderSide(
                          color: Colors.black87,
                          width: 1.2,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 10,
                      ),
                    ),
                    onPressed: _submitQuiz,
                    child: const Text(
                      'Submit',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  TableRow _buildTableRow(
    String label,
    String val, {
    bool isBoldState = false,
    bool isReviewButton = false,
  }) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: isReviewButton
              ? InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Viewing quiz answers...')),
                    );
                  },
                  child: Text(
                    val,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                )
              : Text(
                  val,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: isBoldState ? Colors.green : Colors.grey.shade500,
                  ),
                ),
        ),
      ],
    );
  }
}

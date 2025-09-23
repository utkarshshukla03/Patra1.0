import 'package:flutter/material.dart';

class PersonalityTestPage extends StatefulWidget {
  @override
  State<PersonalityTestPage> createState() => _PersonalityTestPageState();
}

class _PersonalityTestPageState extends State<PersonalityTestPage> {
  final List<String> questions = [
    'You usually stay calm, even under a lot of pressure.',
    'You enjoy social gatherings and meeting new people.',
    'You prefer planning ahead rather than being spontaneous.',
    'You are comfortable expressing your feelings to others.',
    'You like to take risks and try new things.',
    'You are detail-oriented and organized.',
    'You enjoy helping others and being supportive.',
    'You adapt easily to new situations.',
    'You value deep conversations over small talk.',
    'You are motivated by challenges and goals.'
  ];

  final List<String> options = [
    'Disagree',
    'Slightly Disagree',
    'Not sure',
    'Slightly Agree',
    'Agree'
  ];
  int currentQuestion = 0;
  List<int?> answers = List.filled(10, null);

  void nextQuestion() {
    if (currentQuestion < questions.length - 1) {
      setState(() {
        currentQuestion++;
      });
    } else {
      // TODO: Save answers for matching algorithm
      Navigator.of(context).pop();
    }
  }

  void previousQuestion() {
    if (currentQuestion > 0) {
      setState(() {
        currentQuestion--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF3B1E6D),
      appBar: AppBar(
        backgroundColor: Color(0xFF3B1E6D),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: previousQuestion,
        ),
        title: Text('Personality type', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Skip', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 16),
            // Progress bar
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(questions.length, (index) {
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 2),
                  width: 28,
                  height: 6,
                  decoration: BoxDecoration(
                    color: index <= currentQuestion
                        ? Colors.white
                        : Colors.white24,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
            SizedBox(height: 16),
            Text('Question ${currentQuestion + 1}/${questions.length}',
                style: TextStyle(color: Colors.white70, fontSize: 16)),
            SizedBox(height: 24),
            Text(
              questions[currentQuestion],
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(options.length, (i) {
                final selected = answers[currentQuestion] == i;
                return Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          answers[currentQuestion] = i;
                        });
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: selected ? Colors.white : Colors.white24,
                              width: 2),
                          color: selected ? Colors.white24 : Colors.transparent,
                        ),
                        child: selected
                            ? Icon(Icons.check, color: Colors.white, size: 28)
                            : null,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(options[i],
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                );
              }),
            ),
            Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFB39DDB),
                  shape: StadiumBorder(),
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed:
                    answers[currentQuestion] != null ? nextQuestion : null,
                child: Text('Confirm',
                    style: TextStyle(
                        fontSize: 18,
                        color: Color(0xFF3B1E6D),
                        fontWeight: FontWeight.bold)),
              ),
            ),
            SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class GenderStepPage extends StatefulWidget {
  final Function(String) onNext;
  final VoidCallback onBack;

  const GenderStepPage({
    Key? key,
    required this.onNext,
    required this.onBack,
  }) : super(key: key);

  @override
  State<GenderStepPage> createState() => _GenderStepPageState();
}

class _GenderStepPageState extends State<GenderStepPage> {
  String? selectedGender;

  final List<Map<String, dynamic>> genderOptions = [
    {
      'value': 'Woman',
      'icon': Icons.female,
      'color': Colors.pink,
    },
    {
      'value': 'Man',
      'icon': Icons.male,
      'color': Colors.blue,
    },
    {
      'value': 'Non-binary',
      'icon': Icons.circle,
      'color': Colors.purple,
    },
    {
      'value': 'Trans Woman',
      'icon': Icons.transgender,
      'color': Colors.pink.shade300,
    },
    {
      'value': 'Trans Man',
      'icon': Icons.transgender,
      'color': Colors.blue.shade300,
    },
    {
      'value': 'Genderfluid',
      'icon': Icons.water_drop,
      'color': Colors.indigo,
    },
    {
      'value': 'Agender',
      'icon': Icons.circle_outlined,
      'color': Colors.grey.shade600,
    },
    {
      'value': 'Other',
      'icon': Icons.more_horiz,
      'color': Colors.orange,
    },
    {
      'value': 'Prefer not to say',
      'icon': Icons.help_outline,
      'color': Colors.grey,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height,
          ),
          child: IntrinsicHeight(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20),

                  // Header
                  Text(
                    'I am a',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  SizedBox(height: 8),

                  Text(
                    'This helps us show you to the right people',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),

                  SizedBox(height: 40),

                  // Gender Options - Chip Style
                  Expanded(
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: genderOptions.map((option) {
                          final isSelected = selectedGender == option['value'];
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedGender = option['value'];
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? option['color']
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                  color: isSelected
                                      ? option['color']
                                      : Colors.grey[300]!,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    option['icon'],
                                    color: isSelected
                                        ? Colors.white
                                        : option['color'],
                                    size: 18,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    option['value'],
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  SizedBox(height: 20),

                  // Navigation Buttons
                  Row(
                    children: [
                      // Back Button
                      Expanded(
                        flex: 1,
                        child: GestureDetector(
                          onTap: widget.onBack,
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Center(
                              child: Text(
                                'Back',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(width: 16),

                      // Continue Button
                      Expanded(
                        flex: 2,
                        child: GestureDetector(
                          onTap: selectedGender != null
                              ? () => widget.onNext(selectedGender!)
                              : null,
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: selectedGender != null
                                  ? Colors.pink
                                  : Colors.grey[300],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                'Continue',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: selectedGender != null
                                      ? Colors.white
                                      : Colors.grey[600],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

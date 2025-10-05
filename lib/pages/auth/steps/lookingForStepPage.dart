import 'package:flutter/material.dart';

class LookingForStepPage extends StatefulWidget {
  final Function(List<String>) onNext;
  final VoidCallback onBack;

  const LookingForStepPage({
    Key? key,
    required this.onNext,
    required this.onBack,
  }) : super(key: key);

  @override
  State<LookingForStepPage> createState() => _LookingForStepPageState();
}

class _LookingForStepPageState extends State<LookingForStepPage> {
  List<String> selectedPreferences = [];

  final List<Map<String, dynamic>> lookingForOptions = [
    {
      'value': 'Friends',
      'icon': Icons.people,
      'color': Colors.lightBlue, // Trust, loyalty, reliability
      'description': 'Friends',
    },
    {
      'value': 'Study Buddy',
      'icon': Icons.school,
      'color': Colors.green, // Growth, learning, harmony
      'description': 'Study Buddy',
    },
    {
      'value': 'Fun',
      'icon': Icons.celebration,
      'color': Colors.orange, // Energy, enthusiasm, playfulness
      'description': 'Fun',
    },
    {
      'value': 'Casual',
      'icon': Icons.coffee,
      'color': Colors.amber, // Warmth, comfort, easygoing
      'description': 'Casual',
    },
    {
      'value': 'Long Term',
      'icon': Icons.favorite,
      'color': Colors.red, // Passion, love, commitment
      'description': 'Long Term',
    },
    {
      'value': 'Activity',
      'icon': Icons.directions_run,
      'color': Colors.deepOrange, // Energy, movement, vitality
      'description': 'Activity',
    },
    {
      'value': 'Open',
      'icon': Icons.explore,
      'color': Colors.indigo, // Openness, wisdom, inclusivity
      'description': 'Open',
    },
  ];

  void _togglePreference(String preference) {
    setState(() {
      if (preference == 'Open') {
        // If "Open" is selected, clear other selections and add open
        selectedPreferences.clear();
        selectedPreferences.add('Open');
      } else {
        // Remove "Open" if specific preference is selected
        selectedPreferences.remove('Open');

        if (selectedPreferences.contains(preference)) {
          selectedPreferences.remove(preference);
        } else {
          selectedPreferences.add(preference);
        }
      }
    });
  }

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
                    'I\'m looking for',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  SizedBox(height: 8),

                  Text(
                    'What kind of connection are you seeking? You can choose multiple options',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),

                  SizedBox(height: 40),

                  // Looking For Options - Chip Style
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: lookingForOptions.map((option) {
                              final isSelected =
                                  selectedPreferences.contains(option['value']);
                              return GestureDetector(
                                onTap: () => _togglePreference(option['value']),
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
                                        option['description'],
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

                          SizedBox(height: 20),

                          // Selection count indicator
                          if (selectedPreferences.isNotEmpty)
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.pink.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                selectedPreferences.length == 1 &&
                                        selectedPreferences.contains('Open')
                                    ? 'Open to all connections'
                                    : '${selectedPreferences.length} option${selectedPreferences.length == 1 ? '' : 's'} selected',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.pink,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
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
                          onTap: selectedPreferences.isNotEmpty
                              ? () => widget.onNext(selectedPreferences)
                              : null,
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: selectedPreferences.isNotEmpty
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
                                  color: selectedPreferences.isNotEmpty
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

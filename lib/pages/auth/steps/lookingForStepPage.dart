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
      'value': 'Woman',
      'icon': Icons.female,
      'color': Colors.pink,
      'description': 'Women',
    },
    {
      'value': 'Man',
      'icon': Icons.male,
      'color': Colors.blue,
      'description': 'Men',
    },
    {
      'value': 'Non-binary',
      'icon': Icons.circle,
      'color': Colors.purple,
      'description': 'Non-binary',
    },
    {
      'value': 'Trans Woman',
      'icon': Icons.transgender,
      'color': Colors.pink.shade300,
      'description': 'Trans Women',
    },
    {
      'value': 'Trans Man',
      'icon': Icons.transgender,
      'color': Colors.blue.shade300,
      'description': 'Trans Men',
    },
    {
      'value': 'Genderfluid',
      'icon': Icons.water_drop,
      'color': Colors.indigo,
      'description': 'Genderfluid',
    },
    {
      'value': 'Gay',
      'icon': Icons.favorite,
      'color': Colors.teal,
      'description': 'Gay',
    },
    {
      'value': 'Lesbian',
      'icon': Icons.favorite,
      'color': Colors.deepOrange,
      'description': 'Lesbian',
    },
    {
      'value': 'Bisexual',
      'icon': Icons.favorite_border,
      'color': Colors.deepPurple,
      'description': 'Bisexual',
    },
    {
      'value': 'Pansexual',
      'icon': Icons.favorite_rounded,
      'color': Colors.yellow.shade700,
      'description': 'Pansexual',
    },
    {
      'value': 'Everyone',
      'icon': Icons.group,
      'color': Colors.orange,
      'description': 'Everyone',
    },
  ];

  void _togglePreference(String preference) {
    setState(() {
      if (preference == 'Everyone') {
        // If "Everyone" is selected, clear other selections and add everyone
        selectedPreferences.clear();
        selectedPreferences.add('Everyone');
      } else {
        // Remove "Everyone" if specific preference is selected
        selectedPreferences.remove('Everyone');

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
                    'Show me',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  SizedBox(height: 8),

                  Text(
                    'Who would you like to see? You can choose multiple options',
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
                                        selectedPreferences.contains('Everyone')
                                    ? 'Showing everyone'
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

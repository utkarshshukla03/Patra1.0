import 'package:flutter/material.dart';

class HobbiesStepPage extends StatefulWidget {
  final Function(List<String>) onNext;
  final VoidCallback onBack;

  const HobbiesStepPage({
    Key? key,
    required this.onNext,
    required this.onBack,
  }) : super(key: key);

  @override
  State<HobbiesStepPage> createState() => _HobbiesStepPageState();
}

class _HobbiesStepPageState extends State<HobbiesStepPage>
    with TickerProviderStateMixin {
  List<String> selectedHobbies = [];
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final List<Map<String, dynamic>> trendingHobbies = [
    {'name': 'Music', 'icon': Icons.music_note, 'color': Colors.purple},
    {'name': 'Sports', 'icon': Icons.sports_soccer, 'color': Colors.green},
    {'name': 'Travel', 'icon': Icons.flight_takeoff, 'color': Colors.blue},
    {'name': 'Photography', 'icon': Icons.camera_alt, 'color': Colors.orange},
    {'name': 'Reading', 'icon': Icons.menu_book, 'color': Colors.brown},
    {'name': 'Gaming', 'icon': Icons.sports_esports, 'color': Colors.indigo},
    {'name': 'Cooking', 'icon': Icons.restaurant, 'color': Colors.red},
    {'name': 'Art', 'icon': Icons.palette, 'color': Colors.pink},
    {'name': 'Dancing', 'icon': Icons.music_video, 'color': Colors.purple},
    {'name': 'Fitness', 'icon': Icons.fitness_center, 'color': Colors.orange},
    {'name': 'Movies', 'icon': Icons.local_movies, 'color': Colors.blue},
    {'name': 'Tech', 'icon': Icons.computer, 'color': Colors.cyan},
    {'name': 'Fashion', 'icon': Icons.checkroom, 'color': Colors.pink},
    {'name': 'Pets', 'icon': Icons.pets, 'color': Colors.brown},
    {'name': 'Yoga', 'icon': Icons.self_improvement, 'color': Colors.green},
    {'name': 'Writing', 'icon': Icons.edit, 'color': Colors.indigo},
    {'name': 'Hiking', 'icon': Icons.hiking, 'color': Colors.green},
    {'name': 'Coffee', 'icon': Icons.coffee, 'color': Colors.brown},
    {'name': 'Meditation', 'icon': Icons.spa, 'color': Colors.purple},
    {
      'name': 'Volunteering',
      'icon': Icons.volunteer_activism,
      'color': Colors.red
    },
  ];

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    // Start fade in animation
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _toggleHobby(String hobby) {
    setState(() {
      if (selectedHobbies.contains(hobby)) {
        selectedHobbies.remove(hobby);
      } else {
        if (selectedHobbies.length < 10) {
          // Limit to 10 hobbies
          selectedHobbies.add(hobby);
        }
      }
    });
  }

  void _proceedToNext() {
    widget.onNext(selectedHobbies);
  }

  Widget _buildHobbyChip(Map<String, dynamic> hobby) {
    bool isSelected = selectedHobbies.contains(hobby['name']);

    return GestureDetector(
      onTap: () => _toggleHobby(hobby['name']),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        margin: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? hobby['color'].withOpacity(0.1)
              : Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? hobby['color'] : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: hobby['color'].withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hobby['icon'],
              size: 20,
              color: isSelected ? hobby['color'] : Colors.grey[600],
            ),
            SizedBox(width: 8),
            Text(
              hobby['name'],
              style: TextStyle(
                color: isSelected ? hobby['color'] : Colors.grey[700],
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 40),

            // Back button
            GestureDetector(
              onTap: widget.onBack,
              child: Container(
                padding: EdgeInsets.all(10),
                child: Icon(
                  Icons.arrow_back_ios,
                  color: Colors.grey[600],
                  size: 24,
                ),
              ),
            ),

            SizedBox(height: 40),

            // Heading
            Text(
              'What excites you outside of work?',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
                height: 1.3,
              ),
            ),

            SizedBox(height: 15),

            Text(
              selectedHobbies.isEmpty
                  ? 'Choose what makes you unique. Select up to 10 hobbies.'
                  : '${selectedHobbies.length}/10 selected. Great choices!',
              style: TextStyle(
                fontSize: 16,
                color: selectedHobbies.isEmpty
                    ? Colors.grey[600]
                    : Colors.pink[600],
                height: 1.4,
                fontWeight: selectedHobbies.isEmpty
                    ? FontWeight.normal
                    : FontWeight.w500,
              ),
            ),

            SizedBox(height: 40),

            // Hobbies grid
            Expanded(
              child: SingleChildScrollView(
                child: Wrap(
                  children: trendingHobbies
                      .map((hobby) => _buildHobbyChip(hobby))
                      .toList(),
                ),
              ),
            ),

            // Selected hobbies preview (if any selected)
            if (selectedHobbies.isNotEmpty) ...[
              Container(
                margin: EdgeInsets.only(bottom: 20),
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.pink.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.pink.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.favorite,
                          color: Colors.pink,
                          size: 20,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Your Selected Interests',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.pink[700],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Text(
                      selectedHobbies.join(' • '),
                      style: TextStyle(
                        color: Colors.pink[600],
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Continue or Skip buttons
            Row(
              children: [
                // Skip button
                Expanded(
                  flex: 1,
                  child: GestureDetector(
                    onTap: () => widget.onNext([]), // Skip with empty list
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          'Skip',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(width: 15),

                // Continue button
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: _proceedToNext,
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: selectedHobbies.isNotEmpty
                              ? [Colors.pink, Colors.pink.shade700]
                              : [Colors.grey[400]!, Colors.grey[500]!],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: selectedHobbies.isNotEmpty
                            ? [
                                BoxShadow(
                                  color: Colors.pink.withOpacity(0.3),
                                  spreadRadius: 2,
                                  blurRadius: 10,
                                  offset: Offset(0, 3),
                                ),
                              ]
                            : [],
                      ),
                      child: Center(
                        child: Text(
                          selectedHobbies.isNotEmpty
                              ? 'Continue'
                              : 'Choose Some!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

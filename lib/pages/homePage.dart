import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import 'package:patra_initial/pages/services/chat.dart';
import '../models/user.dart' as UserModel;
import '../services/cloudinary_service.dart';
import '../pages/profile_modal.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final CloudinaryService _cloudinaryService = CloudinaryService();
  List<UserModel.User> users = [];
  bool isLoading = true;
  String? error;
  // bool useMLMatching = true; // DISABLED ML SERVICE - Toggle for ML-powered matching
  bool useMLMatching = false; // ML SERVICE DISABLED
  final CardSwiperController controller = CardSwiperController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      // DISABLED ML SERVICE - Use standard matching only
      // final List<Map<String, dynamic>> usersData = useMLMatching
      //     ? await _cloudinaryService.getMLPoweredMatches(count: 20)
      //     : await _cloudinaryService.getUsersForMatching();
      final List<Map<String, dynamic>> usersData =
          await _cloudinaryService.getUsersForMatching();

      List<UserModel.User> loadedUsers = [];

      // Helper function to safely convert to List<String>
      List<String>? safeStringList(dynamic value) {
        if (value == null) return null;
        if (value is List) {
          return value
              .map((e) => e?.toString() ?? '')
              .where((s) => s.isNotEmpty)
              .toList();
        }
        if (value is String && value.isNotEmpty) {
          return [value];
        }
        return null;
      }

      for (var userData in usersData) {
        // Debug: Check age data
        // print(
        //     'User ${userData['username']}: age = ${userData['age']}, type = ${userData['age'].runtimeType}');

        // Parse age more safely
        int? parsedAge;
        if (userData['age'] != null) {
          if (userData['age'] is int) {
            parsedAge = userData['age'];
          } else if (userData['age'] is double) {
            parsedAge = userData['age'].toInt();
          } else if (userData['age'] is String) {
            parsedAge = int.tryParse(userData['age']);
          }
        }
        // print('User ${userData['username']}: parsedAge = $parsedAge');

        // No need to check hasUserSwiped individually - it's already filtered in the service
        final user = UserModel.User(
          email: userData['email'] ?? '',
          uid: userData['uid'] ?? '',
          photoUrl: userData['photoUrl'] ?? '',
          username: userData['username'] ?? '',
          bio: userData['bio'],
          age: parsedAge,
          gender: userData['gender'],
          orientation: safeStringList(userData['orientation']),
          interests: safeStringList(userData['interests']),
          location: userData['location'],
          photoUrls: safeStringList(userData['photoUrls']),
          dateOfBirth: userData['dateOfBirth'] != null
              ? (userData['dateOfBirth'] as Timestamp?)?.toDate()
              : null,
        );
        loadedUsers.add(user);
      }

      setState(() {
        users = loadedUsers;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Failed to load users: $e';
        isLoading = false;
      });
    }
  }

  // Refresh data by reloading
  Future<void> _refreshUsers() async {
    await _loadUsers();
  }

  bool _onSwipe(
    int previousIndex,
    int? currentIndex,
    CardSwiperDirection direction,
  ) {
    _handleSwipeAction(previousIndex, direction);
    return true;
  }

  Future<void> _handleSwipeAction(
      int index, CardSwiperDirection direction) async {
    if (index >= 0 && index < users.length) {
      final bool isLike = direction == CardSwiperDirection.right;
      final String targetUserId = users[index].uid;

      // Save the swipe action
      bool success =
          await _cloudinaryService.saveSwipeAction(targetUserId, isLike);

      if (success && isLike) {
        // Show a quick animation or message for likes
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You liked ${users[index].username}!'),
            duration: Duration(seconds: 1),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink.shade50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Patra',
          style: TextStyle(
            color: const Color.fromARGB(255, 13, 13, 13),
            fontWeight: FontWeight.bold,
            // fontStyle: FontStyle.italic,
            fontSize: 36,
          ),
        ),
        centerTitle: true,
        actions: [
          // ML Toggle button - DISABLED
          // IconButton(
          //   icon: Icon(
          //     useMLMatching ? Icons.psychology : Icons.people,
          //     color: useMLMatching
          //         ? Colors.purple
          //         : Color.fromARGB(255, 134, 166, 226),
          //   ),
          //   onPressed: () {
          //     setState(() {
          //       useMLMatching = !useMLMatching;
          //     });
          //     _refreshUsers();
          //     ScaffoldMessenger.of(context).showSnackBar(
          //       SnackBar(
          //         content: Text(useMLMatching
          //             ? '🤖 ML-Powered Matching Enabled'
          //             : '👥 Standard Matching Enabled'),
          //         duration: Duration(seconds: 2),
          //       ),
          //     );
          //   },
          //   tooltip:
          //       useMLMatching ? 'Using ML matching' : 'Using standard matching',
          // ),
          // Refresh button
          IconButton(
            icon:
                Icon(Icons.refresh, color: Color.fromARGB(255, 134, 166, 226)),
            onPressed: isLoading ? null : _refreshUsers,
            tooltip: 'Refresh profiles',
          ),
          IconButton(
            icon: Icon(Icons.chat_bubble,
                color: Color.fromARGB(255, 134, 166, 226)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Chat()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/animations/Search.json',
              width: 150,
              height: 150,
              fit: BoxFit.cover,
            ),
            SizedBox(height: 16),
            Text(
              // useMLMatching
              //     ? 'Finding your perfect matches with AI...'
              //     : 'Finding amazing people...',
              'Finding amazing people...', // ML SERVICE DISABLED
              style: TextStyle(
                color: Colors.pink.shade700,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              // useMLMatching
              //     ? '🤖 AI analyzing compatibility...'
              //     : '✨ Discovering your perfect matches',
              '✨ Discovering your perfect matches', // ML SERVICE DISABLED
              style: TextStyle(
                color: Colors.pink.shade400,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
            SizedBox(height: 16),
            Text(
              error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red.shade400, fontSize: 16),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadUsers,
              child: Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink.shade700,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    // Always check for empty users list to prevent CardSwiper crash
    if (users.isEmpty || users.length == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No new people in your area',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Check back later for new profiles!',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadUsers,
              child: Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink.shade700,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    // Double-check users count before creating CardSwiper
    if (users.length == 0) {
      return Center(
        child: Text('No profiles available'),
      );
    }

    return Stack(
      children: [
        Container(
          margin: EdgeInsets.only(bottom: 120), // Add margin for navbar
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: users.isNotEmpty && users.length > 0
                  ? CardSwiper(
                      controller: controller,
                      cardsCount: users.length,
                      onSwipe: _onSwipe,
                      cardBuilder: (context, index, horizontalThreshold,
                          verticalThreshold) {
                        return _buildUserCard(
                            users[index], horizontalThreshold);
                      },
                      isLoop: false,
                      allowedSwipeDirection: AllowedSwipeDirection.symmetric(
                        horizontal: true,
                      ),
                    )
                  : Center(
                      child: Text(
                        'No profiles available',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
            ),
          ),
        ),

        // Action buttons at bottom
        _buildActionButtons(),
      ],
    );
  }

  void _showUserProfile(UserModel.User user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProfileModal(user: user),
    );
  }

  Widget _buildUserCard(UserModel.User user, int swipeThreshold) {
    double swipeProgress = swipeThreshold / 100.0; // Convert to progress value
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: GestureDetector(
          onTap: () => _showUserProfile(user),
          child: Stack(
            children: [
              // Background image
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(user.primaryPhotoUrl.isNotEmpty
                        ? user.primaryPhotoUrl
                        : 'https://via.placeholder.com/400x600?text=No+Image'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              // Swipe indicator overlay
              if (swipeProgress.abs() > 0.1)
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: swipeProgress > 0
                      ? Colors.green.withOpacity(0.3)
                      : Colors.red.withOpacity(0.3),
                  child: Center(
                    child: Icon(
                      swipeProgress > 0 ? Icons.favorite : Icons.close,
                      size: 100,
                      color: Colors.white,
                    ),
                  ),
                ),

              // Profile info button - positioned at top right
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.info_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),

              // Gradient overlay for text readability
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.transparent,
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Name and age
                      Text(
                        '${user.username}, ${user.calculatedAge}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      SizedBox(height: 8),

                      // Gender and location
                      if (user.gender != null || user.location != null)
                        Row(
                          children: [
                            if (user.gender != null) ...[
                              Icon(Icons.person, color: Colors.white, size: 18),
                              SizedBox(width: 4),
                              Text(
                                user.gender!,
                                style: TextStyle(
                                    color: Colors.white, fontSize: 16),
                              ),
                            ],
                            if (user.gender != null && user.location != null)
                              SizedBox(width: 16),
                            if (user.location != null) ...[
                              Icon(Icons.location_on,
                                  color: Colors.white, size: 18),
                              SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  user.location!,
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 16),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),

                      // Bio
                      if (user.bio != null && user.bio!.isNotEmpty) ...[
                        SizedBox(height: 8),
                        Text(
                          user.bio!,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      // Interests
                      if (user.interests != null &&
                          user.interests!.isNotEmpty) ...[
                        SizedBox(height: 12),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: user.interests!.take(3).map((interest) {
                            return Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.3)),
                              ),
                              child: Text(
                                interest,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],

                      // Tap hint
                      SizedBox(height: 12),
                      Center(
                        child: Text(
                          'Tap to view full profile',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 120, // Positioned above the liquid glass navbar
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 40),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Dislike button
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: FloatingActionButton(
                heroTag: "dislike",
                onPressed: () {
                  controller.swipe(CardSwiperDirection.left);
                },
                backgroundColor: Colors.white,
                child: Icon(Icons.close, color: Colors.red, size: 30),
                elevation: 0,
              ),
            ),

            // Super like button
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: FloatingActionButton(
                heroTag: "superlike",
                onPressed: () {
                  controller.swipe(CardSwiperDirection.top);
                },
                backgroundColor: Colors.white,
                child: Icon(Icons.star, color: Colors.blue, size: 24),
                elevation: 0,
                mini: true,
              ),
            ),

            // Like button
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: FloatingActionButton(
                heroTag: "like",
                onPressed: () {
                  controller.swipe(CardSwiperDirection.right);
                },
                backgroundColor: Colors.white,
                child: Icon(Icons.favorite, color: Colors.green, size: 30),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import 'package:patra_initial/pages/services/chat.dart';
import '../models/user.dart' as UserModel;
import '../services/cloudinary_service.dart';
import '../services/like_service.dart';
import '../services/ml_service.dart';
import '../pages/profile_modal.dart';
import '../utils/text_utils.dart';

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
  bool useMLMatching =
      true; // ML SERVICE ENABLED - Toggle for ML-powered matching
  final CardSwiperController controller = CardSwiperController();

  @override
  void initState() {
    super.initState();
    print('🚀 ══════════════════════════════════════════════════════════════');
    print('🚀 PATRA APP STARTING - HOMEPAGE INITIALIZATION');
    print(
        '🤖 ML Recommendation System: ${useMLMatching ? 'ENABLED ✅' : 'DISABLED ❌'}');
    print('🔥 Loading personalized user recommendations...');
    print('══════════════════════════════════════════════════════════════');
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      print(
          '🏠 HomePage: Loading users with ML matching ${useMLMatching ? 'ENABLED' : 'DISABLED'}');

      // Use ML-powered matching when available
      final List<Map<String, dynamic>> usersData = useMLMatching
          ? await _cloudinaryService.getMLPoweredMatches(count: 20)
          : await _cloudinaryService.getUsersForMatching();

      print(
          '🏠 HomePage: Received ${usersData.length} users from ${useMLMatching ? 'ML service' : 'regular matching'}');

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

      print(
          '🏠 HomePage: Successfully converted ${loadedUsers.length} users for display');

      if (useMLMatching && loadedUsers.isNotEmpty) {
        print(
            '🎉 ══════════════════════════════════════════════════════════════');
        print(
            '🤖 ML ALGORITHM CONFIRMED: Successfully loaded ML recommendations!');
        print('📱 USERS NOW DISPLAYED IN THE APP:');

        for (int i = 0; i < loadedUsers.length && i < 8; i++) {
          final user = loadedUsers[i];
          print('   🔥 Card #${i + 1}: ${user.username} (${user.age} years)');
          print('      📍 Location: ${user.location ?? 'Unknown'}');
          print('      💝 Interests: ${user.interests?.join(', ') ?? 'None'}');
          print('      📱 Gender: ${user.gender ?? 'Not specified'}');
          print('      📸 Photos: ${user.photoUrls?.length ?? 0} uploaded');
          if (i < 3) print('      ─────────────────────────────────────');
        }

        print(
            '🎯 Total ML-recommended profiles ready for swiping: ${loadedUsers.length}');
        print('══════════════════════════════════════════════════════════════');
      } else if (!useMLMatching) {
        print('📋 Regular matching mode - ML disabled');
      } else {
        print('⚠️  No ML recommendations available - check ML service');
      }

      // Filter out users that have already been swiped (parallel processing for performance)
      print(
          '🔍 Filtering ${loadedUsers.length} users to remove already swiped...');

      final List<Future<bool>> swipeChecks = loadedUsers
          .map((user) => LikeService.hasAlreadySwiped(user.uid))
          .toList();

      final List<bool> swipeResults = await Future.wait(swipeChecks);

      List<UserModel.User> filteredUsers = [];
      for (int i = 0; i < loadedUsers.length; i++) {
        if (!swipeResults[i]) {
          filteredUsers.add(loadedUsers[i]);
        }
      }

      print(
          '📊 Filtered to ${filteredUsers.length} unswipped users out of ${loadedUsers.length} total');

      setState(() {
        users = filteredUsers;
        isLoading = false;
      });
    } catch (e) {
      print('❌ ══════════════════════════════════════════════════════════════');
      print('❌ ERROR: Failed to load users');
      print('🔍 Error details: $e');
      print(
          '💡 This might indicate ML service is down or Firebase connection issue');
      print('🔄 App will retry when user refreshes');
      print('══════════════════════════════════════════════════════════════');

      setState(() {
        error = 'Failed to load users: $e';
        isLoading = false;
      });
    }
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
      final bool isSuperLike = direction == CardSwiperDirection.top;
      final bool isDislike = direction == CardSwiperDirection.left;
      final String targetUserId = users[index].uid;

      // Save the swipe action using new LikeService
      bool success = false;
      if (isSuperLike) {
        success = await LikeService.sendSuperLike(targetUserId);
      } else if (isLike) {
        success = await LikeService.sendLike(targetUserId);
      } else if (isDislike) {
        success = await LikeService.sendDislike(targetUserId);
      }

      // Record interaction for ML learning
      if (useMLMatching) {
        String action;
        if (isSuperLike) {
          action = 'superlike';
        } else if (isLike) {
          action = 'like';
        } else {
          action = 'dislike';
        }

        print('🎯 ═══ USER INTERACTION DETECTED ═══');
        print('👤 User Action: ${action.toUpperCase()}');
        print(
            '🎭 Target: ${users[index].username} (${users[index].age}) from ${users[index].location}');
        print('🤖 Recording to ML backend for learning...');

        // Record the interaction asynchronously (don't wait for it)
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          MLService.recordInteraction(
            currentUser.uid, // current user ID from Firebase Auth
            targetUserId,
            action,
          ).then((_) {
            print(
                '✅ ML Learning: Successfully recorded $action for ${users[index].username}');
            print(
                '🧠 Algorithm will improve future recommendations based on this preference');
            print(
                '═══════════════════════════════════════════════════════════');
          }).catchError((e) {
            print('❌ ML Learning: Failed to record ML interaction: $e');
            print(
                '═══════════════════════════════════════════════════════════');
          });
        }
      }

      if (success && (isLike || isSuperLike)) {
        // Show a quick animation or message for likes/superlikes
        final actionText = isSuperLike ? 'super liked' : 'liked';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You $actionText ${users[index].username}!'),
            duration: Duration(seconds: 1),
            backgroundColor: isSuperLike ? Colors.blue : Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 254, 254),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 80, // Increased height for more space
        flexibleSpace: SafeArea(
          child: Container(
            padding: EdgeInsets.only(top: 16), // Safe area padding
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Empty left side for spacing
                SizedBox(width: 48),
                // Center content (logo + title)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      child: Image.asset(
                        'assets/Patra_logo.png',
                        width: 28,
                        height: 28,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          print('Error loading Patra logo: $error');
                          return Icon(Icons.favorite,
                              size: 28, color: Colors.red);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Patra',
                      style: TextStyle(
                        fontFamily: 'Ginger',
                        color: const Color.fromARGB(255, 13, 13, 13),
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                      ),
                    ),
                  ],
                ),
                // Right side (chat icon)
                Container(
                  margin: EdgeInsets.only(right: 8),
                  child: IconButton(
                    icon: Container(
                      width: 24,
                      height: 24,
                      child: Image.asset(
                        'assets/chat_icon.png',
                        width: 24,
                        height: 24,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          print('Error loading chat icon: $error');
                          return Icon(
                            Icons.chat_bubble,
                            size: 24,
                            color: Color.fromARGB(255, 134, 166, 226),
                          );
                        },
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => Chat()),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
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
              'Finding amazing people...',
              style: TextStyle(
                color: Colors.pink.shade700,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
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

    return Container(
      margin:
          EdgeInsets.only(bottom: 80), // Reduced margin since no action buttons
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(12), // Reduced padding for larger cards
          child: users.isNotEmpty && users.length > 0
              ? CardSwiper(
                  controller: controller,
                  cardsCount: users.length,
                  onSwipe: _onSwipe,
                  cardBuilder:
                      (context, index, horizontalThreshold, verticalThreshold) {
                    return _buildUserCard(users[index], horizontalThreshold);
                  },
                  isLoop: false,
                  allowedSwipeDirection: AllowedSwipeDirection.symmetric(
                    horizontal: true,
                    vertical: true,
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
                        '${TextUtils.formatUsername(user.username)}, ${user.calculatedAge}',
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

              // ML recommendation badge (top left)
              if (useMLMatching)
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.psychology,
                          color: Colors.white,
                          size: 12,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'AI Pick',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
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
}

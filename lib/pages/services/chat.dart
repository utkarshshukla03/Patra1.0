import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/like_request.dart';
import '../../models/match.dart';
import '../../widgets/requests_list.dart';
import '../../services/requests_service.dart';
import '../../services/matches_service.dart';
import '../../services/like_service.dart';
import '../chat_thread_page.dart';

class Chat extends StatefulWidget {
  const Chat({super.key});

  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<LikeRequest> _requests = [];
  List<Match> _matches = [];
  bool _isLoadingRequests = false;

  // Add stream subscriptions for cleanup
  Stream<List<Match>>? _matchesStream;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Listen to tab changes to refresh data when switching tabs
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        if (_tabController.index == 0) {
          // User switched to requests tab
          print('🔄 User switched to requests tab, refreshing...');
          _loadRequests();
        } else if (_tabController.index == 1) {
          // User switched to matches tab
          print('🔄 User switched to matches tab, refreshing...');
          _loadMatches();
        }
      }
    });

    // Load data immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRequests();
      _loadMatches();
    });

    // No periodic refresh needed - everything is real-time now!
  }

  void _loadRequests() {
    print('🔄 Setting up real-time requests stream...');

    setState(() {
      _isLoadingRequests = true;
    });

    // Set up real-time stream for like requests
    LikeService.getLikesReceived().listen(
      (likesData) {
        final requests = likesData.map((likeData) {
          return LikeRequest.fromFirestore(likeData, likeData['id']);
        }).toList();

        print('📦 Received ${requests.length} real-time requests');

        if (mounted) {
          setState(() {
            _requests = requests;
            _isLoadingRequests = false;
          });
        }
      },
      onError: (error) {
        print('❌ Error loading requests stream: $error');
        if (mounted) {
          setState(() {
            _requests = [];
            _isLoadingRequests = false;
          });
        }
      },
    );
  }

  void _loadMatches() {
    // Set up the real-time matches stream
    _matchesStream = MatchesService.getUserMatches();
    _matchesStream!.listen((matches) {
      if (mounted) {
        setState(() {
          _matches = matches;
        });
      }
    }, onError: (error) {
      print('❌ Error loading matches: $error');
      // Fallback to empty list if Firebase fails
      if (mounted) {
        setState(() {
          _matches = [];
        });
      }
    });
  }

  void _onAcceptRequest(String requestId) async {
    print('🎉 Accepting request: $requestId');

    // Find the request being accepted
    final request = _requests.firstWhere((req) => req.id == requestId);

    // Create the match using MatchesService
    final success = await MatchesService.createMatch(request);

    if (success) {
      print('✅ Match created successfully!');

      // Remove the accepted request from the requests list
      setState(() {
        _requests.removeWhere((req) => req.id == requestId);
      });

      // The matches list will automatically update due to the real-time listener

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ You matched with ${request.fromUserName}!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      print('❌ Failed to create match');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Failed to create match. Try again.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _onDismissRequest(String requestId) {
    print('Dismissed request: $requestId');
    // In real app, this would remove the request from backend
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Messages',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh,
              color: Colors.black,
            ),
            onPressed: () {
              // No need to refresh - real-time streams automatically update
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content:
                      Text('Real-time updates active - no refresh needed!'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            tooltip: 'Refresh requests',
          ),
          // Test button - for development only
          IconButton(
            icon: const Icon(
              Icons.science,
              color: Colors.blue,
            ),
            onPressed: () async {
              // Create test like from Unnati to Utkarsh
              final success =
                  await RequestsService.createUnnatiLikesUtkarshTest();
              if (success) {
                // Real-time stream will automatically update the UI
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        '✅ Test: Unnati liked Utkarsh! Watch for real-time update...'),
                    duration: Duration(seconds: 2),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            tooltip: 'Create test like (Unnati → Utkarsh)',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(25),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: false, // Ensure tabs take equal width
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey.shade600,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Requests'),
                      if (_requests.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.pink.shade500,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_requests.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Matches'),
                      if (_matches.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade500,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_matches.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Requests Tab
          _isLoadingRequests
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Loading requests...',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : RequestsList(
                  requests: _requests,
                  onAccept: _onAcceptRequest,
                  onDismiss: _onDismissRequest,
                ),

          // Matches Tab
          _buildMatchesList(),
        ],
      ),
    );
  }

  Widget _buildMatchesList() {
    if (_matches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline,
                size: 64,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No matches yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Accept requests to start chatting\nwith your matches',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade500,
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _matches.length,
      itemBuilder: (context, index) {
        final match = _matches[index];
        return _buildMatchCard(match);
      },
    );
  }

  Widget _buildMatchCard(Match match) {
    // Get the other user's data (not the current user)
    final currentUser = FirebaseAuth.instance.currentUser;
    final isCurrentUserUser1 = currentUser?.uid == match.user1Id;
    final otherUserData =
        isCurrentUserUser1 ? match.user2Data : match.user1Data;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundImage: NetworkImage(otherUserData['photo'] ??
                  'https://via.placeholder.com/400x600?text=No+Image'),
            ),
            // Show unread indicator if there's a recent message
            if (match.lastMessageAt != null &&
                DateTime.now().difference(match.lastMessageAt!).inMinutes < 60)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.pink.shade500,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          otherUserData['name'] ?? 'Unknown User',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          match.lastMessage ?? 'You matched! Start a conversation.',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          _formatTimestamp(match.lastMessageAt ?? match.matchedAt),
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 12,
          ),
        ),
        onTap: () {
          // Navigate to chat thread with real match data
          final currentUser = FirebaseAuth.instance.currentUser;
          final otherUserId =
              match.user1Id == currentUser?.uid ? match.user2Id : match.user1Id;

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatThreadPage(
                matchId: match.id,
                otherUserId: otherUserId,
                otherUserName: otherUserData['name'] ?? 'Unknown User',
                otherUserPhoto: otherUserData['photo'] ??
                    'https://via.placeholder.com/400x600?text=No+Image',
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inDays}d';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

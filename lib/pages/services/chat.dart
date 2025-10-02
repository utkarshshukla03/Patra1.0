import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/like_request.dart';
import '../../widgets/requests_list.dart';
import '../../services/requests_service.dart';

class Chat extends StatefulWidget {
  const Chat({super.key});

  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<LikeRequest> _requests = [];
  List<Map<String, dynamic>> _matches = [];
  bool _isLoadingRequests = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Listen to tab changes to refresh data when switching to requests tab
    _tabController.addListener(() {
      if (_tabController.indexIsChanging && _tabController.index == 0) {
        // User switched to requests tab
        print('🔄 User switched to requests tab, refreshing...');
        _loadRequests();
      }
    });

    // Load data immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRequests();
      _loadMatches();
    });

    // Refresh requests every 30 seconds to simulate real-time updates
    _startPeriodicRefresh();
  }

  void _startPeriodicRefresh() {
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        _refreshRequests();
        _startPeriodicRefresh();
      }
    });
  }

  Future<void> _refreshRequests() async {
    _loadRequests();
  }

  void _loadRequests() async {
    if (_isLoadingRequests) return; // Prevent multiple simultaneous loads

    setState(() {
      _isLoadingRequests = true;
    });

    try {
      print('🔄 Loading requests...');

      // Get current user UID
      final currentUser = FirebaseAuth.instance.currentUser;
      final userUID = currentUser?.uid ??
          'HfdoBOlYEBO54oUpaSqPTf5ML452'; // Default for testing

      print('👤 Current user UID: $userUID');

      // Load requests from service using UID instead of email
      final requestsData =
          await RequestsService.getTestRequestsForUser(userUID);

      print('📦 Received ${requestsData.length} requests from service');

      // Convert to LikeRequest objects
      final requests = requestsData.map((data) {
        print('🔍 Processing request data: ${data.keys.toList()}');
        return LikeRequest(
          id: data['id'],
          fromUserId: data['fromUserId'],
          fromUserName: data['userInfo']['name'],
          fromUserPhoto: data['userInfo']['photo'],
          fromUserAge: data['userInfo']['age'] ?? 22,
          fromUserBio: data['userInfo']['bio'],
          type: data['type'] == 'superlike'
              ? RequestType.superlike
              : RequestType.like,
          timestamp: data['timestamp'],
          fullUserData: data['userInfo'], // Pass complete user data
        );
      }).toList();

      print('✅ Successfully processed ${requests.length} requests');

      setState(() {
        _requests = requests;
        _isLoadingRequests = false;
      });
    } catch (e) {
      print('❌ Error loading requests: $e');
      // Fallback to mock data
      setState(() {
        _requests = LikeRequest.getMockRequests();
        _isLoadingRequests = false;
      });
    }
  }

  void _loadMatches() {
    setState(() {
      _matches = [
        {
          'id': '1',
          'name': 'Sarah',
          'photo':
              'https://images.unsplash.com/photo-1494790108755-2616b67fcec?w=400',
          'lastMessage': 'Hey! Thanks for the like! 😊',
          'timestamp': DateTime.now().subtract(Duration(minutes: 30)),
          'unread': true,
        },
        {
          'id': '2',
          'name': 'Jessica',
          'photo':
              'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=400',
          'lastMessage': 'Would love to grab coffee sometime!',
          'timestamp': DateTime.now().subtract(Duration(hours: 2)),
          'unread': false,
        },
      ];
    });
  }

  void _onAcceptRequest(String requestId) {
    print('Accepted request: $requestId');
    // In real app, this would create a match and start a chat
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
              _refreshRequests();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Refreshing requests...'),
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
                _refreshRequests();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Test: Unnati liked Utkarsh!'),
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
                const Tab(text: 'Matches'),
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

  Widget _buildMatchCard(Map<String, dynamic> match) {
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
              backgroundImage: NetworkImage(match['photo']),
            ),
            if (match['unread'])
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
          match['name'],
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          match['lastMessage'],
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          _formatTimestamp(match['timestamp']),
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 12,
          ),
        ),
        onTap: () {
          // Navigate to chat thread (mock)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Opening chat with ${match['name']}'),
              behavior: SnackBarBehavior.floating,
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

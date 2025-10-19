import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/swipe_analytics_service.dart';

class SwipeAnalyticsPage extends StatefulWidget {
  const SwipeAnalyticsPage({Key? key}) : super(key: key);

  @override
  State<SwipeAnalyticsPage> createState() => _SwipeAnalyticsPageState();
}

class _SwipeAnalyticsPageState extends State<SwipeAnalyticsPage> {
  Map<String, dynamic>? _userStats;
  Map<String, dynamic>? _dailyInfo;
  List<Map<String, dynamic>> _swipeHistory = [];
  List<Map<String, dynamic>> _incomingSwipes = [];
  double _matchRate = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        SwipeAnalyticsService.getUserSwipeStats(null),
        SwipeAnalyticsService.getDailySwipeInfo(null),
        SwipeAnalyticsService.getUserSwipeHistory(null, limit: 20),
        SwipeAnalyticsService.getIncomingSwipes(),
        SwipeAnalyticsService.getUserMatchRate(null),
      ]);

      setState(() {
        _userStats = results[0] as Map<String, dynamic>?;
        _dailyInfo = results[1] as Map<String, dynamic>;
        _swipeHistory = results[2] as List<Map<String, dynamic>>;
        _incomingSwipes = results[3] as List<Map<String, dynamic>>;
        _matchRate = results[4] as double;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error loading analytics: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Swipe Analytics'),
        backgroundColor: Colors.pink.shade700,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOverviewCards(),
                    const SizedBox(height: 24),
                    _buildDailyProgress(),
                    const SizedBox(height: 24),
                    _buildSwipeBreakdown(),
                    const SizedBox(height: 24),
                    _buildIncomingLikes(),
                    const SizedBox(height: 24),
                    _buildRecentActivity(),
                    const SizedBox(height: 24),
                    _buildDebugSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildOverviewCards() {
    if (_userStats == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overview',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Swipes',
                '${_userStats!['totalSwipes'] ?? 0}',
                Icons.swipe,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Matches',
                '${_userStats!['matchCount'] ?? 0}',
                Icons.favorite,
                Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Match Rate',
                '${_matchRate.toStringAsFixed(1)}%',
                Icons.trending_up,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Super Likes',
                '${_userStats!['superlikeCount'] ?? 0}',
                Icons.star,
                Colors.amber,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyProgress() {
    if (_dailyInfo == null) return const SizedBox();

    final todaySwipes = _dailyInfo!['todaySwipes'] ?? 0;
    final dailyLimit = _dailyInfo!['dailyLimit'] ?? 100;
    final progress = todaySwipes / dailyLimit;
    final dateKey = _dailyInfo!['dateKey'] ?? 'Unknown';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Today\'s Activity',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: _loadAnalytics,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink.shade700,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Date: $dateKey',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$todaySwipes / $dailyLimit swipes'),
              Text(
                '${_dailyInfo!['remainingSwipes']} remaining',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(
              progress > 0.8 ? Colors.red : Colors.pink.shade700,
            ),
          ),
          if (progress > 0.9)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'You\'re close to your daily limit!',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSwipeBreakdown() {
    if (_userStats == null) return const SizedBox();

    final likes = _userStats!['likeCount'] ?? 0;
    final superlikes = _userStats!['superlikeCount'] ?? 0;
    final rejects = _userStats!['rejectCount'] ?? 0;
    final total = likes + superlikes + rejects;

    if (total == 0) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Swipe Breakdown',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildSwipeBar('Likes', likes, total, Colors.green),
          const SizedBox(height: 8),
          _buildSwipeBar('Super Likes', superlikes, total, Colors.blue),
          const SizedBox(height: 8),
          _buildSwipeBar('Passes', rejects, total, Colors.grey),
        ],
      ),
    );
  }

  Widget _buildSwipeBar(String label, int count, int total, Color color) {
    final percentage = total > 0 ? (count / total) * 100 : 0.0;

    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        Expanded(
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: Colors.grey.shade300,
            ),
            child: FractionallySizedBox(
              widthFactor: percentage / 100,
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: color,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 40,
          child: Text(
            '$count',
            style: const TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildIncomingLikes() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'People Who Liked You',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '${_incomingSwipes.length}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.pink.shade700,
                ),
              ),
            ],
          ),
          if (_incomingSwipes.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'No incoming likes yet',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ...(_incomingSwipes.take(3).map((swipe) => Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: swipe['fromUser']['photoUrls'] !=
                                    null &&
                                swipe['fromUser']['photoUrls'].isNotEmpty
                            ? NetworkImage(swipe['fromUser']['photoUrls'][0])
                            : null,
                        child: swipe['fromUser']['photoUrls'] == null ||
                                swipe['fromUser']['photoUrls'].isEmpty
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          swipe['fromUser']['name'] ?? 'Unknown',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      Icon(
                        swipe['actionType'] == 'superlike'
                            ? Icons.star
                            : Icons.favorite,
                        color: swipe['actionType'] == 'superlike'
                            ? Colors.blue
                            : Colors.red,
                        size: 20,
                      ),
                    ],
                  ),
                ))),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Activity',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (_swipeHistory.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'No recent activity',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ...(_swipeHistory.take(5).map((swipe) => Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Icon(
                        swipe['actionType'] == 'like'
                            ? Icons.favorite
                            : swipe['actionType'] == 'superlike'
                                ? Icons.star
                                : Icons.close,
                        color: swipe['actionType'] == 'like'
                            ? Colors.green
                            : swipe['actionType'] == 'superlike'
                                ? Colors.blue
                                : Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${swipe['actionType']} action',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      Text(
                        _formatTimestamp(swipe['timestamp']),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ))),
        ],
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';

    try {
      DateTime dateTime;
      if (timestamp is Timestamp) {
        dateTime = timestamp.toDate();
      } else if (timestamp is DateTime) {
        dateTime = timestamp;
      } else {
        return '';
      }

      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Now';
      }
    } catch (e) {
      return '';
    }
  }

  Widget _buildDebugSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade300),
        color: Colors.orange.shade50,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Debug Tools',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'Use these tools to test the swipe tracking system:',
            style: TextStyle(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    // Simulate a like action
                    final success =
                        await SwipeAnalyticsService.resetDailySwipeCount(null);
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Daily swipe count reset!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      _loadAnalytics(); // Refresh the data
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Reset Daily Count'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // Show instructions
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Testing Instructions'),
                        content: const Text(
                          'To test swipe tracking:\n\n'
                          '1. Go to the Home page\n'
                          '2. Swipe on some profiles\n'
                          '3. Return here and tap "Refresh"\n'
                          '4. Your swipe counts should update!\n\n'
                          'Note: Each swipe (left/right/up) counts toward your daily limit.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Got it!'),
                          ),
                        ],
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('How to Test'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../models/like_request.dart';
import '../widgets/request_card.dart';

class RequestsList extends StatefulWidget {
  final List<LikeRequest> requests;
  final Function(String requestId) onAccept;
  final Function(String requestId) onDismiss;

  const RequestsList({
    super.key,
    required this.requests,
    required this.onAccept,
    required this.onDismiss,
  });

  @override
  State<RequestsList> createState() => _RequestsListState();
}

class _RequestsListState extends State<RequestsList> {
  late List<LikeRequest> _requests;

  @override
  void initState() {
    super.initState();
    _requests = List.from(widget.requests);
  }

  void _handleAccept(String requestId) {
    widget.onAccept(requestId);
    setState(() {
      _requests.removeWhere((request) => request.id == requestId);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Match created! 💕'),
        backgroundColor: Colors.green.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _handleDismiss(String requestId) {
    widget.onDismiss(requestId);
    setState(() {
      _requests.removeWhere((request) => request.id == requestId);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_requests.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 100),
      itemCount: _requests.length,
      itemBuilder: (context, index) {
        final request = _requests[index];
        return RequestCard(
          key: Key(request.id),
          request: request,
          onAccept: () => _handleAccept(request.id),
          onDismiss: () => _handleDismiss(request.id),
        );
      },
    );
  }

  Widget _buildEmptyState() {
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
              Icons.favorite_border,
              size: 64,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No requests yet',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'When someone likes you,\ntheir request will appear here',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.pink.shade400, Colors.pink.shade600],
              ),
              borderRadius: BorderRadius.circular(25),
            ),
            child: const Text(
              'Start swiping to get matches!',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

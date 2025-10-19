import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/match_notification_service.dart';
import '../models/match_notification.dart';
import 'match_animation_overlay.dart';

class MatchNotificationHandler extends StatefulWidget {
  final Widget child;

  const MatchNotificationHandler({
    super.key,
    required this.child,
  });

  @override
  State<MatchNotificationHandler> createState() =>
      _MatchNotificationHandlerState();
}

class _MatchNotificationHandlerState extends State<MatchNotificationHandler> {
  OverlayEntry? _overlayEntry;
  bool _isShowingAnimation = false;

  @override
  void initState() {
    super.initState();
    _listenForMatchNotifications();
  }

  void _listenForMatchNotifications() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    MatchNotificationService.getUnreadNotifications(currentUser.uid).listen(
      (notifications) {
        if (notifications.isNotEmpty && !_isShowingAnimation) {
          _showMatchAnimation(notifications.first);
        }
      },
    );
  }

  void _showMatchAnimation(MatchNotification notification) {
    if (_isShowingAnimation) return;

    setState(() {
      _isShowingAnimation = true;
    });

    _overlayEntry = OverlayEntry(
      builder: (context) => MatchAnimationOverlay(
        currentUserData: notification.toUserData,
        matchedUserData: notification.fromUserData,
        onComplete: () {
          _hideMatchAnimation();
          // Mark notification as read
          MatchNotificationService.markAsRead(notification.id);
        },
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideMatchAnimation() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }

    setState(() {
      _isShowingAnimation = false;
    });
  }

  @override
  void dispose() {
    _hideMatchAnimation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

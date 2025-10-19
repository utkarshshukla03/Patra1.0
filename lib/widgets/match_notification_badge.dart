import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/match_notification_service.dart';

class MatchNotificationBadge extends StatelessWidget {
  final Widget child;

  const MatchNotificationBadge({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return child;

    return StreamBuilder(
      stream: MatchNotificationService.getUnreadNotifications(currentUser.uid),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data?.length ?? 0;

        if (unreadCount == 0) {
          return child;
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            child,
            Positioned(
              right: -8,
              top: -8,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  unreadCount > 9 ? '9+' : unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_message.dart';

class ChatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Send a message in a chat
  static Future<bool> sendMessage({
    required String matchId,
    required String receiverId,
    required String message,
    MessageType type = MessageType.text,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('❌ No current user found');
        return false;
      }

      // Get current user data
      final currentUserDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();

      if (!currentUserDoc.exists) {
        print('❌ Current user document not found');
        return false;
      }

      final currentUserData = currentUserDoc.data()!;
      final senderName = currentUserData['username'] ?? 'Unknown';

      // Create the message document
      final messageData = {
        'matchId': matchId,
        'senderId': currentUser.uid,
        'receiverId': receiverId,
        'senderName': senderName,
        'content': message,
        'type': type.toString().split('.').last, // Convert enum to string
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      };

      // Add the message to the messages subcollection under the match
      final messageRef = await _firestore
          .collection('matches')
          .doc(matchId)
          .collection('messages')
          .add(messageData);

      // Update the match document with the last message
      await _firestore.collection('matches').doc(matchId).update({
        'lastMessage': message,
        'lastMessageAt': FieldValue.serverTimestamp(),
      });

      print('✅ Message sent successfully');
      return true;
    } catch (e) {
      print('❌ Error sending message: $e');
      return false;
    }
  }

  // Get real-time messages for a match
  static Stream<List<ChatMessage>> getMessages(String matchId) {
    return _firestore
        .collection('matches')
        .doc(matchId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return ChatMessage(
          id: doc.id,
          senderId: data['senderId'] ?? '',
          senderName: data['senderName'] ?? 'Unknown',
          content: data['content'] ?? '',
          type: _parseMessageType(data['type']),
          timestamp:
              (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
          isRead: data['isRead'] ?? false,
        );
      }).toList();
    });
  }

  // Mark messages as read
  static Future<void> markMessagesAsRead(
      String matchId, String currentUserId) async {
    try {
      // Get unread messages for the current user in this match
      final unreadMessages = await _firestore
          .collection('matches')
          .doc(matchId)
          .collection('messages')
          .where('receiverId', isEqualTo: currentUserId)
          .where('isRead', isEqualTo: false)
          .get();

      // Mark them as read using batch
      final batch = _firestore.batch();
      for (final doc in unreadMessages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      if (unreadMessages.docs.isNotEmpty) {
        await batch.commit();
        print('✅ Marked ${unreadMessages.docs.length} messages as read');
      }
    } catch (e) {
      print('❌ Error marking messages as read: $e');
    }
  }

  // Get unread message count for a match
  static Stream<int> getUnreadMessageCount(
      String matchId, String currentUserId) {
    return _firestore
        .collection('matches')
        .doc(matchId)
        .collection('messages')
        .where('receiverId', isEqualTo: currentUserId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Get all unread message count for current user (across all matches)
  static Stream<int> getTotalUnreadMessageCount() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value(0);
    }

    // This requires getting all matches and counting unread messages in each
    return _firestore
        .collection('matches')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .asyncMap((matchSnapshot) async {
      int totalUnread = 0;

      for (final matchDoc in matchSnapshot.docs) {
        final matchData = matchDoc.data();
        final user1Id = matchData['user1Id'];
        final user2Id = matchData['user2Id'];

        // Check if current user is part of this match
        if (user1Id == currentUser.uid || user2Id == currentUser.uid) {
          final unreadSnapshot = await _firestore
              .collection('matches')
              .doc(matchDoc.id)
              .collection('messages')
              .where('receiverId', isEqualTo: currentUser.uid)
              .where('isRead', isEqualTo: false)
              .get();

          totalUnread += unreadSnapshot.docs.length;
        }
      }

      return totalUnread;
    });
  }

  // Delete a message
  static Future<bool> deleteMessage(String matchId, String messageId) async {
    try {
      await _firestore
          .collection('matches')
          .doc(matchId)
          .collection('messages')
          .doc(messageId)
          .delete();
      print('✅ Message deleted successfully');
      return true;
    } catch (e) {
      print('❌ Error deleting message: $e');
      return false;
    }
  }

  // Send typing indicator
  static Future<void> sendTypingIndicator(
      String matchId, String receiverId, bool isTyping) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final typingData = {
        'matchId': matchId,
        'userId': currentUser.uid,
        'receiverId': receiverId,
        'isTyping': isTyping,
        'timestamp': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('matches')
          .doc(matchId)
          .collection('typing_indicators')
          .doc(currentUser.uid)
          .set(typingData);
    } catch (e) {
      print('❌ Error sending typing indicator: $e');
    }
  }

  // Listen to typing indicators
  static Stream<bool> getTypingIndicator(String matchId, String otherUserId) {
    return _firestore
        .collection('matches')
        .doc(matchId)
        .collection('typing_indicators')
        .doc(otherUserId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return false;
      final data = doc.data()!;

      // Check if the typing indicator is recent (within last 3 seconds)
      final timestamp = data['timestamp'] as Timestamp?;
      if (timestamp != null) {
        final timeDiff = DateTime.now().difference(timestamp.toDate());
        if (timeDiff.inSeconds > 3) {
          return false; // Too old, consider not typing
        }
      }

      return data['isTyping'] ?? false;
    });
  }

  // Helper method to parse message type
  static MessageType _parseMessageType(String? typeString) {
    switch (typeString) {
      case 'image':
        return MessageType.image;
      case 'voice':
        return MessageType.voice;
      default:
        return MessageType.text;
    }
  }

  // Get recent chats (matches with messages)
  static Stream<List<Map<String, dynamic>>> getRecentChats() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    // Get matches where user is involved and has messages
    return _firestore
        .collection('matches')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .asyncMap((matchSnapshot) async {
      final List<Map<String, dynamic>> chats = [];

      for (final matchDoc in matchSnapshot.docs) {
        final matchData = matchDoc.data();
        final user1Id = matchData['user1Id'];
        final user2Id = matchData['user2Id'];

        // Check if current user is part of this match
        if (user1Id == currentUser.uid || user2Id == currentUser.uid) {
          final otherUserId = user1Id == currentUser.uid ? user2Id : user1Id;
          final otherUserData = user1Id == currentUser.uid
              ? matchData['user2Data']
              : matchData['user1Data'];

          // Get message count for this match
          final messageSnapshot = await _firestore
              .collection('matches')
              .doc(matchDoc.id)
              .collection('messages')
              .get();

          if (messageSnapshot.docs.isNotEmpty) {
            // Get unread count
            final unreadSnapshot = await _firestore
                .collection('matches')
                .doc(matchDoc.id)
                .collection('messages')
                .where('receiverId', isEqualTo: currentUser.uid)
                .where('isRead', isEqualTo: false)
                .get();

            chats.add({
              'matchId': matchDoc.id,
              'otherUserId': otherUserId,
              'otherUserData': otherUserData,
              'lastMessage': matchData['lastMessage'],
              'lastMessageAt': matchData['lastMessageAt'],
              'unreadCount': unreadSnapshot.docs.length,
            });
          }
        }
      }

      // Sort by last message time
      chats.sort((a, b) {
        final aTime = a['lastMessageAt'] as Timestamp?;
        final bTime = b['lastMessageAt'] as Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });

      return chats;
    });
  }

  // Send image message
  static Future<bool> sendImageMessage({
    required String matchId,
    required String receiverId,
    required String imageUrl,
  }) async {
    return await sendMessage(
      matchId: matchId,
      receiverId: receiverId,
      message: imageUrl,
      type: MessageType.image,
    );
  }

  // Send voice message
  static Future<bool> sendVoiceMessage({
    required String matchId,
    required String receiverId,
    required String voiceUrl,
  }) async {
    return await sendMessage(
      matchId: matchId,
      receiverId: receiverId,
      message: voiceUrl,
      type: MessageType.voice,
    );
  }
}

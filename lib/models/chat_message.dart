class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.type,
    required this.timestamp,
    this.isRead = false,
  });

  static List<ChatMessage> getMockMessages(String chatId) {
    return [
      ChatMessage(
        id: '1',
        senderId: 'other_user',
        senderName: 'Emma',
        content: 'Hey! Thanks for the like! 😊',
        type: MessageType.text,
        timestamp: DateTime.now().subtract(Duration(minutes: 30)),
      ),
      ChatMessage(
        id: '2',
        senderId: 'current_user',
        senderName: 'You',
        content: 'Hi Emma! How are you doing?',
        type: MessageType.text,
        timestamp: DateTime.now().subtract(Duration(minutes: 25)),
      ),
      ChatMessage(
        id: '3',
        senderId: 'other_user',
        senderName: 'Emma',
        content: 'Great! Just finished a yoga session. What about you?',
        type: MessageType.text,
        timestamp: DateTime.now().subtract(Duration(minutes: 20)),
      ),
      ChatMessage(
        id: '4',
        senderId: 'current_user',
        senderName: 'You',
        content: 'That sounds amazing! I love yoga too 🧘‍♂️',
        type: MessageType.text,
        timestamp: DateTime.now().subtract(Duration(minutes: 15)),
      ),
    ];
  }
}

enum MessageType {
  text,
  image,
  voice,
}

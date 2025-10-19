import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';
import '../widgets/message_composer.dart';
import '../utils/text_utils.dart';
import 'dart:async';

class ChatThreadPage extends StatefulWidget {
  final String matchId;
  final String otherUserId;
  final String otherUserName;
  final String otherUserPhoto;

  const ChatThreadPage({
    super.key,
    required this.matchId,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserPhoto,
  });

  @override
  State<ChatThreadPage> createState() => _ChatThreadPageState();
}

class _ChatThreadPageState extends State<ChatThreadPage> {
  List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  StreamSubscription<List<ChatMessage>>? _messagesSubscription;
  StreamSubscription<bool>? _typingSubscription;
  bool _isOtherUserTyping = false;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _markMessagesAsRead();
    _listenToTypingIndicator();
  }

  void _loadMessages() {
    // Set up real-time message listener
    _messagesSubscription = ChatService.getMessages(widget.matchId).listen(
      (messages) {
        setState(() {
          _messages = messages;
        });
        // Scroll to bottom when new messages arrive
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      },
      onError: (error) {
        print('❌ Error loading messages: $error');
      },
    );
  }

  void _markMessagesAsRead() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      ChatService.markMessagesAsRead(widget.matchId, currentUser.uid);
    }
  }

  void _listenToTypingIndicator() {
    _typingSubscription = ChatService.getTypingIndicator(widget.matchId, widget.otherUserId).listen(
      (isTyping) {
        setState(() {
          _isOtherUserTyping = isTyping;
        });
      },
    );
  }

  Future<void> _sendMessage(String content, MessageType type) async {
    if (content.trim().isEmpty) return;

    // Clear the text field immediately for better UX
    _messageController.clear();

    // Stop typing indicator
    await ChatService.sendTypingIndicator(widget.matchId, widget.otherUserId, false);

    // Send the message
    final success = await ChatService.sendMessage(
      matchId: widget.matchId,
      receiverId: widget.otherUserId,
      message: content.trim(),
      type: type,
    );

    if (!success) {
      // Show error message if sending failed
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Failed to send message. Try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: NetworkImage(widget.otherUserPhoto),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    TextUtils.formatUsername(widget.otherUserName),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    'Active now',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.videocam_outlined, color: Colors.grey.shade600),
            onPressed: () {
              // Mock video call
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Video call feature coming soon!')),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.phone_outlined, color: Colors.grey.shade600),
            onPressed: () {
              // Mock phone call
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Voice call feature coming soon!')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Match notification
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.pink.shade50, Colors.purple.shade50],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.pink.shade100),
            ),
            child: Row(
              children: [
                Icon(Icons.favorite, color: Colors.pink.shade400, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You and ${TextUtils.formatUsername(widget.otherUserName)} liked each other!',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _messages.length + (_isOtherUserTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isOtherUserTyping) {
                  // Show typing indicator at the end
                  return _buildTypingIndicator();
                }
                
                final message = _messages[index];
                final currentUser = FirebaseAuth.instance.currentUser;
                final isCurrentUser = message.senderId == currentUser?.uid;
                final showTime = index == 0 ||
                    _messages[index - 1]
                            .timestamp
                            .difference(message.timestamp)
                            .inMinutes >
                        5;

                return Column(
                  children: [
                    if (showTime) _buildTimeHeader(message.timestamp),
                    _buildMessageBubble(message, isCurrentUser),
                  ],
                );
              },
            ),
          ),

          // Message composer
          MessageComposer(
            onSendMessage: _sendMessage,
            controller: _messageController,
            onTextChanged: _onTextChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundImage: NetworkImage(widget.otherUserPhoto),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 40,
                  child: Row(
                    children: [
                      for (int i = 0; i < 3; i++)
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(right: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade500,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeHeader(DateTime timestamp) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        _formatTime(timestamp),
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade500,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isCurrentUser) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isCurrentUser) ...[
            CircleAvatar(
              radius: 12,
              backgroundImage: NetworkImage(widget.otherUserPhoto),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isCurrentUser ? Colors.pink.shade500 : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isCurrentUser ? 20 : 4),
                  bottomRight: Radius.circular(isCurrentUser ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _buildMessageContent(message, isCurrentUser),
            ),
          ),
          if (isCurrentUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 12,
              backgroundColor: Colors.pink.shade100,
              child: Text(
                'Y',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.pink.shade700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageContent(ChatMessage message, bool isCurrentUser) {
    switch (message.type) {
      case MessageType.text:
        return Text(
          message.content,
          style: TextStyle(
            color: isCurrentUser ? Colors.white : Colors.black87,
            fontSize: 16,
            height: 1.3,
          ),
        );
      case MessageType.image:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 200,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.image, size: 50),
            ),
            if (message.content.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                message.content,
                style: TextStyle(
                  color: isCurrentUser ? Colors.white : Colors.black87,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        );
      case MessageType.voice:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.play_arrow,
              color: isCurrentUser ? Colors.white : Colors.pink.shade500,
            ),
            const SizedBox(width: 8),
            Container(
              width: 100,
              height: 20,
              decoration: BoxDecoration(
                color: isCurrentUser
                    ? Colors.white.withOpacity(0.3)
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '0:32',
              style: TextStyle(
                color: isCurrentUser ? Colors.white70 : Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        );
    }
  }

  void _onTextChanged(String text) {
    // Send typing indicator
    if (text.isNotEmpty) {
      ChatService.sendTypingIndicator(widget.matchId, widget.otherUserId, true);
      
      // Cancel previous timer
      _typingTimer?.cancel();
      
      // Set new timer to stop typing indicator after 2 seconds of inactivity
      _typingTimer = Timer(const Duration(seconds: 2), () {
        ChatService.sendTypingIndicator(widget.matchId, widget.otherUserId, false);
      });
    } else {
      ChatService.sendTypingIndicator(widget.matchId, widget.otherUserId, false);
      _typingTimer?.cancel();
    }
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    _typingSubscription?.cancel();
    _typingTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

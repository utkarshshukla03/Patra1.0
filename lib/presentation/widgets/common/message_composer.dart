import 'package:flutter/material.dart';
// Update the import path below to the correct location of chat_message.dart, for example:
import 'package:patra_initial/models/chat_message.dart';
// Or create the file at ../models/chat_message.dart if it does not exist.

class MessageComposer extends StatefulWidget {
  final Function(String content, MessageType type) onSendMessage;

  const MessageComposer({
    super.key,
    required this.onSendMessage,
  });

  @override
  State<MessageComposer> createState() => _MessageComposerState();
}

class _MessageComposerState extends State<MessageComposer> {
  final TextEditingController _textController = TextEditingController();
  bool _isRecording = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      setState(() {
        _hasText = _textController.text.trim().isNotEmpty;
      });
    });
  }

  void _sendTextMessage() {
    if (_textController.text.trim().isNotEmpty) {
      widget.onSendMessage(_textController.text.trim(), MessageType.text);
      _textController.clear();
    }
  }

  void _sendImageMessage() {
    // Mock image sharing
    widget.onSendMessage('Shared an image', MessageType.image);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Image sharing feature coming soon!')),
    );
  }

  void _toggleVoiceRecording() {
    setState(() {
      _isRecording = !_isRecording;
    });

    if (_isRecording) {
      // Mock start recording
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🎤 Recording... (mock)')),
      );
    } else {
      // Mock send voice message
      widget.onSendMessage('Voice message (0:32)', MessageType.voice);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voice message sent! (mock)')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Image button
            GestureDetector(
              onTap: _sendImageMessage,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.image_outlined,
                  color: Colors.grey.shade600,
                  size: 20,
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Text input field
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: TextField(
                  controller: _textController,
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (_) => _sendTextMessage(),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Send/Voice button
            GestureDetector(
              onTap: _hasText ? _sendTextMessage : _toggleVoiceRecording,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _hasText || _isRecording
                      ? Colors.pink.shade500
                      : Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: _hasText || _isRecording
                      ? [
                          BoxShadow(
                            color: Colors.pink.shade200,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    _hasText
                        ? Icons.send_rounded
                        : _isRecording
                            ? Icons.stop
                            : Icons.mic_outlined,
                    color: Colors.white,
                    size: 20,
                    key: ValueKey(_hasText
                        ? 'send'
                        : _isRecording
                            ? 'stop'
                            : 'mic'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../models/message_model.dart';
import 'package:intl/intl.dart';

import '../providers/app_auth_provider.dart';
import '../providers/message_provider.dart';

// Updated ChatScreen
class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  late MessageProvider _messageProvider;
  late User _matchedUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _messageProvider = MessageProvider();

    // Use post-frame callback to ensure we have route arguments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMessages();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _messageProvider.stopMessagesStream();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      // Get matched user from route arguments with null safety
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args == null) {
        // Handle case when no arguments are passed
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      _matchedUser = args as User;

      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      // Load messages for this match
      await _messageProvider.loadMessages(_matchedUser.id);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading messages: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) {
      return;
    }

    final messageText = _messageController.text.trim();
    _messageController.clear();

    // Send the message
    bool success = await _messageProvider.sendMessage(
        _matchedUser.id,
        messageText
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send message. Please try again.'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if we have _matchedUser before proceeding
    if (ModalRoute.of(context)?.settings.arguments == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Get the matched user if not already set
    if (!this.mounted) {
      _matchedUser = ModalRoute.of(context)!.settings.arguments as User;
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(_matchedUser.imageUrls[0]),
              radius: 16,
            ),
            const SizedBox(width: 8),
            Text(_matchedUser.name),
          ],
        ),
        elevation: 1,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildChatMessages(),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildChatMessages() {
    final messages = _messageProvider.messages;

    if (messages.isEmpty) {
      return _buildEmptyChatView();
    }

    return AnimatedBuilder(
      animation: _messageProvider,
      builder: (context, _) {
        final updatedMessages = _messageProvider.messages;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          reverse: true,
          itemCount: updatedMessages.length,
          itemBuilder: (context, index) {
            final message = updatedMessages[index];
            final isMe = message.senderId == Provider.of<AppAuthProvider>(context, listen: false).currentUserId;

            return _buildMessageBubble(message, isMe);
          },
        );
      },
    );
  }


  Widget _buildMessageBubble(Message message, bool isMe) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe)
            CircleAvatar(
              backgroundImage: NetworkImage(_matchedUser.imageUrls[0]),
              radius: 16,
            ),
          if (!isMe) const SizedBox(width: 8),

          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isMe ? Colors.red : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('h:mm a').format(message.timestamp),
                    style: TextStyle(
                      fontSize: 10,
                      color: isMe ? Colors.white70 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (isMe) const SizedBox(width: 8),
          if (isMe)
            const CircleAvatar(
              backgroundImage: NetworkImage('https://i.pravatar.cc/300?img=33'),
              radius: 16,
            ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade200,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Colors.red,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChatView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            backgroundImage: NetworkImage(_matchedUser.imageUrls[0]),
            radius: 60,
          ),
          const SizedBox(height: 16),
          Text(
            'You matched with ${_matchedUser.name}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Send a message to start the conversation',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
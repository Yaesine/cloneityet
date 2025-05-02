import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/message_model.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final List<Message> _messages = [];
  late User _matchedUser;

  @override
  void initState() {
    super.initState();
    // Load dummy messages in simulated delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _messages.addAll(_getDummyMessages());
        });
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  List<Message> _getDummyMessages() {
    // In a real app, these would come from a database or API
    final currentUserId = 'user_123';
    final matchedUserId = _matchedUser.id;

    return [
      Message(
        id: 'm1',
        senderId: matchedUserId,
        receiverId: currentUserId,
        text: 'Hey there! How are you?',
        timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      ),
      Message(
        id: 'm2',
        senderId: currentUserId,
        receiverId: matchedUserId,
        text: 'Hi! I\'m good, thanks for asking. How about you?',
        timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 1)),
      ),
      Message(
        id: 'm3',
        senderId: matchedUserId,
        receiverId: currentUserId,
        text: 'I\'m doing well! I noticed we both like hiking. What\'s your favorite trail?',
        timestamp: DateTime.now().subtract(const Duration(hours: 12)),
      ),
    ];
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) {
      return;
    }

    final newMessage = Message(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderId: 'user_123', // Current user ID
      receiverId: _matchedUser.id,
      text: _messageController.text,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(newMessage);
      _messageController.clear();
    });

    // Simulate a reply after a short delay
    if (_messages.length % 2 == 0) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          final replyMessage = Message(
            id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
            senderId: _matchedUser.id,
            receiverId: 'user_123',
            text: 'That sounds interesting! Tell me more about it.',
            timestamp: DateTime.now(),
          );

          setState(() {
            _messages.add(replyMessage);
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the matched user from route arguments
    _matchedUser = ModalRoute.of(context)!.settings.arguments as User;

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
            child: _messages.isEmpty
                ? _buildEmptyChatView()
                : _buildChatMessages(),
          ),
          _buildMessageInput(),
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

  Widget _buildChatMessages() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      reverse: true,
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[_messages.length - 1 - index];
        final isMe = message.senderId == 'user_123';

        return _buildMessageBubble(message, isMe);
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
}
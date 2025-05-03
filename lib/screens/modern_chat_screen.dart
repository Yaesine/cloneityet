import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../models/message_model.dart';
import 'package:intl/intl.dart';

import '../providers/app_auth_provider.dart';
import '../providers/message_provider.dart';
import '../theme/app_theme.dart';

class ModernChatScreen extends StatefulWidget {
  const ModernChatScreen({Key? key}) : super(key: key);

  @override
  _ModernChatScreenState createState() => _ModernChatScreenState();
}

class _ModernChatScreenState extends State<ModernChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  User? _matchedUser;
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    // Use post-frame callback to ensure we have route arguments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMessages();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      print("Attempting to load messages");
      // Get matched user from route arguments with null safety
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args == null) {
        print("No arguments passed to ModernChatScreen");
        // Handle case when no arguments are passed
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error: No user data provided'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.of(context).pop();
        }
        return;
      }

      setState(() {
        _matchedUser = args as User;
        _isLoading = true;
      });

      print("Matched user ID: ${_matchedUser!.id}, Name: ${_matchedUser!.name}");

      // Load messages for this match using the Provider
      final messageProvider = Provider.of<MessageProvider>(context, listen: false);
      await messageProvider.loadMessages(_matchedUser!.id);
      print("Messages loaded successfully");

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading messages: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _matchedUser == null) {
      return;
    }

    print("Attempting to send message: ${_messageController.text}");

    setState(() {
      _isSending = true;
    });

    final messageText = _messageController.text.trim();
    _messageController.clear();

    // Send the message
    try {
      final messageProvider = Provider.of<MessageProvider>(context, listen: false);
      bool success = await messageProvider.sendMessage(_matchedUser!.id, messageText);

      print("Message send result: $success");

      if (mounted) {
        setState(() {
          _isSending = false;
        });

        if (!success) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to send message. Please try again.'),
                backgroundColor: Colors.red,
              )
          );
        }
      }
    } catch (e) {
      print("Error sending message: $e");
      if (mounted) {
        setState(() {
          _isSending = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            )
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _matchedUser != null
            ? Text("Chat with ${_matchedUser!.name}")
            : const Text("Chat"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Expanded(
            child: Consumer<MessageProvider>(
              builder: (context, messageProvider, _) {
                final messages = messageProvider.messages;

                if (messages.isEmpty) {
                  return _buildEmptyChat();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == Provider.of<AppAuthProvider>(context, listen: false).currentUserId;

                    return _buildMessageBubble(message, isMe);
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildEmptyChat() {
    if (_matchedUser == null) {
      return const Center(child: Text("No user data"));
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: NetworkImage(_matchedUser!.imageUrls.isNotEmpty
                ? _matchedUser!.imageUrls[0]
                : 'https://i.pravatar.cc/300?img=33'),
          ),
          const SizedBox(height: 16),
          Text(
            'You matched with ${_matchedUser!.name}!',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Send a message to start the conversation',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              _messageController.text = 'Hi ${_matchedUser!.name}, nice to meet you!';
            },
            child: const Text('Start with a greeting'),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isMe) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe && _matchedUser != null) ...[
            CircleAvatar(
              backgroundImage: NetworkImage(_matchedUser!.imageUrls.isNotEmpty
                  ? _matchedUser!.imageUrls[0]
                  : 'https://i.pravatar.cc/300?img=33'),
              radius: 16,
            ),
            const SizedBox(width: 8),
          ],

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isMe ? Theme.of(context).primaryColor : Colors.grey.shade200,
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
                    color: isMe ? Colors.white.withOpacity(0.7) : Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundImage: const NetworkImage('https://i.pravatar.cc/300?img=33'),
              radius: 16,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _isSending ? null : _sendMessage,
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(12),
            ),
            child: _isSending
                ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}
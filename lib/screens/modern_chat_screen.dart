import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../models/message_model.dart';
import 'package:intl/intl.dart';

import '../providers/app_auth_provider.dart';
import '../providers/message_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/components/loading_indicator.dart';

class ModernChatScreen extends StatefulWidget {
  const ModernChatScreen({Key? key}) : super(key: key);

  @override
  _ModernChatScreenState createState() => _ModernChatScreenState();
}

class _ModernChatScreenState extends State<ModernChatScreen> {
  final _messageController = TextEditingController();
  late MessageProvider _messageProvider;
  User? _matchedUser;
  bool _isLoading = true;
  bool _isSending = false;

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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error: No user data provided'),
              backgroundColor: AppColors.error,
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

      // Load messages for this match
      await _messageProvider.loadMessages(_matchedUser!.id);

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
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    final messageText = _messageController.text.trim();
    _messageController.clear();

    // Send the message
    bool success = await _messageProvider.sendMessage(
        _matchedUser!.id,
        messageText
    );

    if (mounted) {
      setState(() {
        _isSending = false;
      });

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to send message. Please try again.'),
              backgroundColor: AppColors.error,
            )
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // If still loading and no matched user, show loading screen
    if (_matchedUser == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 20),
            onPressed: () => Navigator.of(context).pop(),
            color: AppColors.text,
          ),
          title: const Text('Chat'),
        ),
        body: const Center(
          child: LoadingIndicator(
            type: LoadingIndicatorType.circular,
            message: 'Loading conversation...',
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 1,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.text,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Hero(
              tag: 'avatar_${_matchedUser!.id}',
              child: CircleAvatar(
                backgroundImage: NetworkImage(_matchedUser!.imageUrls[0]),
                radius: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _matchedUser!.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Online now',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.secondary,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // Show options menu
              showModalBottomSheet(
                context: context,
                builder: (context) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.person, color: AppColors.primary),
                        title: const Text('View Profile'),
                        onTap: () {
                          Navigator.pop(context);
                          // Navigate to user profile
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.block, color: AppColors.error),
                        title: const Text('Unmatch'),
                        onTap: () {
                          Navigator.pop(context);
                          // Show unmatch confirmation
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(
              child: LoadingIndicator(
                type: LoadingIndicatorType.circular,
              ),
            )
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
          if (!isMe) ...[
            CircleAvatar(
              backgroundImage: NetworkImage(_matchedUser!.imageUrls[0]),
              radius: 16,
            ),
            const SizedBox(width: 8),
          ],

          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: isMe ? Colors.white : AppColors.text,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('h:mm a').format(message.timestamp),
                    style: TextStyle(
                      fontSize: 10,
                      color: isMe ? Colors.white.withOpacity(0.7) : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (isMe) ...[
            const SizedBox(width: 8),
            Hero(
              tag: 'current_user_avatar',
              child: CircleAvatar(
                backgroundImage: const NetworkImage('https://i.pravatar.cc/300?img=33'),
                radius: 16,
                backgroundColor: AppColors.primaryLight,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.photo_outlined, color: AppColors.primary),
              onPressed: () {
                // Handle image upload
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Photo sharing coming soon!'))
                );
              },
            ),
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
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.4),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(25),
                  onTap: _isSending ? null : _sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: _isSending
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : const Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyChatView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Hero(
            tag: 'avatar_${_matchedUser!.id}',
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: NetworkImage(_matchedUser!.imageUrls[0]),
                  fit: BoxFit.cover,
                ),
                border: Border.all(
                  color: Colors.white,
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'You matched with ${_matchedUser!.name}!',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Send a message to start the conversation',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              _messageController.text = 'Hi ${_matchedUser!.name}, nice to meet you!';
              FocusScope.of(context).requestFocus(FocusNode());
            },
            icon: const Icon(Icons.chat_bubble_outline),
            label: const Text('Start with a greeting'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
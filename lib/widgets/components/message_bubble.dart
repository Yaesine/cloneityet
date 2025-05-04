// lib/widgets/components/message_bubble.dart
import 'package:flutter/material.dart';
import '../../models/message_model.dart';
import '../../theme/app_theme.dart';
import 'package:intl/intl.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final bool showTimestamp;
  final VoidCallback? onReply;
  final Function(String emoji)? onReact;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.isMe,
    this.showTimestamp = false,
    this.onReply,
    this.onReact,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _showMessageOptions(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        child: Row(
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe) _buildAvatar(),
            if (!isMe) const SizedBox(width: 8),

            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isMe ? AppColors.primary : Colors.grey[200],
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(isMe ? 16 : 4),
                    topRight: Radius.circular(isMe ? 4 : 16),
                    bottomLeft: const Radius.circular(16),
                    bottomRight: const Radius.circular(16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (message.type == MessageType.text)
                      Text(
                        message.text,
                        style: TextStyle(
                          color: isMe ? Colors.white : Colors.black,
                          fontSize: 15,
                        ),
                      ),
                    if (message.type == MessageType.image && message.mediaUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          message.mediaUrl!,
                          width: 200,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),

                    const SizedBox(height: 4),

                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormat('HH:mm').format(message.timestamp),
                          style: TextStyle(
                            color: (isMe ? Colors.white : Colors.black).withOpacity(0.6),
                            fontSize: 11,
                          ),
                        ),
                        if (isMe) const SizedBox(width: 4),
                        if (isMe) _buildDeliveryStatus(),
                      ],
                    ),

                    if (message.reactions?.isNotEmpty ?? false)
                      _buildReactions(),
                  ],
                ),
              ),
            ),

            if (isMe) const SizedBox(width: 8),
            if (isMe) _buildAvatar(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 12,
      backgroundColor: isMe ? AppColors.primary : Colors.grey[400],
      child: Text(
        'U',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDeliveryStatus() {
    if (message.isRead) {
      return Icon(Icons.done_all, size: 14, color: Colors.lightBlueAccent);
    } else if (message.isDelivered) {
      return Icon(Icons.done_all, size: 14, color: Colors.grey);
    } else {
      return Icon(Icons.done, size: 14, color: Colors.grey);
    }
  }

  Widget _buildReactions() {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 4,
        children: message.reactions!.entries.map((entry) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${entry.key} ${entry.value}',
              style: TextStyle(fontSize: 12),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showMessageOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onReact != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ['😂', '❤️', '😮', '😢', '😡', '👍'].map((emoji) {
                  return GestureDetector(
                    onTap: () {
                      onReact!(emoji);
                      Navigator.pop(context);
                    },
                    child: Text(emoji, style: TextStyle(fontSize: 32)),
                  );
                }).toList(),
              ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.reply),
              title: Text('Reply'),
              onTap: () {
                onReply?.call();
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.copy),
              title: Text('Copy'),
              onTap: () {
                // Copy message text
                Navigator.pop(context);
              },
            ),
            if (isMe)
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () {
                  // Delete message
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }
}
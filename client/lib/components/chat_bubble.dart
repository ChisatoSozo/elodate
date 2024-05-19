import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

class ChatBubble extends StatefulWidget {
  final String text;
  final bool isMe;
  final DateTime timestamp;
  final Image? image;

  const ChatBubble({
    super.key,
    required this.text,
    required this.isMe,
    required this.timestamp,
    this.image,
  });

  @override
  ChatBubbleState createState() => ChatBubbleState();
}

class ChatBubbleState extends State<ChatBubble>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Align(
      alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onTap: _toggleExpanded,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: widget.isMe
                ? theme.colorScheme.primary
                : isDarkMode
                    ? Colors.grey[700]
                    : Colors.grey[300],
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(widget.isMe ? 16 : 0),
              bottomRight: Radius.circular(widget.isMe ? 0 : 16),
            ),
          ),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.image != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: widget.image,
                    ),
                  ),
                Text(
                  widget.text,
                  style: TextStyle(
                    color: widget.isMe
                        ? theme.colorScheme.onPrimary
                        : isDarkMode
                            ? Colors.white
                            : Colors.black,
                  ),
                ),
                if (_isExpanded)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      timeago.format(widget.timestamp),
                      style: TextStyle(
                        color: widget.isMe
                            ? theme.colorScheme.onPrimary.withOpacity(0.7)
                            : isDarkMode
                                ? Colors.white70
                                : Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

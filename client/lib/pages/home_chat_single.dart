import 'package:client/api/pkg/lib/api.dart';
import 'package:client/components/chat_bubble.dart';
import 'package:client/components/responsive_container.dart';
import 'package:client/models/home_model.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String displayName;

  const ChatScreen(
      {super.key, required this.chatId, required this.displayName});

  @override
  ChatScreenState createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  List<Message> messages = [];
  UserWithImagesAndEloAndUuid? me;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      Provider.of<HomeModel>(context, listen: false)
          .getMessages(widget.chatId)
          .then((value) {
        setState(() {
          messages = value;
        });
      });
    });
  }

  void _sendMessage() {
    if (_controller.text.isNotEmpty) {
      // Here you would handle sending the message
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      // Here you would handle the picked image
    }
  }

  @override
  Widget build(BuildContext context) {
    if (me == null) {
      Provider.of<HomeModel>(context, listen: false).getMe().then((value) {
        setState(() {
          me = value;
        });
      });

      return const Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.displayName),
      ),
      body: ResponsiveContainer(
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView.builder(
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  final bool isMe = message.author ==
                      me!.uuid; // You need to replace "yourUserId" with the actual user ID logic
                  return ChatBubble(
                    text: message.content,
                    isMe: isMe,
                    timestamp:
                        DateTime.now(), //TODO: Replace with actual timestamp
                  );
                },
              ),
            ),
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Row(
      children: <Widget>[
        Expanded(
          child: TextField(
            controller: _controller,
            decoration: const InputDecoration(
              hintText: 'Send a message...',
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.send),
          onPressed: _sendMessage,
        ),
        IconButton(
          icon: const Icon(Icons.camera_alt),
          onPressed: () => _pickImage(ImageSource.camera),
        ),
        IconButton(
          icon: const Icon(Icons.photo_library),
          onPressed: () => _pickImage(ImageSource.gallery),
        ),
      ],
    );
  }
}

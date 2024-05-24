import 'dart:async'; // Add this import
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:client/api/pkg/lib/api.dart';
import 'package:client/components/chat_bubble.dart';
import 'package:client/components/responsive_container.dart';
import 'package:client/components/uuid_image_provider.dart';
import 'package:client/models/home_model.dart';
import 'package:client/utils/utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

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
  final FocusNode _focusNode = FocusNode();
  ApiChat? _chat;
  final List<ApiMessage> _messages = [];
  Uint8List? _selectedImage;
  String? _selectedImageMimeType;
  Timer? _timer; // Declare a Timer
  bool _isSendButtonEnabled = false; // New variable

  @override
  void initState() {
    super.initState();
    _fetchChat(); // Initial fetch
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _fetchChat();
    });
    _controller.addListener(_updateSendButtonState); // Add listener
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer when disposing
    _controller.removeListener(_updateSendButtonState); // Remove listener
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _updateSendButtonState() {
    setState(() {
      _isSendButtonEnabled =
          _controller.text.isNotEmpty || _selectedImage != null;
    });
  }

  void _fetchChat() async {
    var chat = await Provider.of<HomeModel>(context, listen: false)
        .getChat(widget.chatId);
    //is there new messages, if so, fetch the new ones
    if (_chat != null && chat.messages.length > _chat!.messages.length) {
      var newMessages = chat.messages
          .sublist(_chat!.messages.length, chat.messages.length)
          .toList();
      _chat = chat;
      _fetchMessages(newMessages);
    }
    if (_chat == null) {
      _chat = chat;
      _fetchMessages(chat.messages);
    }
    _chat = chat;
  }

  void _fetchMessages(List<String> newMessages) async {
    var messages = await Provider.of<HomeModel>(context, listen: false)
        .getMessages(widget.chatId, newMessages);
    setState(() {
      _messages.addAll(messages);
    });
  }

  void _sendMessage() async {
    Provider.of<HomeModel>(context, listen: false)
        .sendChatMessage(
          widget.chatId,
          SendMessageInputMessage(
            uuid: const Uuid().v4(),
            content: _controller.text,
            image: _selectedImage == null
                ? null
                : ApiUserWritableImagesInner(
                    b64Content: base64Encode(_selectedImage!),
                    imageType: mimeToType(_selectedImageMimeType!),
                  ),
          ),
        )
        .then((value) => {
              _fetchChat(),
            });

    setState(() {
      _controller.clear();
      _selectedImage = null;
      _selectedImageMimeType = null;
      _isSendButtonEnabled = false; // Reset send button state
    });
    _focusNode.requestFocus();
  }

  Future<void> _pickImage(ImageSource source) async {
    if (kIsWeb) {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'png', 'webp'],
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _selectedImage = result.files.single.bytes;
          _selectedImageMimeType = result.files.single.extension;
          _isSendButtonEnabled = true; // Enable send button
        });
      }
    } else {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path).readAsBytesSync();
          _selectedImageMimeType = pickedFile.mimeType;
          _isSendButtonEnabled = true; // Enable send button
        });
      }
    }
  }

  void _removeSelectedImage() {
    setState(() {
      _selectedImage = null;
      _selectedImageMimeType = null;
      _isSendButtonEnabled =
          _controller.text.isNotEmpty; // Update send button state
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final chatBarColor = isDarkMode ? Colors.grey[850] : Colors.grey[300];
    final inputFieldColor = isDarkMode ? Colors.grey[800] : Colors.grey[200];
    final homeModel = Provider.of<HomeModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.displayName),
      ),
      body: ResponsiveContainer(
        child: Column(
          children: <Widget>[
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: ListView.builder(
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[_messages.length - index - 1];
                    final bool isMe = message.author == homeModel.me.uuid;
                    return ChatBubble(
                        key: Key(message.uuid),
                        text: message.content,
                        image: message.image == null
                            ? null
                            : Image(
                                width: 200,
                                image: UuidImageProvider(
                                    uuid: message.image!,
                                    homeModel: homeModel)),
                        isMe: isMe,
                        timestamp: DateTime.fromMillisecondsSinceEpoch(
                            message.sentAt * 1000));
                  },
                  reverse: true,
                  shrinkWrap: true,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: chatBarColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16.0),
                  topRight: Radius.circular(16.0),
                ),
              ),
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_selectedImage != null)
                    Stack(
                      children: [
                        Container(
                          alignment: Alignment.centerLeft,
                          child: Image.memory(
                            _selectedImage!,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: _removeSelectedImage,
                            child: const MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: CircleAvatar(
                                backgroundColor: Colors.black54,
                                child: Icon(
                                  Icons.close,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  _buildMessageInput(inputFieldColor!),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput(Color inputFieldColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: 'Send a message...',
                fillColor: inputFieldColor,
                filled: true,
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _isSendButtonEnabled ? _sendMessage : null,
            color: _isSendButtonEnabled ? null : Colors.grey,
          ),
          if (!kIsWeb)
            IconButton(
              icon: const Icon(Icons.camera_alt),
              onPressed: () => _pickImage(ImageSource.camera),
            ),
          IconButton(
            icon: const Icon(Icons.photo_library),
            onPressed: () => _pickImage(ImageSource.gallery),
          ),
        ],
      ),
    );
  }
}

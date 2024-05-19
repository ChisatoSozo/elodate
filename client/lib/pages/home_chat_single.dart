import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:client/api/pkg/lib/api.dart';
import 'package:client/components/chat_bubble.dart';
import 'package:client/components/responsive_container.dart';
import 'package:client/models/home_model.dart';
import 'package:client/utils/utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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
  final FocusNode _focusNode = FocusNode();
  List<Message> _messages = [];
  UserWithImagesAndEloAndUuid? _me;
  Uint8List? _selectedImage;
  String? _selectedImageMimeType;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      Provider.of<HomeModel>(context, listen: false)
          .getMessages(widget.chatId)
          .then((value) {
        setState(() {
          _messages = value;
        });
      });
    });
  }

  void _sendMessage() {
    Provider.of<HomeModel>(context, listen: false)
        .sendChatMessage(
            widget.chatId,
            SendMessageInputMessage(
                content: _controller.text,
                uuid: widget.chatId,
                image: _selectedImage == null
                    ? null
                    : MessageImage(
                        b64Content: base64Encode(_selectedImage!),
                        imageType: mimeToType(_selectedImageMimeType!)),
                imageType: _selectedImageMimeType == null
                    ? null
                    : fromMesageImageImageTypeEnum(
                        mimeToType(_selectedImageMimeType!))))
        .then((value) {
      Provider.of<HomeModel>(context, listen: false)
          .getMessages(widget.chatId)
          .then((value) {
        setState(() {
          _messages = value;
        });
      });
    });
    if (_controller.text.isNotEmpty) {
      setState(() {
        _controller.clear();
        _selectedImage = null;
        _selectedImageMimeType = null;
      });
      _focusNode.requestFocus();
    }
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
        });
      }
    } else {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path).readAsBytesSync();
          _selectedImageMimeType = pickedFile.mimeType;
        });
      }
    }
  }

  void _removeSelectedImage() {
    setState(() {
      _selectedImage = null;
      _selectedImageMimeType = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final chatBarColor = isDarkMode ? Colors.grey[850] : Colors.grey[300];
    final inputFieldColor = isDarkMode ? Colors.grey[800] : Colors.grey[200];

    if (_me == null) {
      Provider.of<HomeModel>(context, listen: false).getMe().then((value) {
        setState(() {
          _me = value;
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
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  final bool isMe = message.author == _me!.uuid;
                  return ChatBubble(
                      text: message.content,
                      image: message.image == null
                          ? null
                          : Image.memory(
                              base64Decode(message.image!.b64Content),
                              fit: BoxFit.cover,
                            ),
                      isMe: isMe,
                      timestamp: DateTime.fromMillisecondsSinceEpoch(
                          message.sentAt * 1000));
                },
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
      ),
    );
  }
}

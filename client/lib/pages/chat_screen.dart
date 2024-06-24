import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:client/api/pkg/lib/api.dart';
import 'package:client/components/chat/chat_bubble.dart';
import 'package:client/components/elodate_scaffold.dart';
import 'package:client/components/uuid_image_provider.dart';
import 'package:client/models/user_model.dart';
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
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final FocusNode _focusNode = FocusNode();
  final List<ApiMessage> _messages = [];
  ApiChat? _chat;
  Uint8List? _selectedImage;
  Timer? _timer;
  bool _isSendButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
    _initChat();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.removeListener(_updateSendButtonState);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _initChat() {
    _fetchChat();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchChat());
    _controller.addListener(_updateSendButtonState);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final chatBarColor = isDarkMode ? Colors.grey[850] : Colors.grey[300];
    final inputFieldColor = isDarkMode ? Colors.grey[800] : Colors.grey[200];
    final formKey = GlobalKey<FormState>();

    return ElodateScaffold(
      reverseScrollDirection: true,
      appBar: AppBar(
        title: Text(widget.displayName),
      ),
      body: Form(
        key: formKey,
        child: _buildMessageList(context),
      ),
      bottomNavigationBar: _buildInputSection(chatBarColor!, inputFieldColor!),
    );
  }

  Widget _buildMessageList(BuildContext context) {
    final userModel = Provider.of<UserModel>(context, listen: false);
    return ListView.builder(
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[_messages.length - index - 1];
        final isMe = message.author == userModel.me.uuid;
        return ChatBubble(
          key: ValueKey(message.uuid),
          text: message.content,
          image: _buildMessageImage(message, userModel),
          isMe: isMe,
          timestamp: DateTime.fromMillisecondsSinceEpoch(
            message.sentAt * 1000,
          ),
        );
      },
      reverse: true,
      shrinkWrap: true,
    );
  }

  Image? _buildMessageImage(ApiMessage message, UserModel userModel) {
    return message.image == null
        ? null
        : Image(
            width: 200,
            image:
                UuidImageProvider(uuid: message.image!, userModel: userModel),
          );
  }

  Widget _buildInputSection(Color chatBarColor, Color inputFieldColor) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
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
          if (_selectedImage != null) _buildSelectedImagePreview(),
          _buildMessageInput(inputFieldColor),
        ],
      ),
    );
  }

  Widget _buildSelectedImagePreview() {
    return Stack(
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
    );
  }

  Widget _buildMessageInput(Color inputFieldColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
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

  void _updateSendButtonState() {
    setState(() {
      _isSendButtonEnabled =
          _controller.text.isNotEmpty || _selectedImage != null;
    });
  }

  Future<void> _fetchChat() async {
    var chat = await _getChat(widget.chatId);
    if (_chat != null && chat.messages.length > _chat!.messages.length) {
      var newMessages = chat.messages.sublist(_chat!.messages.length);
      _fetchMessages(newMessages);
    }
    if (_chat == null) {
      _chat = chat;
      _fetchMessages(chat.messages);
    }
    setState(() {
      _chat = chat;
    });
  }

  Future<void> _fetchMessages(List<String> newMessages) async {
    var userModel = Provider.of<UserModel>(context, listen: false);
    var messages = await userModel.client.getMessagesPost(
        GetMessagesInput(chatUuid: _chat!.uuid, messages: newMessages));

    if (messages == null) {
      throw Exception('Failed to get messages');
    }

    setState(() {
      _messages.addAll(messages);
    });
  }

  Future<void> _sendMessage() async {
    var userModel = Provider.of<UserModel>(context, listen: false);
    var client = userModel.client;
    String? uuid;

    if (_selectedImage != null) {
      var compressed = await compressImage(_selectedImage!);
      uuid = await client.putImagePost(PutImageInput(
          content: base64Encode(compressed), access: _chat!.users));
      //trim first and last quotes
      uuid = uuid!.substring(1, uuid.length - 1);
    }

    await client.sendMessagePost(SendMessageInput(
      chatUuid: _chat!.uuid,
      message: SendMessageInputMessage(content: _controller.text, image: uuid),
    ));

    await _fetchChat();

    setState(() {
      _controller.clear();
      _selectedImage = null;
      _isSendButtonEnabled = false;
    });

    _focusNode.requestFocus();
  }

  Future<void> _pickImage(ImageSource source) async {
    if (kIsWeb) {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _selectedImage = result.files.single.bytes;
          _isSendButtonEnabled = true;
        });
      }
    } else {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        var selectedImage = await pickedFile.readAsBytes();
        setState(() {
          _selectedImage = selectedImage;
          _isSendButtonEnabled = true;
        });
      }
    }
  }

  void _removeSelectedImage() {
    setState(() {
      _selectedImage = null;
      _isSendButtonEnabled = _controller.text.isNotEmpty;
    });
  }

  Future<ApiChat> _getChat(String chatUuid) async {
    var client = Provider.of<UserModel>(context, listen: false).client;
    var chat = await client.getChatsPost([chatUuid]);

    if (chat == null || chat.isEmpty) {
      throw Exception('Chat not found');
    }

    if (chat.length > 1) {
      throw Exception('Too many chats found');
    }

    return chat.first;
  }
}

import 'dart:convert';

import 'package:client/api/pkg/lib/api.dart';
import 'package:client/models/home_model.dart';
import 'package:client/pages/home_chat_single.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  ChatPageState createState() => ChatPageState();
}

class ChatPageState extends State<ChatPage> {
  List<(Chat, UserWithImagesAndElo)>? chats;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      Provider.of<HomeModel>(context, listen: false)
          .getChats()
          .then((value) => {
                setState(() {
                  chats = value;
                })
              });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chats"),
        automaticallyImplyLeading: false,
      ),
      body: chats == null
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: chats!.length,
              itemBuilder: (context, index) {
                final chat =
                    chats![index].$1; // Assuming this holds the chat data
                final user =
                    chats![index].$2; // Assuming this holds the user data

                var imageData = base64Decode(user.images[0].b64Content);

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: MemoryImage(imageData),
                  ),
                  title: Text(user.user.displayName,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  subtitle: Text(chat.mostRecentMessage,
                      style: const TextStyle(fontSize: 14)),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                              chatId: chat.uuid,
                              displayName: user.user.displayName),
                        ));
                  },
                );
              },
            ),
    );
  }
}

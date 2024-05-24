import 'package:client/components/uuid_image_provider.dart';
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
  @override
  void initState() {
    super.initState();
    var homeModel = Provider.of<HomeModel>(context, listen: false);
    homeModel.initChats(homeModel.me);
  }

  @override
  Widget build(BuildContext context) {
    var chats = Provider.of<HomeModel>(context).chats;
    var homeModel = Provider.of<HomeModel>(context);
    return Scaffold(
      body: ListView.builder(
        itemCount: chats.length,
        itemBuilder: (context, index) {
          final (user, chat) = chats[index];

          return ListTile(
            leading: CircleAvatar(
              backgroundImage:
                  UuidImageProvider(uuid: user.images[0], homeModel: homeModel),
            ),
            title: Text(user.displayName,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            subtitle: Text(
                chat.mostRecentSender == homeModel.me.uuid
                    ? "You: ${chat.mostRecentMessage}"
                    : "${user.displayName}: ${chat.mostRecentMessage}",
                style: const TextStyle(fontSize: 14)),
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                        chatId: chat.uuid, displayName: user.displayName),
                  ));
            },
          );
        },
      ),
    );
  }
}

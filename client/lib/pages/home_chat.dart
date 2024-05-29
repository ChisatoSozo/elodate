import 'package:client/api/pkg/lib/api.dart';
import 'package:client/components/uuid_image_provider.dart';
import 'package:client/models/user_model.dart';
import 'package:client/pages/home_chat_single.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  ChatPageState createState() => ChatPageState();
}

class ChatPageState extends State<ChatPage> {
  List<(ApiUser, ApiChat)> chats = [];
  @override
  void initState() {
    super.initState();
    initChats();
  }

  @override
  Widget build(BuildContext context) {
    var userModel = Provider.of<UserModel>(context, listen: false);
    var me = userModel.me;
    return ListView.builder(
      itemCount: chats.length,
      itemBuilder: (context, index) {
        final (user, chat) = chats[index];

        return ListTile(
          leading: CircleAvatar(
            backgroundImage:
                UuidImageProvider(uuid: user.images[0], userModel: userModel),
          ),
          title: Text(user.displayName,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          subtitle: Text(
              chat.mostRecentSender == me.uuid
                  ? "You: ${chat.mostRecentMessage}"
                  : "${user.displayName}: ${chat.mostRecentMessage}",
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: Theme.of(context).textTheme.bodyMedium),
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
    );
  }

  Future<void> initChats() async {
    var userModel = Provider.of<UserModel>(context, listen: false);
    var client = userModel.client;
    var me = userModel.me;
    var result = await client.getChatsPost(me.chats);

    if (result == null) {
      throw Exception('Failed to get chat messages');
    }
    var users = await client.getUsersPost(result
        .map((e) => (e.mostRecentSender == null
            ? e.users.firstWhere((element) => element != me.uuid)
            : e.mostRecentSender == me.uuid
                ? e.users.firstWhere((element) => element != me.uuid)
                : e.mostRecentSender)!)
        .toList());

    if (users == null) {
      throw Exception('Failed to get chat users');
    }

    List<(ApiUser, ApiChat)> newChats = [];
    for (var i = 0; i < result.length; i++) {
      newChats.add((users[i], result[i]));
    }
    setState(() {
      chats = newChats;
    });
  }
}

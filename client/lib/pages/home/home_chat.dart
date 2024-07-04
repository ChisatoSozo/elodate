import 'dart:async';

import 'package:client/api/pkg/lib/api.dart';
import 'package:client/components/uuid_image_provider.dart';
import 'package:client/models/user_model.dart';
import 'package:client/router/elo_router_nav.dart';
import 'package:client/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  ChatPageState createState() => ChatPageState();
}

class ChatPageState extends State<ChatPage> {
  List<(ApiUser, ApiChat)> chats = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    initChats();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => initChats());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var userModel = Provider.of<UserModel>(context, listen: false);
    var me = userModel.me;
    var pageWidth = calcPageWidth(context);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: pageWidth),
        child: Column(
          children: chats.map((chatPair) {
            final (user, chat) = chatPair;
            return ListTile(
              key: ValueKey(chat.uuid),
              leading: CircleAvatar(
                backgroundImage: UuidImageProvider(
                    uuid: user.images[0], userModel: userModel),
              ),
              title: Text(user.displayName,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              subtitle: Text(
                  chat.mostRecentSender == me.uuid
                      ? "You: ${chat.mostRecentMessage}"
                      : chat.mostRecentMessage,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: chat.unread > 0
                          ? Theme.of(context).textTheme.bodyMedium?.color ??
                              Colors.red
                          : Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey
                              : Colors.grey)),
              trailing: chat.unread > 0
                  ? Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red,
                      ),
                      child: Text(
                        '${chat.unread}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    )
                  : null,
              onTap: () {
                EloNav.goChat(context, chat.uuid, user.displayName);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> initChats() async {
    var userModel = Provider.of<UserModel>(context, listen: false);
    await userModel.updateMe();
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

    //sort chats by most recent message
    newChats.sort((a, b) =>
        b.$2.mostRecentMessageSentAt.compareTo(a.$2.mostRecentMessageSentAt));

    print("loaded chats");

    setState(() {
      chats = newChats;
    });
  }
}

import 'package:client/api/pkg/lib/api.dart';
import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';

class HomeModel extends ChangeNotifier {
  DefaultApi? _client;
  UserWithImagesAndEloAndUuid? _me;

  Future<DefaultApi> getClient() async {
    _client ??= await initClient();
    return _client!;
  }

  Future<List<(ChatAndLastMessage, UserWithImagesAndElo)>> getChats() async {
    return await initChats();
  }

  Future<UserWithImagesAndEloAndUuid?> getMe() async {
    _me ??= await initMe();
    return _me;
  }

  Future<DefaultApi?> initClient() async {
    var jwt = localStorage.getItem('jwt');
    if (jwt == null) {
      return null;
    }

    var auth = HttpBearerAuth();
    auth.accessToken = jwt;

    var client = DefaultApi(
        ApiClient(basePath: 'http://localhost:8080', authentication: auth));

    _client = client;
    return client;
  }

  Future<List<(ChatAndLastMessage, UserWithImagesAndElo)>> initChats() async {
    var client = await getClient();
    var me = await getMe();
    var result = await client.getMyChatsPost();

    if (me == null) {
      throw Exception('Failed to get user');
    }

    if (result == null) {
      throw Exception('Failed to get chat messages');
    }
    List<(ChatAndLastMessage, UserWithImagesAndElo)> chats = [];
    for (var chat in result) {
      var notMe = [chat.chat.user1, chat.chat.user2]
          .firstWhere((element) => element != me.uuid);
      var user = await client.getUserWithSingleImagePost(notMe);
      if (user == null) {
        throw Exception('Failed to get user');
      }
      chats.add((chat, user));
    }

    return chats;
  }

  Future<UserWithImagesAndEloAndUuid> initMe() async {
    var client = await getClient();
    var me = await client.getMePost();
    if (me == null) {
      throw Exception('Failed to get user');
    }
    _me = me;
    return me;
  }
}

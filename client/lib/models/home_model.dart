import 'package:client/api/pkg/lib/api.dart';
import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';

class HomeModel extends ChangeNotifier {
  DefaultApi? _client;
  UserWithImagesAndEloAndUuid? _me;
  final List<UserWithImagesAndEloAndUuid> _potentialMatches = [];

  Future<DefaultApi> getClient() async {
    _client ??= await initClient();
    return _client!;
  }

  Future<List<(ChatAndLastMessage, UserWithImagesAndElo)>> getChats() async {
    return await initChats();
  }

  Future<UserWithImagesAndEloAndUuid> getMe() async {
    _me ??= await initMe();
    return _me!;
  }

  Future<UserWithImagesAndEloAndUuid> getPotentialMatch() async {
    if (_potentialMatches.length < 5) {
      _fetchPotentialMatches()
          .then((matches) => _potentialMatches.addAll(matches));
    }
    if (_potentialMatches.isEmpty) {
      var matches = await _fetchPotentialMatches();
      _potentialMatches.addAll(matches);
      return _potentialMatches[0];
    }
    return _potentialMatches[0];
  }

  Future<List<UserWithImagesAndEloAndUuid>> _fetchPotentialMatches() async {
    var client = await getClient();
    var matches = await client
        .getNextUsersPost(_potentialMatches.map((e) => e.uuid).toList());
    if (matches == null) {
      throw Exception('Failed to get matches');
    }

    return matches.toList();
  }

  Future<List<Message>> getMessages(String chatId) async {
    var client = await getClient();
    var messages = await client.getChatMessagesPost(chatId);
    if (messages == null) {
      throw Exception('Failed to get messages');
    }
    return messages;
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

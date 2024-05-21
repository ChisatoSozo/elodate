import 'package:client/api/pkg/lib/api.dart';
import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';

class HomeModel extends ChangeNotifier {
  late DefaultApi _client;
  late ApiUser me;
  final List<ApiUser> _potentialMatches = [];
  late PreferencesConfig preferencesConfig;
  List<ApiChat> chats = [];
  bool isLoaded = false;
  bool isLoading = false;

  Future<void> initAll() async {
    var jwt = localStorage.getItem('jwt');
    if (jwt == null) {
      throw Exception('No JWT found');
    }

    var uuid = localStorage.getItem('uuid');
    if (uuid == null) {
      throw Exception('No UUID found');
    }

    isLoading = true;
    await initClient(jwt);
    await Future.wait([initMe(uuid), initAdditionalPreferences()]);
    await initChats(me);
    isLoaded = true;
    isLoading = false;
    notifyListeners();
  }

  Future<void> initClient(String jwt) async {
    var auth = HttpBearerAuth();
    auth.accessToken = jwt;

    var client = DefaultApi(
        ApiClient(basePath: 'http://localhost:8080', authentication: auth));

    _client = client;
  }

  Future<void> initMe(String myUuid) async {
    var newMe = await _client.getUsersPost([myUuid]);
    if (newMe == null) {
      throw Exception('Failed to get user');
    }
    if (newMe.isEmpty) {
      throw Exception('User not found');
    }
    if (newMe.length > 1) {
      throw Exception('Too many users found');
    }
    me = newMe.first;
  }

  Future<void> initAdditionalPreferences() async {
    var result = await _client.getPreferencesConfigPost(true);
    if (result == null) {
      throw Exception('Failed to get additional preferences');
    }
    preferencesConfig = result;
  }

  Future<void> initChats(ApiUser me) async {
    var result = await _client.getChatsPost(me.chats);

    if (result == null) {
      throw Exception('Failed to get chat messages');
    }
  }

  Future<bool> sendChatMessage(
      String chatUuid, SendMessageInputMessage message) async {
    var result = await _client.sendMessagePost(
        SendMessageInput(chatUuid: chatUuid, message: message));
    if (result == null) {
      throw Exception('Failed to send message');
    }
    return result;
  }

  Future<ApiUser> getPotentialMatch(int index) async {
    if (_potentialMatches.length < 5) {
      _fetchPotentialMatches()
          .then((matches) => _potentialMatches.addAll(matches));
    }
    if (_potentialMatches.isEmpty) {
      var matches = await _fetchPotentialMatches();
      _potentialMatches.addAll(matches);
      return _potentialMatches[index];
    }
    return _potentialMatches[index];
  }

  Future<List<ApiUser>> _fetchPotentialMatches() async {
    var matches = await _client
        .getNextUsersPost(_potentialMatches.map((e) => e.uuid).toList());
    if (matches == null) {
      throw Exception('Failed to get matches');
    }

    return matches.toList();
  }

  Future<List<ApiMessage>> getMessages(
      String chatUuid, List<String> messageUuids) async {
    var messages = await _client.getMessagesPost(
        GetMessagesInput(chatUuid: chatUuid, messages: messageUuids));
    if (messages == null) {
      throw Exception('Failed to get messages');
    }
    return messages;
  }

  Future<int> getNumUsersIPreferDryRun(ApiUser newUser) async {
    var result = await _client.getUsersIPerferCountDryRunPost(newUser);
    if (result == null) {
      throw Exception('Failed to get number of users');
    }
    return result;
  }

  Future<int> getNumUsersMutuallyPreferDryRun(ApiUser user) async {
    var result = await _client.getUsersMutualPerferCountDryRunPost(user);
    if (result == null) {
      throw Exception('Failed to get number of users');
    }
    return result;
  }

  Future<bool> likeUser(ApiUser user) async {
    //pop the user from the potential matches
    _potentialMatches.remove(user);

    var result = await _client.ratePost(RatingWithTarget(
        rating: RatingWithTargetRatingEnum.like, target: user.uuid));
    if (result == null) {
      throw Exception('Failed to like user');
    }
    return result;
  }

  Future<bool> dislikeUser(ApiUser user) async {
    //pop the user from the potential matches
    _potentialMatches.remove(user);

    var result = await _client.ratePost(RatingWithTarget(
        rating: RatingWithTargetRatingEnum.pass, target: user.uuid));
    if (result == null) {
      throw Exception('Failed to dislike user');
    }
    return result;
  }

  Future<void> updateMe(ApiUserWritable user) async {
    var result = await _client.putUserPost(user);
    await initMe(me.uuid);
    if (result == null) {
      throw Exception('Failed to update user');
    }
    notifyListeners();
  }
}

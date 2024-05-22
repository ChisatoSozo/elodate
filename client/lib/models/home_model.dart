import 'package:client/api/pkg/lib/api.dart';
import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';

class HomeModel extends ChangeNotifier {
  late DefaultApi _client;
  late ApiUserMe me;
  final List<ApiUser> _potentialMatches = [];
  late PreferencesConfig preferencesConfig;
  List<(ApiUser, ApiChat)> chats = [];
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
    var newMe = await _client.getMePost(true);
    if (newMe == null) {
      throw Exception('Failed to get me');
    }
    me = newMe;
  }

  Future<void> initAdditionalPreferences() async {
    var result = await _client.getPreferencesConfigPost(true);
    if (result == null) {
      throw Exception('Failed to get additional preferences');
    }
    preferencesConfig = result;
  }

  Future<void> initChats(ApiUserMe me) async {
    var result = await _client.getChatsPost(me.chats);

    if (result == null) {
      throw Exception('Failed to get chat messages');
    }
    var users = await _client.getUsersPost(result
        .map((e) =>
            e.mostRecentSender ??
            e.users.firstWhere((element) => element != me.uuid))
        .toList());

    if (users == null) {
      throw Exception('Failed to get chat users');
    }

    var newChats = [];
    for (var i = 0; i < result.length; i++) {
      newChats.add((users[i], result[i]));
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

  Future<ApiChat> getChat(String chatUuid) async {
    var chat = await _client.getChatsPost([chatUuid]);
    if (chat == null) {
      throw Exception('Failed to get chat');
    }
    if (chat.isEmpty) {
      throw Exception('Chat not found');
    }
    if (chat.length > 1) {
      throw Exception('Too many chats found');
    }
    return chat.first;
  }

  Future<int> getNumUsersIPreferDryRun(ApiUserPreferences prefs) async {
    var result = await _client.getUsersIPerferCountDryRunPost(Preferences(
        age: prefs.age,
        latitude: prefs.latitude,
        longitude: prefs.longitude,
        percentFemale: prefs.percentFemale,
        percentMale: prefs.percentMale,
        additionalPreferences: prefs.additionalPreferences));
    if (result == null) {
      throw Exception('Failed to get number of users');
    }
    return result;
  }

  Future<int> getNumUsersMutuallyPreferDryRun(
      ApiUserProperties props, ApiUserPreferences prefs) async {
    var result = await _client.getUsersMutualPerferCountDryRunPost(
        PropsAndPrefs(preferences: prefs, properties: props));
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

  Future<ApiImage> getImage(String uuid) async {
    var result = await _client.getImagesPost([uuid]);
    if (result == null) {
      throw Exception('Failed to get image');
    }
    if (result.isEmpty) {
      throw Exception('Image not found');
    }
    if (result.length > 1) {
      throw Exception('Too many images found');
    }
    return result.first;
  }
}

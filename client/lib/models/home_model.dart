import 'package:client/api/pkg/lib/api.dart';
import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';

class HomeModel extends ChangeNotifier {
  late DefaultApi _client;
  late UserWithImagesAndEloAndUuid me;
  final List<UserWithImagesAndEloAndUuid> _potentialMatches = [];
  late List<AdditionalPreferencePublic> additionalPreferences;
  List<(Chat, UserWithImagesAndElo)> chats = [];
  bool isLoaded = false;
  bool isLoading = false;

  Future<void> initAll() async {
    isLoading = true;
    await initClient();
    await Future.wait([initMe(), initAdditionalPreferences()]);
    await initChats();
    isLoaded = true;
    isLoading = false;
    notifyListeners();
  }

  Future<void> initClient() async {
    var jwt = localStorage.getItem('jwt');
    if (jwt == null) {
      throw Exception('No JWT found');
    }

    var auth = HttpBearerAuth();
    auth.accessToken = jwt;

    var client = DefaultApi(
        ApiClient(basePath: 'http://localhost:8080', authentication: auth));

    _client = client;
  }

  Future<void> initMe() async {
    var newMe = await _client.getMePost();
    if (newMe == null) {
      throw Exception('Failed to get user');
    }
    me = newMe;
  }

  Future<void> initAdditionalPreferences() async {
    var result = await _client.getAdditionalPreferencesGet();
    if (result == null) {
      throw Exception('Failed to get additional preferences');
    }
    additionalPreferences = result;
  }

  Future<void> initChats() async {
    var result = await _client.getMyChatsPost();

    if (result == null) {
      throw Exception('Failed to get chat messages');
    }

    for (var chat in result) {
      var notMe =
          [chat.user1, chat.user2].firstWhere((element) => element != me.uuid);
      var user = await _client.getUserWithSingleImagePost(notMe);
      if (user == null) {
        throw Exception('Failed to get user');
      }
      chats.add((chat, user));
    }
  }

  Future<String> sendChatMessage(
      String chatUuid, SendMessageInputMessage message) async {
    var result = await _client.sendMessagePost(
        SendMessageInput(chatUuid: chatUuid, message: message));
    if (result == null) {
      throw Exception('Failed to send message');
    }
    return result;
  }

  Future<UserWithImagesAndEloAndUuid> getPotentialMatch(int index) async {
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

  Future<List<UserWithImagesAndEloAndUuid>> _fetchPotentialMatches() async {
    var matches = await _client
        .getNextUsersPost(_potentialMatches.map((e) => e.uuid).toList());
    if (matches == null) {
      throw Exception('Failed to get matches');
    }

    return matches.toList();
  }

  Future<List<Message>> getMessages(String chatId) async {
    var messages = await _client.getChatMessagesPost(chatId);
    if (messages == null) {
      throw Exception('Failed to get messages');
    }
    return messages;
  }

  Future<int> getNumUsersIPreferDryRun(Preference preference) async {
    var result = await _client.getUsersIPerferCountDryRunPost(preference);
    if (result == null) {
      throw Exception('Failed to get number of users');
    }
    return result;
  }

  Future<int> getNumUsersMutuallyPreferDryRun(UserPublicFields user) async {
    var result = await _client.getUsersMutualPerferCountDryRunPost(user);
    if (result == null) {
      throw Exception('Failed to get number of users');
    }
    return result;
  }

  Future<void> likeUser(UserWithImagesAndEloAndUuid user) async {
    //pop the user from the potential matches
    _potentialMatches.remove(user);

    var result = await _client.ratePost(RatingWithTarget(
        rating: RatingWithTargetRatingEnum.like, target: user.uuid));
    if (result == null) {
      throw Exception('Failed to like user');
    }
  }

  Future<void> dislikeUser(UserWithImagesAndEloAndUuid user) async {
    //pop the user from the potential matches
    _potentialMatches.remove(user);

    var result = await _client.ratePost(RatingWithTarget(
        rating: RatingWithTargetRatingEnum.pass, target: user.uuid));
    if (result == null) {
      throw Exception('Failed to dislike user');
    }
  }

  Future<void> updateMe(UserWithImages user) async {
    var result = await _client.updateUserPost(user);
    var newMe = await _client.getMePost();
    if (newMe == null) {
      throw Exception('Failed to get user');
    }
    me = newMe;
    if (result == null) {
      throw Exception('Failed to update user');
    }
    notifyListeners();
  }
}

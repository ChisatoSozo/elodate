



// class HomeModel extends ChangeNotifier {
//   late DefaultApi _client;
//   late ApiUserMe me;
//   final List<ApiUser> _potentialMatches = [];
//   late PreferencesConfig preferenceConfigs;
//   List<(ApiUser, ApiChat)> chats = [];
//   bool isLoaded = false;
//   bool isLoading = false;

//   Future<void> initAll() async {
//     var jwt = localStorage.getItem('jwt');
//     if (jwt == null) {
//       throw Exception('No JWT found');
//     }

//     var uuid = localStorage.getItem('uuid');
//     if (uuid == null) {
//       throw Exception('No UUID found');
//     }

//     isLoading = true;
//     await initClient(jwt);
//     await Future.wait([initMe(), initAdditionalPreferences()]);
//     await initChats(me);
//     isLoaded = true;
//     isLoading = false;
//     notifyListeners();
//   }

//   Future<void> initClient(String jwt) async {
//     _client = constructClient(jwt);
//   }

//   Future<void> initMe() async {
//     _potentialMatches.clear();
//     var newMe = await _client.getMePost(true);
//     if (newMe == null) {
//       throw Exception('Failed to get me');
//     }
//     me = newMe;
//   }

//   Future<void> initAdditionalPreferences() async {
//     var result = await _client.getPreferencesConfigPost(true);
//     if (result == null) {
//       throw Exception('Failed to get additional preferences');
//     }
//     preferenceConfigs = result;
//   }

//   Future<void> initChats(ApiUserMe me) async {
//     var result = await _client.getChatsPost(me.chats);

//     if (result == null) {
//       throw Exception('Failed to get chat messages');
//     }
//     var users = await _client.getUsersPost(result
//         .map((e) => (e.mostRecentSender == null
//             ? e.users.firstWhere((element) => element != me.uuid)
//             : e.mostRecentSender == me.uuid
//                 ? e.users.firstWhere((element) => element != me.uuid)
//                 : e.mostRecentSender)!)
//         .toList());

//     if (users == null) {
//       throw Exception('Failed to get chat users');
//     }

//     List<(ApiUser, ApiChat)> newChats = [];
//     for (var i = 0; i < result.length; i++) {
//       newChats.add((users[i], result[i]));
//     }
//     chats = newChats;
//   }











//   Future<int> getNumUsersIPreferDryRun(ApiUserPreferences prefs) async {
//     var result = await _client.getUsersIPerferCountDryRunPost(Preferences(
//         age: prefs.age,
//         latitude: prefs.latitude,
//         longitude: prefs.longitude,
//         percentFemale: prefs.percentFemale,
//         percentMale: prefs.percentMale,
//         additionalPreferences: prefs.additionalPreferences));
//     if (result == null) {
//       throw Exception('Failed to get number of users');
//     }
//     return result;
//   }

//   Future<int> getNumUsersMutuallyPreferDryRun(
//       ApiUserProperties props, ApiUserPreferences prefs) async {
//     var result = await _client.getUsersMutualPerferCountDryRunPost(
//         PropsAndPrefs(preferences: prefs, properties: props));
//     if (result == null) {
//       throw Exception('Failed to get number of users');
//     }
//     return result;
//   }



//   Future<void> updateMe(ApiUserWritable user) async {
//     var result = await _client.putUserPost(user);
//     await initMe();
//     if (result == null) {
//       throw Exception('Failed to update user');
//     }
//     notifyListeners();
//   }

//   Future<ApiImage> getImage(String uuid) async {
//     var result = await _client.getImagesPost([uuid]);
//     if (result == null) {
//       throw Exception('Failed to get image');
//     }
//     if (result.isEmpty) {
//       throw Exception('Image not found');
//     }
//     if (result.length > 1) {
//       throw Exception('Too many images found');
//     }
//     return result.first;
//   }
// }

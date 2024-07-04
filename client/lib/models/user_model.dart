import 'dart:async';
import 'dart:convert';

import 'package:client/api/pkg/lib/api.dart';
import 'package:client/router/elo_router_nav.dart';
import 'package:client/utils/prefs_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';

//public function to construct client
DefaultApi constructClient(String? jwt) {
  HttpBearerAuth? auth;

  if (jwt != null) {
    auth = HttpBearerAuth();
    auth.accessToken = jwt;
  }

  //if kIsWeb, get host from url
  if (kIsWeb) {
    var host = Uri.base.host;
    var port = Uri.base.port;
    var protocol = Uri.base.scheme;
    if (host == 'localhost' || host.startsWith('192.168.')) {
      port = 8080;
    }
    var client = DefaultApi(
        ApiClient(basePath: '$protocol://$host:$port', authentication: auth));
    return client;
  }

  var client = DefaultApi(
      ApiClient(basePath: 'https://elodate.com', authentication: auth));

  return client;
}

class UserModel extends ChangeNotifier {
  List<PreferenceConfigPublic>? preferenceConfigs;
  late DefaultApi client;
  ApiUser? _me;
  bool isLoading = false;
  bool isLoaded = false;
  int numUsersIPrefer = 0;
  int numUsersMutuallyPrefer = 0;
  bool _changes = false;

  bool get changes => _changes;
  ApiUser get me => _me!;
  bool get loggedIn => _me != null && !isLoading && isLoaded;

  bool _metric = true;
  bool get metric => _metric;
  set metric(bool value) {
    _metric = value;
    notifyListeners();
  }

  bool setChanges(bool value) {
    _changes = value;
    notifyListeners();
    return value;
  }

  bool canLoad() {
    var jwt = localStorage.getItem('jwt');
    var uuid = localStorage.getItem('uuid');
    return jwt != null && uuid != null;
  }

  void clear() {
    preferenceConfigs = null;
    client = DefaultApi(ApiClient());
    _me = null;
    isLoading = false;
    isLoaded = false;
  }

  void logout(BuildContext context) {
    clear();
    localStorage.clear();
    EloNav.goLogin(context);
  }

  Future<UserModel> initAll(BuildContext context) async {
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
    try {
      await initMe();
    } catch (e) {
      //pop all and go to login
      clear();
      if (!context.mounted) {
        rethrow;
      }
      if (EloNav.currentRoute(context) != '/login') {
        EloNav.goLogin(context);
        return this;
      }
      rethrow;
    }
    await initAdditionalPrefs();
    isLoading = false;
    isLoaded = true;
    notifyListeners();
    return this;
  }

  Future<void> initAdditionalPrefs() async {
    var result = await client.getPrefsConfigPost(true);
    if (result == null) {
      throw Exception('Failed to get additional prefs');
    }
    preferenceConfigs = result;
  }

  Future<void> initClient(String jwt) async {
    client = constructClient(jwt);
  }

  Future<void> initMe() async {
    var newMe = await client.getMePost(true);
    if (newMe == null) {
      throw Exception('Failed to get me');
    }
    var birthdate = newMe.birthdate;
    //years old (birthdate is seconds since epoch)
    var age = DateTime.now().year -
        DateTime.fromMillisecondsSinceEpoch(birthdate * 1000).year;
    setPropByName(newMe.props, "age", age);
    _me = newMe;
  }

  Future<void> setProperty(ApiUserPropsInner property, int index) async {
    me.props[index] = property;
    _changes = true;
    notifyListeners();
  }

  Future<void> setPreference(ApiUserPrefsInner preference, int index) async {
    me.prefs[index] = preference;
    _changes = true;
    notifyListeners();
  }

  void setPropertyGroup(
      List<ApiUserPropsInner> props, List<ApiUserPrefsInner> prefs, int index) {
    var propIndex = 0;
    for (var property in props) {
      setProperty(property, index + propIndex);
      propIndex++;
    }

    var prefIndex = 0;
    for (var preference in prefs) {
      setPreference(preference, index + prefIndex);
      prefIndex++;
    }
    notifyListeners();
  }

  (List<ApiUserPropsInner>, List<ApiUserPrefsInner>) getPropertyGroup(
      List<PreferenceConfigPublic> preferenceConfigs) {
    var names = preferenceConfigs.map((e) => e.name);
    var props =
        me.props.where((element) => names.contains(element.name)).toList();
    var prefs =
        me.prefs.where((element) => names.contains(element.name)).toList();
    return (props, prefs);
  }

  Future<String> putImage(Uint8List bytes, List<String>? access) async {
    var b64 = base64Encode(bytes);
    var result = await client
        .putImagePost(PutImageInput(content: b64, access: access ?? []));
    if (result == null) {
      throw Exception('Failed to upload image');
    }
    //remove the first and last characters if they are quotes
    return result.substring(1, result.length - 1);
  }

  Future<ApiImage> getImage(String uuid) async {
    var result = await client.getImagesPost([uuid]);
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

  Future<void> updateMe() async {
    _changes = false;
    notifyListeners();
    var result = await client.putUserPost(ApiUserWritable(
      birthdate: me.birthdate,
      description: me.description,
      displayName: me.displayName,
      username: me.username,
      uuid: me.uuid,
      prefs: me.prefs,
      props: me.props,
      images: me.images,
      previewImage: me.previewImage,
      isBot: false,
    ));

    if (result == null) {
      throw Exception('Failed to update me');
    }

    await initMe();
    notifyListeners();
  }

  Timer? _debounceTimer;

  Future<void> updateUsersPerfered() async {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    _debounceTimer = Timer(const Duration(milliseconds: 300), _executeUpdate);
  }

  Future<void> _executeUpdate() async {
    await getNumUsersIPreferDryRun();
    await getNumUsersMutuallyPreferDryRun();
  }

  Future<void> getNumUsersIPreferDryRun() async {
    var result = await client.getUsersIPerferCountDryRunPost(me.prefs
        .map((p) => LabeledPreferenceRange(name: p.name, range: p.range))
        .toList());
    if (result == null) {
      throw Exception('Failed to get num users I prefer dry run');
    }
    numUsersIPrefer = result;
    notifyListeners();
  }

  Future<void> getNumUsersMutuallyPreferDryRun() async {
    var result = await client.getUsersMutualPerferCountDryRunPost(
        PropsAndPrefs(prefs: me.prefs, props: me.props));
    if (result == null) {
      throw Exception('Failed to get num users mutually prefer dry run');
    }
    numUsersMutuallyPrefer = result;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
    _debounceTimer?.cancel();
  }

  Future<List<ApiNotification>> getNotifications() async {
    var result = await client.fetchNotificationsPost(true);
    if (result == null) {
      throw Exception('Failed to get notifications');
    }
    return result;
  }

  Future<ApiMessage> getMessage(String uuid) async {
    var result = await client.getMessagePost(uuid);
    if (result == null) {
      throw Exception('Failed to get message');
    }
    return result;
  }

  Future<ApiUser> getUser(String uuid) async {
    var result = await client.getUsersPost([uuid]);
    if (result == null) {
      throw Exception('Failed to get user');
    }
    if (result.isEmpty) {
      throw Exception('User not found');
    }
    if (result.length > 1) {
      throw Exception('Too many users found');
    }
    return result.first;
  }
}

import 'dart:async';
import 'dart:convert';

import 'package:client/api/pkg/lib/api.dart';
import 'package:client/router/elo_router_nav.dart';
import 'package:client/utils/prefs_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';

DefaultApi constructClient(String? jwt) {
  HttpBearerAuth? auth;

  if (jwt != null) {
    auth = HttpBearerAuth();
    auth.accessToken = jwt;
  }

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

  String? lastUserLoadedUuid;

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
    var age = DateTime.now().year -
        DateTime.fromMillisecondsSinceEpoch(birthdate * 1000).year;
    setPropByName(newMe.props, "age", age);
    _me = newMe;
  }

  Future<void> setProperty(ApiUserPropsInner property, int index) async {
    if (_me != null) {
      _me!.props[index] = property;
      _changes = true;
      notifyListeners();
    }
  }

  Future<void> setPreference(ApiUserPrefsInner preference, int index) async {
    if (_me != null) {
      _me!.prefs[index] = preference;
      _changes = true;
      notifyListeners();
    }
  }

  void setPropertyGroup(
      List<ApiUserPropsInner> props, List<ApiUserPrefsInner> prefs, int index) {
    if (_me != null) {
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
      updateUsersPerfered();
      notifyListeners();
    }
  }

  (List<ApiUserPropsInner>, List<ApiUserPrefsInner>) getPropertyGroup(
      List<PreferenceConfigPublic> preferenceConfigs) {
    if (_me == null) {
      return ([], []);
    }
    var names = preferenceConfigs.map((e) => e.name);
    var props =
        _me!.props.where((element) => names.contains(element.name)).toList();
    var prefs =
        _me!.prefs.where((element) => names.contains(element.name)).toList();
    return (props, prefs);
  }

  Future<String> putImage(Uint8List bytes, List<String>? access) async {
    var b64 = base64Encode(bytes);
    var result = await client
        .putImagePost(PutImageInput(content: b64, access: access ?? []));
    if (result == null) {
      throw Exception('Failed to upload image');
    }
    return result.replaceAll('"', '');
  }

  Future<ApiImage> getImage(String uuid) async {
    var result = await client.getImagesPost([uuid]);
    if (result == null || result.isEmpty) {
      throw Exception('Failed to get image');
    }
    return result.first;
  }

  Future<void> updateMe() async {
    if (_me == null) {
      throw Exception('User not initialized');
    }
    _changes = false;
    notifyListeners();
    var result = await client.putUserPost(ApiUserWritable(
      birthdate: _me!.birthdate,
      description: _me!.description,
      displayName: _me!.displayName,
      username: _me!.username,
      uuid: _me!.uuid,
      prefs: _me!.prefs,
      props: _me!.props,
      images: _me!.images,
      previewImage: _me!.previewImage,
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
    if (_me == null) return;
    var result = await client.getUsersIPerferCountDryRunPost(_me!.prefs
        .map((p) => LabeledPreferenceRange(name: p.name, range: p.range))
        .toList());
    numUsersIPrefer = result ?? 0;
    notifyListeners();
  }

  Future<void> getNumUsersMutuallyPreferDryRun() async {
    if (_me == null) return;
    var result = await client.getUsersMutualPerferCountDryRunPost(
        PropsAndPrefs(prefs: _me!.prefs, props: _me!.props));
    numUsersMutuallyPrefer = result ?? 0;
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
    if (result == null || result.isEmpty) {
      throw Exception('User not found');
    }
    return result.first;
  }
}

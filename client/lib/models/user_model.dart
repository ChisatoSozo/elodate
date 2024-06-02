import 'dart:convert';

import 'package:client/api/pkg/lib/api.dart';
import 'package:flutter/foundation.dart';
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
    var client = DefaultApi(
        ApiClient(basePath: 'http://$host:8080', authentication: auth));
    return client;
  }

  var client = DefaultApi(
      ApiClient(basePath: 'http://localhost:8080', authentication: auth));

  return client;
}

class UserModel extends ChangeNotifier {
  List<PreferenceConfigPublic>? preferenceConfigs;
  late DefaultApi client;
  late ApiUser me;
  bool isLoading = false;
  bool isLoaded = false;

  bool canLoad() {
    var jwt = localStorage.getItem('jwt');
    var uuid = localStorage.getItem('uuid');
    return jwt != null && uuid != null;
  }

  Future<UserModel> initAll() async {
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
    await Future.wait([initMe(), initAdditionalPrefs()]);
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
    me = newMe;
  }

  Future<void> setProperty(ApiUserPropsInner property, int index) async {
    me.props[index] = property;
    notifyListeners();
  }

  Future<void> setPreference(ApiUserPrefsInner preference, int index) async {
    me.prefs[index] = preference;
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
    var result = await client.putUserPost(ApiUserWritable(
        birthdate: me.birthdate,
        description: me.description,
        displayName: me.displayName,
        username: me.username,
        uuid: me.uuid,
        prefs: me.prefs,
        props: me.props,
        images: me.images));

    if (result == null) {
      throw Exception('Failed to update me');
    }

    result = await client.setPublishedPost(true);

    if (result == null) {
      throw Exception('Failed to publish me');
    }

    await initMe();
    notifyListeners();
  }
}

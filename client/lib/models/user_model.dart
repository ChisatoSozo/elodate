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
    await Future.wait([initMe(), initAdditionalPreferences()]);
    isLoading = false;
    isLoaded = true;
    notifyListeners();
    return this;
  }

  Future<void> initAdditionalPreferences() async {
    var result = await client.getPreferencesConfigPost(true);
    if (result == null) {
      throw Exception('Failed to get additional preferences');
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

  Future<void> setProperty(ApiUserPropertiesInner property, int index) async {
    me.properties[index] = property;
    notifyListeners();
  }

  Future<void> setPreference(
      ApiUserPreferencesInner preference, int index) async {
    me.preferences[index] = preference;
    notifyListeners();
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
}

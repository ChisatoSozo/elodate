import 'dart:convert';
import 'dart:typed_data';

import 'package:client/api/pkg/lib/api.dart';
import 'package:client/models/home_model.dart';
import 'package:client/models/image_model.dart';
import 'package:client/pages/home.dart';
import 'package:client/pages/register_birthdate.dart';
import 'package:client/pages/register_finish.dart';
import 'package:client/pages/register_gender.dart';
import 'package:client/pages/register_images.dart';
import 'package:client/pages/register_location.dart';
import 'package:client/pages/register_name.dart';
import 'package:client/pages/register_password.dart';
import 'package:client/pages/register_start.dart';
import 'package:client/utils/utils.dart';
import 'package:flutter/material.dart';

const pages = [
  RegisterStartPage(),
  RegisterNamePage(),
  RegisterPasswordPage(),
  RegisterBirthdatePage(),
  RegisterLocationPage(),
  RegisterGenderPage(),
  RegisterImagesPage(),
  RegisterFinishPage(),
];

void nextPage(BuildContext context, StatefulWidget page) {
  int currentIndex =
      pages.indexWhere((element) => element.runtimeType == page.runtimeType);
  if (currentIndex != -1 && currentIndex < pages.length - 1) {
    // Move to the next page if not the last page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => pages[currentIndex + 1],
      ),
    );
  } else {
    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        pageBuilder: (context, anim1, anim2) => const HomePage(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
      (route) => false,
    );
  }
}

class RegisterModel extends ChangeNotifier {
  String? _username;
  String? _displayName;
  String? _password;
  double? _percentMale;
  double? _percentFemale;
  double? _lat;
  double? _long;
  DateTime? _birthdate;

  String? get username => _username;
  String? get displayName => _displayName;
  String? get password => _password;
  double? get percentMale => _percentMale;
  double? get percentFemale => _percentFemale;

  double? get lat => _lat;
  double? get long => _long;

  DateTime? get birthdate => _birthdate;

  final List<ImageModel> _images = [];

  void setLocation(double lat, double long) {
    _lat = lat;
    _long = long;
    notifyListeners();
  }

  void setUsername(String username) {
    _username = username;
    notifyListeners();
  }

  void setDisplayName(String displayName) {
    _displayName = displayName;
    notifyListeners();
  }

  void setPassword(String password) {
    _password = password;
    notifyListeners();
  }

  void setGenderPercentages(double percentMale, double percentFemale) {
    _percentMale = percentMale;
    _percentFemale = percentFemale;
    notifyListeners();
  }

  void setImage(Uint8List data, String mimeType, int index) {
    if (_images.length <= index) {
      _images.add(ImageModel(data: data, mimeType: mimeType));
    } else {
      _images[index] = ImageModel(data: data, mimeType: mimeType);
    }

    notifyListeners();
  }

  void setBirthdate(DateTime birthdate) {
    _birthdate = birthdate;
    notifyListeners();
  }

  Future<Jwt?> register() async {
    if (_username == null) {
      throw Exception('Username is required');
    }
    if (_displayName == null) {
      throw Exception('Display name is required');
    }
    if (_password == null) {
      throw Exception('Password is required');
    }
    if (_percentMale == null) {
      throw Exception('Percent male is required');
    }
    if (_percentFemale == null) {
      throw Exception('Percent female is required');
    }
    if (_lat == null) {
      throw Exception('Latitude is required');
    }
    if (_long == null) {
      throw Exception('Longitude is required');
    }
    if (_birthdate == null) {
      throw Exception('Birthdate is required');
    }
    if (_images.isEmpty) {
      throw Exception('Images are required');
    }

    var (lat, long) = encodeLatLongToI16(_lat!, _long!);

    //calc age in years
    var age = DateTime.now().difference(_birthdate!).inDays ~/ 365;

    var input = ApiUserWritable(
        birthdate: _birthdate!.millisecondsSinceEpoch ~/ 1000,
        description: '',
        displayName: _displayName!,
        preferences: ApiUserPreferences(
            age: ApiUserPreferencesAdditionalPreferencesInnerRange(
                max: 120, min: 18),
            latitude: ApiUserPreferencesAdditionalPreferencesInnerRange(
                max: 32767, min: -32768),
            longitude: ApiUserPreferencesAdditionalPreferencesInnerRange(
                max: 32767, min: -32768),
            percentFemale: ApiUserPreferencesAdditionalPreferencesInnerRange(
                max: 100, min: 0),
            percentMale: ApiUserPreferencesAdditionalPreferencesInnerRange(
                max: 100, min: 0),
            additionalPreferences: []),
        properties: ApiUserProperties(
            age: age,
            latitude: lat,
            longitude: long,
            percentFemale: _percentFemale!.toInt(),
            percentMale: _percentMale!.toInt(),
            additionalProperties: []),
        published: false,
        username: _username!,
        password: _password!,
        images: _images
            .map((e) => ApiUserWritableImagesInner(
                b64Content: base64Encode(e.data),
                imageType: mimeToType(e.mimeType)))
            .toList(),
        uuid: '');
    var jwt = constructClient(null).signupPost(input);

    return jwt;
  }

  Future<Jwt> login(String username, String password) async {
    var input = LoginRequest(username: username, password: password);
    var jwt = await constructClient(null).loginPost(input);

    if (jwt == null) {
      throw Exception('Failed to login');
    }

    return jwt;
  }
}

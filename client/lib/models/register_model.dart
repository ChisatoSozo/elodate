import 'dart:convert';
import 'dart:typed_data';

import 'package:client/api/pkg/lib/api.dart';
import 'package:client/models/image_model.dart';
import 'package:client/pages/register_birthdate.dart';
import 'package:client/pages/register_finish.dart';
import 'package:client/pages/register_gender.dart';
import 'package:client/pages/register_images.dart';
import 'package:client/pages/register_location.dart';
import 'package:client/pages/register_password.dart';
import 'package:client/pages/register_start.dart';
import 'package:client/pages/register_username.dart';
import 'package:client/utils.dart';
import 'package:flutter/material.dart';

const pages = [
  RegisterStartPage(),
  RegisterUsernamePage(),
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
    // Optionally handle what happens if it's the last page or not found
    print("No next page available or page not found!");
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

  List<ImageModel> images = [];

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
    if (images.length <= index) {
      images.add(ImageModel(data: data, mimeType: mimeType));
    } else {
      images[index] = ImageModel(data: data, mimeType: mimeType);
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
    if (images.isEmpty) {
      throw Exception('Images are required');
    }

    var input = UserWithImagesAndPassword(
      user: UserWithImagesUser(
        birthdate: _birthdate!.millisecondsSinceEpoch ~/ 1000,
        displayName: _displayName!,
        gender: UserWithImagesUserGender(
            percentFemale: (_percentFemale! * 100).toInt(),
            percentMale: (_percentMale! * 100).toInt()),
        preference: UserWithImagesUserPreference(),
        username: _username!,
        location: UserWithImagesUserLocation(lat: _lat!, long: _long!),
      ),
      password: _password!,
      images: images
          .map((e) => ChatAndLastMessageLastMessageImage(
              b64Content: base64Encode(e.data),
              imageType: mimeToType(e.mimeType)))
          .toList(),
    );
    var jwt = await DefaultApi(ApiClient(basePath: 'http://localhost:8080'))
        .signupPost(input);

    return jwt;
  }

  Future<Jwt?> login(String username, String password) async {
    var input = LoginRequest(username: username, password: password);
    var jwt = await DefaultApi(ApiClient(basePath: 'http://localhost:8080'))
        .loginPost(input);

    return jwt;
  }
}

import 'package:client/api/pkg/lib/api.dart';
import 'package:client/models/user_model.dart';
import 'package:client/pages/register_birthdate.dart';
import 'package:client/pages/register_finish.dart';
import 'package:client/pages/register_name.dart';
import 'package:client/pages/register_password.dart';
import 'package:client/pages/register_start.dart';
import 'package:flutter/material.dart';

const pages = [
  RegisterStartPage(),
  RegisterNamePage(),
  RegisterPasswordPage(),
  RegisterBirthdatePage(),
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
        pageBuilder: (context, anim1, anim2) => Container(),
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
  int? _birthdate;

  String? get username => _username;
  String? get displayName => _displayName;
  String? get password => _password;
  int? get birthdate => _birthdate;

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

  void setBirthdate(int birthdate) {
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
    if (_birthdate == null) {
      throw Exception('Birthdate is required');
    }

    var input = ApiUserWritable(
        birthdate: _birthdate!,
        description: '',
        displayName: '',
        preferences: [],
        properties: [],
        published: false,
        username: _username!,
        password: _password!,
        images: [],
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

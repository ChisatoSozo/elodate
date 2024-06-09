// ignore_for_file: use_build_context_synchronously

import 'package:client/api/pkg/lib/api.dart';
import 'package:client/models/page_state_model.dart';
import 'package:client/models/user_model.dart';
import 'package:client/pages/redir.dart';
import 'package:client/pages/register_birthdate.dart';
import 'package:client/pages/register_finish.dart';
import 'package:client/pages/register_name.dart';
import 'package:client/pages/register_password.dart';
import 'package:client/pages/register_start.dart';
import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';
import 'package:provider/provider.dart';

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
        pageBuilder: (context, anim1, anim2) => const RedirPage(),
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
    if (_username == null || _username!.isEmpty) {
      throw Exception('Username is required');
    }
    if (_displayName == null || _displayName!.isEmpty) {
      throw Exception('Display name is required');
    }
    if (_password == null || _password!.isEmpty) {
      throw Exception('Password is required');
    }
    if (_birthdate == null || _birthdate == 0) {
      throw Exception('Birthdate is required');
    }

    var input = ApiUserWritable(
        birthdate: _birthdate!,
        description: '',
        displayName: _displayName!,
        prefs: [],
        props: [],
        username: _username!,
        password: _password!,
        images: [],
        uuid: '');
    var jwt = constructClient(null).signupPost(input);

    return jwt;
  }

  Future<Jwt> login(
      String username, String password, BuildContext context) async {
    var input = LoginRequest(username: username, password: password);
    var jwt = await constructClient(null).loginPost(input);

    if (jwt == null) {
      throw Exception('Failed to login');
    }

    localStorage.clear();

    if (context.mounted == false) {
      throw Exception('Context is not mounted');
    }

    var userModel = Provider.of<UserModel>(context, listen: false);
    var pageStateModel = Provider.of<PageStateModel>(context, listen: false);

    userModel.clear();
    pageStateModel.clear();

    localStorage.setItem("jwt", jwt.jwt);
    localStorage.setItem("uuid", jwt.uuid);

    return jwt;
  }
}

// ignore_for_file: use_build_context_synchronously

import 'package:client/api/pkg/lib/api.dart';
import 'package:client/models/user_model.dart';
import 'package:client/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';
import 'package:provider/provider.dart';

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

  Future<Jwt?> register(String accessCode) async {
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

    var input = SignupInput(
      user: SignupInputUser(
          birthdate: _birthdate!,
          description: '',
          displayName: _displayName!,
          prefs: [],
          props: [],
          username: _username!,
          password: _password!,
          images: [],
          isBot: false,
          uuid: ''),
      accessCode: accessCode,
    );
    try {
      var jwt = constructClient(null).signupPost(input);
      return jwt;
    } catch (e) {
      throw Exception('Failed to register, $e');
    }
  }

  Future<Jwt> login(
      String username, String password, BuildContext context) async {
    var input = LoginRequest(username: username, password: password);
    try {
      var jwt = await constructClient(null).loginPost(input);

      if (jwt == null) {
        throw Exception('Failed to login');
      }

      localStorage.clear();

      if (context.mounted == false) {
        throw Exception('Context is not mounted');
      }

      var userModel = Provider.of<UserModel>(context, listen: false);

      userModel.clear();

      localStorage.setItem("jwt", jwt.jwt);
      localStorage.setItem("uuid", jwt.uuid);

      return jwt;
    } catch (e) {
      throw Exception('Failed to login, ${formatApiError(e.toString())}');
    }
  }
}

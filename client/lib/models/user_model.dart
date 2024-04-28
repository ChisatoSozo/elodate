import 'package:flutter/material.dart';

class RegisterModel extends ChangeNotifier {
  String? _username;
  String? _displayName;

  String? get username => _username;
  String? get displayName => _displayName;

  void setUsername(String username) {
    _username = username;
    notifyListeners();
  }

  void setDisplayName(String displayName) {
    _displayName = displayName;
    notifyListeners();
  }
}

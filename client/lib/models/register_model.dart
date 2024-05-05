import 'dart:typed_data';

import 'package:client/models/image_model.dart';
import 'package:flutter/material.dart';

class RegisterModel extends ChangeNotifier {
  String? _username;
  String? _displayName;
  String? _password;
  double? _percentMale;
  double? _percentFemale;

  String? get username => _username;
  String? get displayName => _displayName;
  String? get password => _password;
  double? get percentMale => _percentMale;
  double? get percentFemale => _percentFemale;

  List<ImageModel> images = [];

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
}

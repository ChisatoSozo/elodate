import 'package:client/api/pkg/lib/api.dart';
import 'package:client/models/user_model.dart';
import 'package:client/pages/settings_flow.dart';
import 'package:flutter/material.dart';

List<
        (
          PreferenceConfigPublicCategoryEnum,
          List<(String, List<PreferenceConfigPublic>, int)>
        )>
    preferenceConfigsToCategoriesAndGroups(
        List<PreferenceConfigPublic> preferenceConfigs) {
  var categories = <(
    PreferenceConfigPublicCategoryEnum,
    List<(String, List<PreferenceConfigPublic>, int)>
  )>[];
  var index = 0;
  for (var config in preferenceConfigs) {
    var category = categories.firstWhere(
        (element) => element.$1 == config.category,
        orElse: () => (config.category, []));
    if (!categories.contains(category)) {
      categories.add(category);
    }
    var group = category.$2.firstWhere((element) => element.$1 == config.group,
        orElse: () => (config.group, [], index));
    if (!category.$2.contains(group)) {
      category.$2.add(group);
    }
    group.$2.add(config);
    index++;
  }
  return categories;
}

class PageStateModel extends ChangeNotifier {
  int _currentCategoryIndex = 0;
  int _currentGroupIndex = 0;

  int get currentCategoryIndex => _currentCategoryIndex;
  int get currentGroupIndex => _currentGroupIndex;

  late List<
      (
        PreferenceConfigPublicCategoryEnum,
        List<(String, List<PreferenceConfigPublic>, int)>
      )> categories;

  void setPropertyGroup(
      List<ApiUserPropertiesInner> properties,
      List<ApiUserPreferencesInner> preferences,
      int index,
      UserModel userModel) {
    var propIndex = 0;
    for (var property in properties) {
      userModel.setProperty(property, index + propIndex);
      propIndex++;
    }

    var prefIndex = 0;
    for (var preference in preferences) {
      userModel.setPreference(preference, index + prefIndex);
      prefIndex++;
    }
    notifyListeners();
  }

  (List<ApiUserPropertiesInner>, List<ApiUserPreferencesInner>)
      getPropertyGroup(
          List<PreferenceConfigPublic> preferenceConfigs, UserModel userModel) {
    var names = preferenceConfigs.map((e) => e.name);
    var properties = userModel.me.properties
        .where((element) => names.contains(element.name))
        .toList();
    var preferences = userModel.me.preferences
        .where((element) => names.contains(element.name))
        .toList();
    return (properties, preferences);
  }

  void advanceGroup(BuildContext context) {
    if (_currentGroupIndex < categories[currentCategoryIndex].$2.length - 1) {
      _currentGroupIndex++;
    } else if (currentCategoryIndex < categories.length - 1) {
      _currentCategoryIndex++;
      _currentGroupIndex = 0;
    } else {
      print("end");
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SettingsFlowPage(),
      ),
    );
    notifyListeners();
  }

  void revertGroup(BuildContext context) {
    // If we're on the first group of the first category, do nothing
    if (_currentCategoryIndex == 0 && _currentGroupIndex == 0) {
      return;
    }
    if (_currentGroupIndex > 0) {
      _currentGroupIndex--;
    } else if (currentCategoryIndex > 0) {
      _currentCategoryIndex--;
      _currentGroupIndex = categories[currentCategoryIndex].$2.length - 1;
    }
    notifyListeners();
  }

  void initPreferencesCategories(UserModel userModel) {
    categories =
        preferenceConfigsToCategoriesAndGroups(userModel.preferenceConfigs!);
    notifyListeners();
  }

  (String, List<PreferenceConfigPublic>, int) getCurrentGroup() {
    return categories[_currentCategoryIndex].$2[_currentGroupIndex];
  }
}

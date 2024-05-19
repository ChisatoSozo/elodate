import 'package:client/api/pkg/lib/api.dart';
import 'package:client/components/distance_slider.dart';
import 'package:client/components/range_slider.dart';
import 'package:client/utils/preference_utils.dart';
import 'package:flutter/material.dart';

class UserPreferenceForm extends StatefulWidget {
  final UserWithImagesAndEloAndUuid me;
  final List<AdditionalPreferencePublic> additionalPreferences;
  final UserWithImagesUserPreferenceController preferencesController;

  const UserPreferenceForm({
    super.key,
    required this.me,
    required this.additionalPreferences,
    required this.preferencesController,
  });

  @override
  UserPreferenceFormState createState() => UserPreferenceFormState();
}

class UserPreferenceFormState extends State<UserPreferenceForm> {
  static const List<int> presetDistances = [
    1,
    2,
    5,
    10,
    20,
    50,
    100,
    250,
    500,
    25000
  ];

  late List<RangeSliderFormFieldController> _additionalPreferencesControllers;
  late List<void Function(PreferenceAdditionalPreferencesValue)>
      _additionalPreferenceUpdaters;

  List<AdditionalPreferencePublic>? _additionalPreferences = [];
  int _distanceIndex = 5;
  Map<String, bool> _expandedCategories = {};
  bool _basicIsExpanded = true;

  @override
  void initState() {
    super.initState();
    _initializeDistanceIndex();
    _loadAdditionalPreferences();
  }

  void _initializeDistanceIndex() {
    int initialDistance = calculateInitialDistance(widget.me);
    _distanceIndex = findClosestDistanceIndex(initialDistance, presetDistances);
  }

  void _loadAdditionalPreferences() {
    setState(() {
      _additionalPreferences = widget.additionalPreferences;
      _additionalPreferencesControllers = _additionalPreferences!.map((pref) {
        late PreferenceAdditionalPreferencesValue prefProc;

        switch (pref.name) {
          case 'age':
            prefProc = widget.preferencesController.value.age;
            break;
          case 'percent_male':
            prefProc = widget.preferencesController.value.percentMale;
            break;
          case 'percent_female':
            prefProc = widget.preferencesController.value.percentFemale;
            break;
          case 'latitude':
            prefProc = widget.preferencesController.value.latitude;
            break;
          case 'longitude':
            prefProc = widget.preferencesController.value.longitude;
            break;
          default:
            prefProc = widget.preferencesController.value
                    .additionalPreferences[pref.name] ??
                PreferenceAdditionalPreferencesValue(
                  min: pref.min,
                  max: pref.max,
                );
        }

        return RangeSliderFormFieldController(prefProc);
      }).toList();
      _additionalPreferenceUpdaters = _additionalPreferences!.map((pref) {
        return (PreferenceAdditionalPreferencesValue value) {
          _handleAdditionalPreferenceUpdate(pref.name, value);
        };
      }).toList();
      _initializeExpandedCategories();
    });
  }

  void _initializeExpandedCategories() {
    _expandedCategories = {
      for (var pref in widget.additionalPreferences) pref.category: false
    };
  }

  void _closeAllCategories() {
    setState(() {
      _basicIsExpanded = false;
      _expandedCategories = {
        for (var key in _expandedCategories.keys) key: false
      };
    });
  }

  void _toggleCategoryExpansion(String category) {
    setState(() {
      var previousState = _expandedCategories[category]!;
      _closeAllCategories();
      _expandedCategories[category] = !previousState;
    });
  }

  void _toggleBasicExpansion() {
    setState(() {
      var previousState = _basicIsExpanded;
      _closeAllCategories();
      _basicIsExpanded = !previousState;
    });
  }

  void _handleAdditionalPreferenceUpdate(
      String name, PreferenceAdditionalPreferencesValue value) {
    widget.preferencesController.updateAdditionalPreference(name, value);
  }

  @override
  Widget build(BuildContext context) {
    final categorizedPreferences =
        widget.additionalPreferences.skip(5).fold<Map<String, List<int>>>(
      {},
      (map, pref) {
        final index = widget.additionalPreferences.indexOf(pref);
        map.putIfAbsent(pref.category, () => []).add(index);
        return map;
      },
    );

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          children: [
            ExpansionPanelList(
              expansionCallback: (int index, bool isExpanded) {
                if (index == 0) {
                  _toggleBasicExpansion();
                  return;
                }

                final category =
                    categorizedPreferences.keys.elementAt(index - 1);
                _toggleCategoryExpansion(category);
              },
              children: [
                ExpansionPanel(
                  headerBuilder: (BuildContext context, bool isExpanded) {
                    return const ListTile(
                      title: Text('Basic Preferences'),
                    );
                  },
                  body: _basicIsExpanded
                      ? Column(
                          children: [
                            RangeSliderFormField(
                              title: 'Age Range',
                              controller: _additionalPreferencesControllers[0],
                              onUpdate: widget.preferencesController.updateAge,
                              config: widget.additionalPreferences[0],
                            ),
                            DistanceSliderWidget(
                              title: 'Distance Range (km)',
                              distanceIndex: _distanceIndex,
                              presetDistances: presetDistances,
                              onChanged: (index) =>
                                  setState(() => _distanceIndex = index),
                            ),
                            RangeSliderFormField(
                              title: 'Percent Male',
                              controller: _additionalPreferencesControllers[1],
                              onUpdate: widget
                                  .preferencesController.updatePercentMale,
                              config: widget.additionalPreferences[1],
                            ),
                            RangeSliderFormField(
                              title: 'Percent Female',
                              controller: _additionalPreferencesControllers[2],
                              onUpdate: widget
                                  .preferencesController.updatePercentFemale,
                              config: widget.additionalPreferences[2],
                            ),
                          ],
                        )
                      : const Text("loading..."),
                  isExpanded: _basicIsExpanded,
                  canTapOnHeader: true,
                ),
                ...categorizedPreferences.entries.map((entry) {
                  final category = entry.key;
                  final indices = entry.value;

                  return ExpansionPanel(
                    canTapOnHeader: true,
                    headerBuilder: (BuildContext context, bool isExpanded) {
                      return ListTile(
                        title: Text(
                          category[0].toUpperCase() + category.substring(1),
                        ),
                      );
                    },
                    body: _expandedCategories[category]!
                        ? Column(
                            children: indices.map((index) {
                              final pref = widget.additionalPreferences[index];
                              return RangeSliderFormField(
                                title: pref.display,
                                controller:
                                    _additionalPreferencesControllers[index],
                                onUpdate: _additionalPreferenceUpdaters[index],
                                config: pref,
                              );
                            }).toList(),
                          )
                        : const Text("loading..."),
                    isExpanded: _expandedCategories[category]!,
                  );
                })
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class UserWithImagesUserPreferenceController {
  UserPublicFieldsPreference value;
  void Function(UserPublicFieldsPreference) onUpdate;

  UserWithImagesUserPreferenceController(
      {required this.value, required this.onUpdate});

  void updateValue(UserPublicFieldsPreference newValue) {
    value = newValue;
    onUpdate(newValue);
  }

  void updateAge(PreferenceAdditionalPreferencesValue age) {
    value = UserPublicFieldsPreference(
      additionalPreferences: value.additionalPreferences,
      age: age,
      latitude: value.latitude,
      longitude: value.longitude,
      percentFemale: value.percentFemale,
      percentMale: value.percentMale,
    );
    onUpdate(value);
  }

  void updateLatitude(PreferenceAdditionalPreferencesValue latitude) {
    value = UserPublicFieldsPreference(
      additionalPreferences: value.additionalPreferences,
      age: value.age,
      latitude: latitude,
      longitude: value.longitude,
      percentFemale: value.percentFemale,
      percentMale: value.percentMale,
    );
    onUpdate(value);
  }

  void updateLongitude(PreferenceAdditionalPreferencesValue longitude) {
    value = UserPublicFieldsPreference(
      additionalPreferences: value.additionalPreferences,
      age: value.age,
      latitude: value.latitude,
      longitude: longitude,
      percentFemale: value.percentFemale,
      percentMale: value.percentMale,
    );
    onUpdate(value);
  }

  void updatePercentFemale(PreferenceAdditionalPreferencesValue percentFemale) {
    value = UserPublicFieldsPreference(
      additionalPreferences: value.additionalPreferences,
      age: value.age,
      latitude: value.latitude,
      longitude: value.longitude,
      percentFemale: percentFemale,
      percentMale: value.percentMale,
    );
    onUpdate(value);
  }

  void updatePercentMale(PreferenceAdditionalPreferencesValue percentMale) {
    value = UserPublicFieldsPreference(
      additionalPreferences: value.additionalPreferences,
      age: value.age,
      latitude: value.latitude,
      longitude: value.longitude,
      percentFemale: value.percentFemale,
      percentMale: percentMale,
    );
    onUpdate(value);
  }

  void updateAdditionalPreference(
      String name, PreferenceAdditionalPreferencesValue additionalPreference) {
    final updatedPreferences =
        Map<String, PreferenceAdditionalPreferencesValue>.from(
            value.additionalPreferences);
    updatedPreferences[name] = additionalPreference;
    value = UserPublicFieldsPreference(
      additionalPreferences: updatedPreferences,
      age: value.age,
      latitude: value.latitude,
      longitude: value.longitude,
      percentFemale: value.percentFemale,
      percentMale: value.percentMale,
    );
    onUpdate(value);
  }
}

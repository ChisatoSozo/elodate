import 'package:client/api/pkg/lib/api.dart';
import 'package:client/components/distance_slider.dart';
import 'package:client/components/range_slider.dart';
import 'package:client/models/home_model.dart';
import 'package:client/utils/preference_utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UserPreferenceForm extends StatefulWidget {
  final UserWithImagesAndEloAndUuid me;

  const UserPreferenceForm({super.key, required this.me});

  @override
  UserPreferenceFormState createState() => UserPreferenceFormState();
}

class UserPreferenceFormState extends State<UserPreferenceForm> {
  static PreferenceAdditionalPreferencesValue defaultAgeRange =
      PreferenceAdditionalPreferencesValue(max: 120, min: 18);
  static PreferenceAdditionalPreferencesValue defaultPercentRange =
      PreferenceAdditionalPreferencesValue(max: 100, min: 0);
  static const List<int> presetDistances = [1, 2, 5, 10, 20, 50, 100, 250, 500];

  late RangeSliderFormFieldController _ageRangeController;
  late RangeSliderFormFieldController _percentFemaleRangeController;
  late RangeSliderFormFieldController _percentMaleRangeController;
  late List<RangeSliderFormFieldController> _additionalPreferencesControllers;

  List<AdditionalPreferencePublic>? _additionalPreferences = [];
  int _distanceIndex = 5;
  int numUsersIPrefer = 0;
  int numUsersMutuallyPrefer = 0;
  Map<String, bool> _expandedCategories = {};
  bool _basicIsExpanded = true;

  @override
  void initState() {
    super.initState();
    _initializeDistanceIndex();
    _loadAdditionalPreferences();
    _ageRangeController = RangeSliderFormFieldController(defaultAgeRange);
    _percentFemaleRangeController =
        RangeSliderFormFieldController(defaultPercentRange);
    _percentMaleRangeController =
        RangeSliderFormFieldController(defaultPercentRange);
  }

  void _initializeDistanceIndex() {
    int initialDistance = calculateInitialDistance(widget.me);
    _distanceIndex = findClosestDistanceIndex(initialDistance, presetDistances);
  }

  Future<void> _loadAdditionalPreferences() async {
    try {
      final homeModel = Provider.of<HomeModel>(context, listen: false);
      _additionalPreferences = await homeModel.getAdditionalPreferences();
      _additionalPreferencesControllers = _additionalPreferences!.map((pref) {
        return RangeSliderFormFieldController(
            PreferenceAdditionalPreferencesValue(
                min: widget.me.user.preference.additionalPreferences[pref.name]
                        ?.min ??
                    pref.min,
                max: widget.me.user.preference.additionalPreferences[pref.name]
                        ?.max ??
                    pref.max));
      }).toList();
      _initializeExpandedCategories();
      setState(() {});
    } catch (error) {
      print(widget.me.user.preference.additionalPreferences);
      setState(() {
        _additionalPreferences = null;
      });
    }
  }

  void _initializeExpandedCategories() {
    if (_additionalPreferences != null) {
      _expandedCategories = {
        for (var pref in _additionalPreferences!) pref.category: false
      };
    }
  }

  void _closeAllCategories() {
    setState(() {
      _expandedCategories = {
        for (var key in _expandedCategories.keys) key: false
      };
    });
  }

  void _toggleCategoryExpansion(String category) {
    setState(() {
      _closeAllCategories();
      _expandedCategories[category] = !_expandedCategories[category]!;
    });
  }

  void _toggleBasicExpansion() {
    setState(() {
      _closeAllCategories();
      _basicIsExpanded = !_basicIsExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_additionalPreferences == null) {
      return const CircularProgressIndicator();
    } else if (_additionalPreferences!.isEmpty) {
      return const Text('No additional preferences available');
    } else {
      final categorizedPreferences =
          _additionalPreferences!.skip(5).fold<Map<String, List<int>>>(
        {},
        (map, pref) {
          final index = _additionalPreferences!.indexOf(pref);
          map.putIfAbsent(pref.category, () => []).add(index);
          return map;
        },
      );

      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Text('Number of users I prefer: $numUsersIPrefer'),
              Text(
                  'Number of users that mutually prefer: $numUsersMutuallyPrefer'),
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
                    body: Column(
                      children: [
                        RangeSliderFormField(
                          title: 'Age Range',
                          controller: _ageRangeController,
                          config: _additionalPreferences![0],
                        ),
                        DistanceSliderWidget(
                          title: 'Distance Range (km)',
                          distanceIndex: _distanceIndex,
                          presetDistances: presetDistances,
                          onChanged: (index) =>
                              setState(() => _distanceIndex = index),
                        ),
                        RangeSliderFormField(
                          title: 'Percent Female',
                          controller: _percentFemaleRangeController,
                          config: _additionalPreferences![1],
                        ),
                        RangeSliderFormField(
                          title: 'Percent Male',
                          controller: _percentMaleRangeController,
                          config: _additionalPreferences![2],
                        ),
                      ],
                    ),
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
                      body: Column(
                        children: indices.map((index) {
                          final pref = _additionalPreferences![index];
                          return RangeSliderFormField(
                            title: pref.display,
                            controller:
                                _additionalPreferencesControllers[index],
                            config: pref,
                          );
                        }).toList(),
                      ),
                      isExpanded: _expandedCategories[category]!,
                    );
                  })
                ],
              ),
              ElevatedButton(
                onPressed: _savePreferences,
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _savePreferences() async {
    final preference = Preference(
        age: _ageRangeController.value,
        latitude: getLatLngRange(widget.me, presetDistances[_distanceIndex]).$1,
        longitude:
            getLatLngRange(widget.me, presetDistances[_distanceIndex]).$2,
        percentFemale: _percentFemaleRangeController.value,
        percentMale: _percentMaleRangeController.value,
        additionalPreferences: {
          for (int index = 5; index < _additionalPreferences!.length; index++)
            _additionalPreferences![index].name:
                _additionalPreferencesControllers[index].value
        });

    final homeModel = Provider.of<HomeModel>(context, listen: false);
    homeModel
        .getNumUsersIPreferDryRun(preference)
        .then((value) => setState(() => numUsersIPrefer = value));
    homeModel
        .getNumUsersMutuallyPreferDryRun(preference)
        .then((value) => setState(() => numUsersMutuallyPrefer = value));
  }
}

import 'dart:convert';
import 'dart:typed_data';

import 'package:client/api/pkg/lib/api.dart';
import 'package:client/components/gender_picker.dart';
import 'package:client/components/image_grid.dart';
import 'package:client/components/location_getter.dart';
import 'package:client/components/value_slider.dart';
import 'package:client/models/home_model.dart';
import 'package:client/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsPageMe extends StatefulWidget {
  final SettingsPageMeController settingsController;

  const SettingsPageMe({
    super.key,
    required this.settingsController,
  });

  @override
  SettingsPageMeState createState() => SettingsPageMeState();
}

class SettingsPageMeState extends State<SettingsPageMe> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  late TextEditingController _displayNameController;
  late TextEditingController _descriptionController;
  late GenderPickerController _genderController;
  late ImageGridFormFieldController _imageGridController;
  late LocationController _locationController;
  late List<ValueSliderFormFieldController> _additionalPropertiesControllers;
  bool _isProfileExpanded = false;
  bool _isGenderExpanded = false;
  bool _isImagesExpanded = false;
  bool _isLocationExpanded = false;
  Map<String, bool> _expandedCategories = {};

  @override
  void initState() {
    super.initState();

    var me = Provider.of<HomeModel>(context, listen: false).me;

    var (lat, long) =
        decodeLatLongFromI16(me.properties.latitude, me.properties.longitude);

    _locationController = LocationController(
      latitude: lat,
      longitude: long,
    );

    _initializeAdditionalPropertiesControllers();
    _initializeExpandedCategories();
  }

  void _initializeAdditionalPropertiesControllers() {
    var homeModel = Provider.of<HomeModel>(context, listen: false);
    var me = homeModel.me;
    _usernameController = TextEditingController(text: me.username);
    _displayNameController = TextEditingController(text: me.displayName);
    _descriptionController = TextEditingController(text: me.description);
    //TODO: gender is borked, fix the preferences

    _genderController = GenderPickerController(
      percentMale: (me.properties.percentMale as double) / 100,
      percentFemale: (me.properties.percentFemale as double) / 100,
    );
    _imageGridController = ImageGridFormFieldController();
    for (int i = 0; i < me.images.length; i++) {
      Uint8List? imageData = base64Decode(me.images[i].b64Content);
      _imageGridController.updateValue(i, (imageData, "webP"));
    }

    _genderController = GenderPickerController(
        percentMale: (homeModel.me.properties.percentMale as double) / 100,
        percentFemale: (homeModel.me.properties.percentFemale as double) / 100);

    _additionalPropertiesControllers = homeModel.preferencesConfig.additional
        .map((pref) => ValueSliderFormFieldController(homeModel
            .me
            .properties
            .additionalProperties[
                homeModel.preferencesConfig.additional.indexOf(pref)]
            .value))
        .toList();
  }

  void _initializeExpandedCategories() {
    var homeModel = Provider.of<HomeModel>(context, listen: false);
    _expandedCategories = {
      for (var pref in homeModel.preferencesConfig.additional)
        pref.category: false
    };
  }

  void _closeAllCategories() {
    setState(() {
      _expandedCategories = {
        for (var key in _expandedCategories.keys) key: false
      };
      _isGenderExpanded = false;
      _isImagesExpanded = false;
      _isLocationExpanded = false;
      _isProfileExpanded = false;
    });
  }

  void _toggleCategoryExpansion(String category) {
    setState(() {
      var previousProfileExpanded = _isProfileExpanded;
      var previousGenderExpanded = _isGenderExpanded;
      var previousImagesExpanded = _isImagesExpanded;
      var previousLocationExpanded = _isLocationExpanded;
      var previousExpandedCategories = {
        for (var key in _expandedCategories.keys) key: _expandedCategories[key]!
      };
      _closeAllCategories();
      switch (category) {
        case 'Profile':
          _isProfileExpanded = !previousProfileExpanded;
          break;
        case 'Gender':
          _isGenderExpanded = !previousGenderExpanded;
          break;
        case 'Images':
          _isImagesExpanded = !previousImagesExpanded;
          break;
        case 'Location':
          _isLocationExpanded = !previousLocationExpanded;
          break;
        default:
          _expandedCategories[category] =
              !previousExpandedCategories[category]!;
      }
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _displayNameController.dispose();
    _descriptionController.dispose();
    _genderController.dispose();
    _imageGridController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var homeModel = Provider.of<HomeModel>(context);
    final categorizedPreferences =
        homeModel.preferencesConfig.additional.fold<Map<String, List<int>>>(
      {},
      (map, pref) {
        final index = homeModel.preferencesConfig.additional.indexOf(pref);
        map.putIfAbsent(pref.category, () => []).add(index);
        return map;
      },
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          children: <Widget>[
            ExpansionPanelList(
              elevation: 0,
              expandedHeaderPadding: const EdgeInsets.all(0),
              expansionCallback: (int index, bool isExpanded) {
                String category = '';
                switch (index) {
                  case 0:
                    category = 'Profile';
                    break;
                  case 1:
                    category = 'Gender';
                    break;
                  case 2:
                    category = 'Images';
                    break;
                  case 3:
                    category = 'Location';
                    break;
                  default:
                    category = categorizedPreferences.keys.elementAt(index - 4);
                }
                _toggleCategoryExpansion(category);
              },
              children: <ExpansionPanel>[
                ExpansionPanel(
                  canTapOnHeader: true,
                  headerBuilder: (BuildContext context, bool isExpanded) {
                    return const ListTile(
                      title: Text('Profile'),
                    );
                  },
                  body: _isProfileExpanded
                      ? Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: <Widget>[
                              TextFormField(
                                controller: _usernameController,
                                decoration: const InputDecoration(
                                  labelText: 'Username',
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (value) {
                                  widget.settingsController
                                      .updateUsername(value);
                                },
                                onFieldSubmitted: (value) {
                                  widget.settingsController
                                      .updateUsername(value);
                                },
                                validator: (value) => value!.isEmpty
                                    ? 'Username cannot be empty'
                                    : null,
                              ),
                              const SizedBox(height: 16.0),
                              TextFormField(
                                controller: _displayNameController,
                                decoration: const InputDecoration(
                                  labelText: 'Display Name',
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (value) {
                                  widget.settingsController
                                      .updateDisplayName(value);
                                },
                                onFieldSubmitted: (value) {
                                  widget.settingsController
                                      .updateDisplayName(value);
                                },
                                validator: (value) => value!.isEmpty
                                    ? 'Display name cannot be empty'
                                    : null,
                              ),
                              const SizedBox(height: 16.0),
                              TextFormField(
                                controller: _descriptionController,
                                decoration: const InputDecoration(
                                  labelText: 'Description',
                                  border: OutlineInputBorder(),
                                ),
                                maxLines: null,
                                minLines: 1,
                                onChanged: (value) {
                                  widget.settingsController
                                      .updateDescription(value);
                                },
                              )
                            ],
                          ),
                        )
                      : const Text('loading...'),
                  isExpanded: _isProfileExpanded,
                ),
                ExpansionPanel(
                  canTapOnHeader: true,
                  headerBuilder: (BuildContext context, bool isExpanded) {
                    return const ListTile(
                      title: Text('Gender'),
                    );
                  },
                  body: _isGenderExpanded
                      ? Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: GenderPickerFormField(
                            controller: _genderController,
                            onSaved: (genderValues) {
                              if (genderValues == null) {
                                return;
                              }
                              widget.settingsController.updateGender(
                                (genderValues.$1 * 100).toInt(),
                                (genderValues.$2 * 100).toInt(),
                              );
                            },
                            onUpdate: (male, female) {
                              widget.settingsController.updateGender(
                                (male * 100).toInt(),
                                (female * 100).toInt(),
                              );
                            },
                          ),
                        )
                      : const Text('loading...'),
                  isExpanded: _isGenderExpanded,
                ),
                ExpansionPanel(
                  canTapOnHeader: true,
                  headerBuilder: (BuildContext context, bool isExpanded) {
                    return const ListTile(
                      title: Text('Images'),
                    );
                  },
                  body: _isImagesExpanded
                      ? Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ImageGridFormField(
                            controller: _imageGridController,
                            validator: (images) {
                              if (images == null || images.isEmpty) {
                                return 'Please upload at least one image';
                              }
                              if (images.every((element) =>
                                  element.$1 == null && element.$2 == null)) {
                                return 'Please upload at least one image';
                              }
                              return null;
                            },
                          ),
                        )
                      : const Text('loading...'),
                  isExpanded: _isImagesExpanded,
                ),
                ExpansionPanel(
                  canTapOnHeader: true,
                  headerBuilder: (BuildContext context, bool isExpanded) {
                    return const ListTile(
                      title: Text('Location'),
                    );
                  },
                  body: _isLocationExpanded
                      ? Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: LocationPickerFormField(
                            controller: _locationController,
                            onChanged: (location) {
                              if (location == null) {
                                return;
                              }

                              var (lat, long) =
                                  encodeLatLongToI16(location.$1, location.$2);

                              widget.settingsController
                                  .updateLocation(lat, long);
                            },
                            onSaved: (location) {
                              if (location == null) {
                                return;
                              }

                              var (lat, long) =
                                  encodeLatLongToI16(location.$1, location.$2);

                              widget.settingsController
                                  .updateLocation(lat, long);
                            },
                          ),
                        )
                      : const Text('loading...'),
                  isExpanded: _isLocationExpanded,
                ),
                ...categorizedPreferences.keys.map<ExpansionPanel>((category) {
                  final prefs = categorizedPreferences[category]!;
                  return ExpansionPanel(
                    canTapOnHeader: true,
                    headerBuilder: (BuildContext context, bool isExpanded) {
                      return ListTile(
                        title: Text(
                            category[0].toUpperCase() + category.substring(1)),
                      );
                    },
                    body: _expandedCategories[category]!
                        ? Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: prefs.map<Widget>((index) {
                                final pref = homeModel
                                    .preferencesConfig.additional[index];
                                return ValueSliderFormField(
                                  controller:
                                      _additionalPropertiesControllers[index],
                                  onUpdate: (value) {
                                    widget.settingsController
                                        .updateAdditionalProperty(
                                      pref.name,
                                      value,
                                    );
                                  },
                                  title: pref.display,
                                  config: pref,
                                );
                              }).toList(),
                            ),
                          )
                        : const Text('loading...'),
                    isExpanded: _expandedCategories[category] ?? false,
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsPageMeController {
  ApiUserWritable value;
  void Function(ApiUserWritable) onUpdate;

  SettingsPageMeController({required this.value, required this.onUpdate});

  void updateValue(ApiUserWritable newValue) {
    value = newValue;
    onUpdate(newValue);
  }

  void updateUsername(String username) {
    value = ApiUserWritable(
      birthdate: value.birthdate,
      description: value.description,
      displayName: value.displayName,
      preferences: value.preferences,
      properties: value.properties,
      published: value.published,
      username: username,
      uuid: value.uuid,
      images: value.images,
    );
    onUpdate(value);
  }

  void updateDisplayName(String displayName) {
    value = ApiUserWritable(
      birthdate: value.birthdate,
      description: value.description,
      displayName: displayName,
      preferences: value.preferences,
      properties: value.properties,
      published: value.published,
      username: value.username,
      uuid: value.uuid,
      images: value.images,
    );
    onUpdate(value);
  }

  void updateDescription(String description) {
    value = ApiUserWritable(
      birthdate: value.birthdate,
      description: description,
      displayName: value.displayName,
      preferences: value.preferences,
      properties: value.properties,
      published: value.published,
      username: value.username,
      uuid: value.uuid,
      images: value.images,
    );
    onUpdate(value);
  }

  void updateGender(int percentMale, int percentFemale) {
    value = ApiUserWritable(
      birthdate: value.birthdate,
      description: value.description,
      displayName: value.displayName,
      preferences: value.preferences,
      properties: ApiUserProperties(
        age: value.properties.age,
        latitude: value.properties.latitude,
        longitude: value.properties.longitude,
        percentFemale: percentFemale,
        percentMale: percentMale,
        additionalProperties: value.properties.additionalProperties,
      ),
      published: value.published,
      username: value.username,
      uuid: value.uuid,
      images: value.images,
    );
    onUpdate(value);
  }

  void updateImage(int index, Uint8List imageData, String mimeType) {
    value.images[index] = ApiUserWritableImagesInner(
        b64Content: base64Encode(imageData), imageType: mimeToType(mimeType));

    onUpdate(value);
  }

  void updateLocation(int latitude, int longitude) {
    value = ApiUserWritable(
      birthdate: value.birthdate,
      description: value.description,
      displayName: value.displayName,
      preferences: value.preferences,
      properties: ApiUserProperties(
        age: value.properties.age,
        latitude: latitude,
        longitude: longitude,
        percentFemale: value.properties.percentFemale,
        percentMale: value.properties.percentMale,
        additionalProperties: value.properties.additionalProperties,
      ),
      published: value.published,
      username: value.username,
      uuid: value.uuid,
      images: value.images,
    );
    onUpdate(value);
  }

  void updateAdditionalProperty(String name, int prop) {
    var index = value.properties.additionalProperties
        .indexWhere((element) => element.name == name);
    value.properties.additionalProperties[index] =
        ApiUserPropertiesAdditionalPropertiesInner(
      name: name,
      value: prop,
    );

    onUpdate(value);
  }
}

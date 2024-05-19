import 'dart:convert';
import 'dart:typed_data';

import 'package:client/api/pkg/lib/api.dart';
import 'package:client/components/gender_picker.dart';
import 'package:client/components/image_grid.dart';
import 'package:client/components/location_getter.dart';
import 'package:client/components/value_slider.dart';
import 'package:client/utils/utils.dart';
import 'package:flutter/material.dart';

class SettingsPageMe extends StatefulWidget {
  final UserWithImagesAndEloAndUuid me;
  final List<AdditionalPreferencePublic> additionalPreferences;
  final SettingsPageMeController settingsController;

  const SettingsPageMe({
    super.key,
    required this.me,
    required this.additionalPreferences,
    required this.settingsController,
  });

  @override
  SettingsPageMeState createState() => SettingsPageMeState();
}

class SettingsPageMeState extends State<SettingsPageMe> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController usernameController;
  late TextEditingController displayNameController;
  late TextEditingController descriptionController;
  late GenderPickerController genderController;
  late ImageGridFormFieldController imageGridController;
  late LocationController locationController;
  late List<ValueSliderFormFieldController> _additionalPropertiesControllers;
  bool _isProfileExpanded = false;
  bool _isGenderExpanded = false;
  bool _isImagesExpanded = false;
  bool _isLocationExpanded = false;
  Map<String, bool> _expandedCategories = {};

  @override
  void initState() {
    super.initState();

    usernameController = TextEditingController(text: widget.me.user.username);
    displayNameController =
        TextEditingController(text: widget.me.user.displayName);
    descriptionController =
        TextEditingController(text: widget.me.user.description);
    genderController = GenderPickerController(
      percentMale: (widget.me.user.gender.percentMale as double) / 100,
      percentFemale: (widget.me.user.gender.percentFemale as double) / 100,
    );
    imageGridController = ImageGridFormFieldController();
    for (int i = 0; i < widget.me.images.length; i++) {
      Uint8List? imageData = base64Decode(widget.me.images[i].b64Content);
      String? mimeType = widget.me.images[i].imageType.toString();
      imageGridController.updateValue(i, (imageData, mimeType));
    }

    var (lat, long) = decodeLatLongFromI16(
        widget.me.user.location.lat, widget.me.user.location.long);

    locationController = LocationController(
      latitude: lat,
      longitude: long,
    );

    _initializeAdditionalPreferences();
    _initializeExpandedCategories();
  }

  void _initializeAdditionalPreferences() {
    _additionalPropertiesControllers = widget.additionalPreferences.map((pref) {
      return ValueSliderFormFieldController(
          widget.me.user.additionalProperties[pref.name] ?? -32768);
    }).toList();
  }

  void _initializeExpandedCategories() {
    _expandedCategories = {
      for (var pref in widget.additionalPreferences) pref.category: false
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
    usernameController.dispose();
    displayNameController.dispose();
    descriptionController.dispose();
    genderController.dispose();
    imageGridController.dispose();
    locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categorizedPreferences =
        widget.additionalPreferences.fold<Map<String, List<int>>>(
      {},
      (map, pref) {
        final index = widget.additionalPreferences.indexOf(pref);
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
                                controller: usernameController,
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
                                controller: displayNameController,
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
                                controller: descriptionController,
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
                            controller: genderController,
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
                            controller: imageGridController,
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
                            controller: locationController,
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
                                final pref =
                                    widget.additionalPreferences[index];
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
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  // Handle form submission
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsPageMeController {
  UserWithImages value;
  void Function(UserWithImages) onUpdate;

  SettingsPageMeController({required this.value, required this.onUpdate});

  void updateValue(UserWithImages newValue) {
    value = newValue;
    onUpdate(newValue);
  }

  void updateUsername(String username) {
    value = UserWithImages(
      user: UserWithImagesUser(
        username: username,
        displayName: value.user.displayName,
        description: value.user.description,
        gender: value.user.gender,
        location: value.user.location,
        additionalProperties: value.user.additionalProperties,
        birthdate: value.user.birthdate,
        preference: value.user.preference,
      ),
      images: value.images,
    );
    onUpdate(value);
  }

  void updateDisplayName(String displayName) {
    value = UserWithImages(
      user: UserWithImagesUser(
        username: value.user.username,
        displayName: displayName,
        description: value.user.description,
        gender: value.user.gender,
        location: value.user.location,
        additionalProperties: value.user.additionalProperties,
        birthdate: value.user.birthdate,
        preference: value.user.preference,
      ),
      images: value.images,
    );
    onUpdate(value);
  }

  void updateDescription(String description) {
    value = UserWithImages(
      user: UserWithImagesUser(
        username: value.user.username,
        displayName: value.user.displayName,
        description: description,
        gender: value.user.gender,
        location: value.user.location,
        additionalProperties: value.user.additionalProperties,
        birthdate: value.user.birthdate,
        preference: value.user.preference,
      ),
      images: value.images,
    );
    onUpdate(value);
  }

  void updateGender(int percentMale, int percentFemale) {
    value = UserWithImages(
      user: UserWithImagesUser(
        username: value.user.username,
        displayName: value.user.displayName,
        description: value.user.description,
        gender: UserPublicFieldsGender(
            percentMale: percentMale, percentFemale: percentFemale),
        location: value.user.location,
        additionalProperties: value.user.additionalProperties,
        birthdate: value.user.birthdate,
        preference: value.user.preference,
      ),
      images: value.images,
    );
    onUpdate(value);
  }

  void updateImage(int index, Uint8List imageData, String mimeType) {
    final updatedImages = List<MessageImage>.from(value.images);
    updatedImages[index] = MessageImage(
        b64Content: base64Encode(imageData), imageType: mimeToType(mimeType));

    value = UserWithImages(
      user: value.user,
      images: updatedImages,
    );
    onUpdate(value);
  }

  void updateLocation(int latitude, int longitude) {
    value = UserWithImages(
      user: UserWithImagesUser(
        username: value.user.username,
        displayName: value.user.displayName,
        description: value.user.description,
        gender: value.user.gender,
        location: UserPublicFieldsLocation(lat: latitude, long: longitude),
        additionalProperties: value.user.additionalProperties,
        birthdate: value.user.birthdate,
        preference: value.user.preference,
      ),
      images: value.images,
    );
    onUpdate(value);
  }

  void updateAdditionalProperty(String name, int prop) {
    final updatedProperties =
        Map<String, int>.from(value.user.additionalProperties);
    updatedProperties[name] = prop;

    value = UserWithImages(
      user: UserWithImagesUser(
        username: value.user.username,
        displayName: value.user.displayName,
        description: value.user.description,
        gender: value.user.gender,
        location: value.user.location,
        additionalProperties: updatedProperties,
        birthdate: value.user.birthdate,
        preference: value.user.preference,
      ),
      images: value.images,
    );
    onUpdate(value);
  }
}

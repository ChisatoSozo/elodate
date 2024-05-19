import 'dart:convert';
import 'dart:typed_data';

import 'package:client/api/pkg/lib/api.dart';
import 'package:client/components/gender_picker.dart';
import 'package:client/components/image_grid.dart';
import 'package:client/components/location_getter.dart';
import 'package:client/utils/utils.dart';
import 'package:flutter/material.dart';

class SettingsPageMe extends StatefulWidget {
  final UserWithImagesAndEloAndUuid me;

  const SettingsPageMe({
    super.key,
    required this.me,
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
  bool _isProfileExpanded = false;
  bool _isGenderExpanded = false;
  bool _isImagesExpanded = false;
  bool _isLocationExpanded = false;

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
    // Initialize image grid controller with user's images
    for (int i = 0; i < widget.me.images.length; i++) {
      Uint8List? imageData = base64Decode(widget.me.images[i].b64Content);
      String? mimeType = widget.me.images[i].imageType.toString();
      imageGridController.updateValue(i, (imageData, mimeType));
    }

    var (lat, long) = decodeLatLongFromI16(
        widget.me.user.location.lat, widget.me.user.location.long);

    // Initialize location controller
    locationController = LocationController(
      latitude: lat, // Provide initial latitude
      longitude: long, // Provide initial longitude
    );
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
                setState(() {
                  _isProfileExpanded = index == 0 ? isExpanded : false;
                  _isGenderExpanded = index == 1 ? isExpanded : false;
                  _isImagesExpanded = index == 2 ? isExpanded : false;
                  _isLocationExpanded = index == 3 ? isExpanded : false;
                });
              },
              children: <ExpansionPanel>[
                ExpansionPanel(
                  canTapOnHeader: true,
                  headerBuilder: (BuildContext context, bool isExpanded) {
                    return const ListTile(
                      title: Text('Profile'),
                    );
                  },
                  body: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: <Widget>[
                        TextFormField(
                          controller: usernameController,
                          decoration: const InputDecoration(
                            labelText: 'Username',
                            border: OutlineInputBorder(),
                          ),
                          onFieldSubmitted: (value) => {
                            // TODO: autosubmit
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
                          onFieldSubmitted: (value) => {
                            // TODO: autosubmit
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
                          maxLines:
                              null, // Allows the text field to expand vertically
                          minLines: 1, // Starts with a single line
                          onFieldSubmitted: (value) {
                            // TODO: autosubmit
                          },
                        )
                      ],
                    ),
                  ),
                  isExpanded: _isProfileExpanded,
                ),
                ExpansionPanel(
                  canTapOnHeader: true,
                  headerBuilder: (BuildContext context, bool isExpanded) {
                    return const ListTile(
                      title: Text('Gender'),
                    );
                  },
                  body: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: GenderPickerFormField(
                      controller: genderController,
                      onSaved: (genderValues) {
                        // TODO: Handle saving the form data
                      },
                    ),
                  ),
                  isExpanded: _isGenderExpanded,
                ),
                ExpansionPanel(
                  canTapOnHeader: true,
                  headerBuilder: (BuildContext context, bool isExpanded) {
                    return const ListTile(
                      title: Text('Images'),
                    );
                  },
                  body: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ImageGridFormField(
                      controller: imageGridController,
                      validator: (images) {
                        if (images == null) {
                          return 'Please upload at least one image';
                        }
                        if (images.isEmpty) {
                          return 'Please upload at least one image';
                        }
                        if (images.every((element) =>
                            element.$1 == null && element.$2 == null)) {
                          return 'Please upload at least one image';
                        }
                        return null;
                      },
                    ),
                  ),
                  isExpanded: _isImagesExpanded,
                ),
                ExpansionPanel(
                  canTapOnHeader: true,
                  headerBuilder: (BuildContext context, bool isExpanded) {
                    return const ListTile(
                      title: Text('Location'),
                    );
                  },
                  body: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: LocationPickerFormField(
                      controller: locationController,
                      onSaved: (locationValues) {
                        // TODO: Handle saving the form data
                      },
                    ),
                  ),
                  isExpanded: _isLocationExpanded,
                ),
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

import 'dart:async';

import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:client/api/pkg/lib/api.dart';
import 'package:client/models/home_model.dart';
import 'package:client/pages/home_settings_matches.dart';
import 'package:client/pages/home_settings_me.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  SettingsPageState createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  late UserWithImagesUserPreferenceController _preferencesController;
  late SettingsPageMeController _meController;
  bool _hasError = false;
  bool _hasChanges = false; // Track if changes have been made
  final bool _saving = false;

  int _numUsersIPrefer = 0;
  int _numUsersMutuallyPrefer = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    var homeModel = Provider.of<HomeModel>(context, listen: false);
    try {
      setState(() {
        _preferencesController = UserWithImagesUserPreferenceController(
          value: homeModel.me.user.preference,
          onUpdate: (value) {
            setState(() {
              homeModel.me.user.preference = value;
              _hasChanges = true; // Mark changes
              _fetchPreferCounts();
            });
          },
        );
        _meController = SettingsPageMeController(
          value: UserWithImages(
              user: homeModel.me.user, images: homeModel.me.images),
          onUpdate: (value) {
            var homeModel = Provider.of<HomeModel>(context, listen: false);
            setState(() {
              value.user.preference = homeModel.me.user.preference;
              homeModel.me.user = value.user;
              homeModel.me.images = value.images;
              _hasChanges = true; // Mark changes
              _fetchPreferCounts();
            });
          },
        );
        _fetchPreferCounts();
      });
    } catch (error) {
      setState(() {
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return const Center(child: Text("Error loading data"));
    }

    var fit = _numUsersIPrefer == 1 ? "fits" : "fit";
    var prefer = _numUsersMutuallyPrefer == 1 ? "prefers" : "prefer";
    var user = _numUsersIPrefer == 1 ? "user" : "users";

    var homeModel = Provider.of<HomeModel>(context, listen: true);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: homeModel.me.user.published == null ||
                  !homeModel.me.user.published!
              ? const Text("Optional profile set-up")
              : const Text("Settings"),
          automaticallyImplyLeading: false,
          bottom: const TabBar(
            tabs: [
              Tab(text: "Me"),
              Tab(text: "Matches"),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: TabBarView(
                children: [
                  SettingsPageMe(
                    additionalPreferences: homeModel.additionalPreferences,
                    settingsController: _meController,
                  ),
                  UserPreferenceForm(
                    additionalPreferences: homeModel.additionalPreferences,
                    preferencesController: _preferencesController,
                  ),
                ],
              ),
            ),
            Container(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[900]
                  : Colors.white,
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    AnimatedFlipCounter(
                      duration: const Duration(milliseconds: 500),
                      value: _numUsersIPrefer, // pass in a value like 2014
                    ),
                    Text(
                      ' $user $fit your preferences',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                    )
                  ]),
                  Row(children: [
                    AnimatedFlipCounter(
                      duration: const Duration(milliseconds: 500),
                      value:
                          _numUsersMutuallyPrefer, // pass in a value like 2014
                    ),
                    Text(
                      ' also $prefer you',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                    )
                  ]),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _saving
                    ? null
                    : _hasChanges
                        ? _saveChanges
                        : null,
                child: Text(_saving ? "Saving..." : "Save changes"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Timer? _debounce;

  void _fetchPreferCounts() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      if (_hasChanges) {
        await _flagUnpublished();
      }
      if (!mounted) {
        return;
      }
      final homeModel = Provider.of<HomeModel>(context, listen: false);

      final pref = Preference(
        age: homeModel.me.user.preference.age,
        latitude: homeModel.me.user.preference.latitude,
        longitude: homeModel.me.user.preference.longitude,
        percentFemale: homeModel.me.user.preference.percentFemale,
        percentMale: homeModel.me.user.preference.percentMale,
        additionalPreferences:
            homeModel.me.user.preference.additionalPreferences,
      );

      homeModel
          .getNumUsersIPreferDryRun(pref)
          .then((value) => setState(() => _numUsersIPrefer = value));

      homeModel
          .getNumUsersMutuallyPreferDryRun(UserPublicFields(
            birthdate: homeModel.me.user.birthdate,
            description: homeModel.me.user.description,
            displayName: homeModel.me.user.displayName,
            gender: homeModel.me.user.gender,
            preference: homeModel.me.user.preference,
            location: homeModel.me.user.location,
            username: homeModel.me.user.username,
            published: homeModel.me.user.published,
            additionalProperties: homeModel.me.user.additionalProperties,
          ))
          .then((value) => setState(() => _numUsersMutuallyPrefer = value));
    });
  }

  Future<void> _saveChanges() async {
    try {
      final homeModel = Provider.of<HomeModel>(context, listen: false);
      homeModel.me.user.published = true; // Mark as published
      await homeModel.updateMe(
          UserWithImages(user: homeModel.me.user, images: homeModel.me.images));
      _loadData(); // Reload data
      setState(() {
        _hasChanges = false; // Reset change flag
      });
    } catch (error) {
      print(error.toString());
      //TODO: handle error
    }
  }

  Future<void> _flagUnpublished() async {
    try {
      final homeModel = Provider.of<HomeModel>(context, listen: false);
      var unpublishedUser = UserWithImages(
        user: UserWithImagesUser(
          published: false,
          birthdate: homeModel.me.user.birthdate,
          description: homeModel.me.user.description,
          displayName: homeModel.me.user.displayName,
          gender: homeModel.me.user.gender,
          preference: homeModel.me.user.preference,
          location: homeModel.me.user.location,
          username: homeModel.me.user.username,
          additionalProperties: homeModel.me.user.additionalProperties,
        ),
        images: homeModel.me.images,
      );
      await homeModel.updateMe(unpublishedUser);
    } catch (error) {
      print(error.toString());
    }
  }
}

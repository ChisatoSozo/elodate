import 'dart:async';

import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:client/api/pkg/lib/api.dart';
import 'package:client/models/home_model.dart';
import 'package:client/pages/home_settings_matches.dart';
import 'package:client/pages/home_settings_me.dart';
import 'package:client/utils/utils.dart';
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
  String? _error;
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
          value: homeModel.me.preferences,
          onUpdate: (value) {
            setState(() {
              _hasChanges = true; // Mark changes
              _fetchPreferCounts();
            });
          },
        );
        _meController = SettingsPageMeController(
          value: ApiUserWritable(
              birthdate: homeModel.me.birthdate,
              description: homeModel.me.description,
              displayName: homeModel.me.displayName,
              preferences: homeModel.me.preferences,
              properties: homeModel.me.properties,
              published: homeModel.me.published,
              username: homeModel.me.username,
              uuid: homeModel.me.uuid,
              images: homeModel.me.images
                  .map((e) => ApiUserWritableImagesInner(
                      b64Content: e.b64Content,
                      imageType: ApiUserWritableImagesInnerImageTypeEnum.webP))
                  .toList()),
          onUpdate: (value) {
            setState(() {
              _hasChanges = true; // Mark changes
              _fetchPreferCounts();
            });
          },
        );
        _fetchPreferCounts();
      });
    } catch (error) {
      setState(() {
        _error = formatApiError(error.toString());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(child: Text(_error!));
    }

    var fit = _numUsersIPrefer == 1 ? "fits" : "fit";
    var prefer = _numUsersMutuallyPrefer == 1 ? "prefers" : "prefer";
    var user = _numUsersIPrefer == 1 ? "user" : "users";

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: "Me"),
                Tab(text: "Matches"),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  SettingsPageMe(
                    settingsController: _meController,
                  ),
                  UserPreferenceForm(
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

      homeModel
          .getNumUsersIPreferDryRun(_preferencesController.value)
          .then((value) => setState(() => _numUsersIPrefer = value));

      homeModel
          .getNumUsersMutuallyPreferDryRun(
              _meController.value.properties, _preferencesController.value)
          .then((value) => setState(() => _numUsersMutuallyPrefer = value));
    });
  }

  Future<void> _saveChanges() async {
    try {
      final homeModel = Provider.of<HomeModel>(context, listen: false);
      await homeModel.updateMe(ApiUserWritable(
          birthdate: _meController.value.birthdate,
          description: _meController.value.description,
          displayName: _meController.value.displayName,
          preferences: _preferencesController.value,
          properties: _meController.value.properties,
          published: true,
          username: _meController.value.username,
          uuid: homeModel.me.uuid,
          images: homeModel.me.images
              .map((e) => ApiUserWritableImagesInner(
                  b64Content: e.b64Content,
                  imageType: ApiUserWritableImagesInnerImageTypeEnum.webP))
              .toList()));

      _loadData(); // Reload data
      setState(() {
        _hasChanges = false; // Reset change flag
      });
    } catch (error) {
      setState(() {
        _error = formatApiError(error.toString());
      });
    }
  }

  Future<void> _flagUnpublished() async {
    try {
      final homeModel = Provider.of<HomeModel>(context, listen: false);
      var unpublishedUser = ApiUserWritable(
          birthdate: homeModel.me.birthdate,
          description: homeModel.me.description,
          displayName: homeModel.me.displayName,
          preferences: homeModel.me.preferences,
          properties: homeModel.me.properties,
          published: homeModel.me.published,
          username: homeModel.me.username,
          uuid: homeModel.me.uuid,
          images: homeModel.me.images
              .map((e) => ApiUserWritableImagesInner(
                  b64Content: e.b64Content,
                  imageType: ApiUserWritableImagesInnerImageTypeEnum.webP))
              .toList());
      await homeModel.updateMe(unpublishedUser);
    } catch (error) {
      setState(() {
        _error = formatApiError(error.toString());
      });
    }
  }
}

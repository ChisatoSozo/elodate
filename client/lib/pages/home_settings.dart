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
  UserWithImagesAndEloAndUuid? _me;
  List<AdditionalPreferencePublic>? _additionalPreferences;
  UserWithImages? _newMe;
  late UserWithImagesUserPreferenceController _preferencesController;
  late SettingsPageMeController _meController;
  bool _isLoading = true;
  bool _hasError = false;

  int _numUsersIPrefer = 0;
  int _numUsersMutuallyPrefer = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      //todo: unpublish on update
      final homeModel = Provider.of<HomeModel>(context, listen: false);
      final me = await homeModel.getMe();
      final additionalPreferences = await homeModel.getAdditionalPreferences();
      setState(() {
        _me = me;
        _newMe = UserWithImages(user: _me!.user, images: _me!.images);
        _additionalPreferences = additionalPreferences;
        _preferencesController = UserWithImagesUserPreferenceController(
          value: _me!.user.preference,
          onUpdate: (value) {
            setState(() {
              _newMe!.user.preference = value;
              _fetchPreferCounts();
            });
          },
        );
        _meController = SettingsPageMeController(
          value: UserWithImages(user: _me!.user, images: _me!.images),
          onUpdate: (value) {
            setState(() {
              value.user.preference = _newMe!.user.preference;
              _newMe = value;
              _fetchPreferCounts();
            });
          },
        );
        _isLoading = false;
        _fetchPreferCounts();
      });
    } catch (error) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return const Center(child: Text("Error loading data"));
    }

    if (_me == null) {
      return const Center(child: Text("No data available"));
    }

    var fit = _numUsersIPrefer == 1 ? "fits" : "fit";
    var prefer = _numUsersMutuallyPrefer == 1 ? "prefers" : "prefer";
    var user = _numUsersIPrefer == 1 ? "user" : "users";

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: _me!.user.published == null || !_me!.user.published!
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
        body: Stack(
          children: [
            TabBarView(
              children: [
                SettingsPageMe(
                  me: _me!,
                  additionalPreferences: _additionalPreferences!,
                  settingsController: _meController,
                ),
                UserPreferenceForm(
                  me: _me!,
                  additionalPreferences: _additionalPreferences!,
                  preferencesController: _preferencesController,
                ),
              ],
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[900]
                    : Colors.white,
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$_numUsersIPrefer $user $fit your preferences',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                    Text(
                      '$_numUsersMutuallyPrefer also $prefer you',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _fetchPreferCounts() {
    if (_newMe == null) {
      return;
    }
    final homeModel = Provider.of<HomeModel>(context, listen: false);

    final pref = Preference(
        age: _newMe!.user.preference.age,
        latitude: _newMe!.user.preference.latitude,
        longitude: _newMe!.user.preference.longitude,
        percentFemale: _newMe!.user.preference.percentFemale,
        percentMale: _newMe!.user.preference.percentMale,
        additionalPreferences: _newMe!.user.preference.additionalPreferences);
    homeModel
        .getNumUsersIPreferDryRun(pref)
        .then((value) => setState(() => _numUsersIPrefer = value));
    homeModel
        .getNumUsersMutuallyPreferDryRun(UserPublicFields(
          birthdate: _newMe!.user.birthdate,
          description: _newMe!.user.description,
          displayName: _newMe!.user.displayName,
          gender: _newMe!.user.gender,
          preference: _newMe!.user.preference,
          location: _newMe!.user.location,
          username: _newMe!.user.username,
          published: _newMe!.user.published,
          additionalProperties: _newMe!.user.additionalProperties,
        ))
        .then((value) => setState(() => _numUsersMutuallyPrefer = value));
  }
}

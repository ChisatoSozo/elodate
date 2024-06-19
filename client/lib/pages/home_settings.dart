import 'dart:async';
import 'dart:convert';

import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:client/api/pkg/lib/api.dart';
import 'package:client/components/elo_badge.dart';
import 'package:client/components/image_picker.dart';
import 'package:client/components/prop_pref_components/pref.dart';
import 'package:client/components/prop_pref_components/prop.dart';
import 'package:client/models/page_state_model.dart';
import 'package:client/models/user_model.dart';
import 'package:client/pages/login.dart';
import 'package:client/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  SettingsPageState createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  late List<
      (
        PreferenceConfigPublicCategoryEnum,
        List<(String, List<PreferenceConfigPublic>, int)>
      )> categoriesAndGroups;

  late List<bool> _expanded;
  int _usersThatIPrefer = 0;
  int _usersThatAlsoPreferMe = 0;
  String? _error;
  bool _modified = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    var userModel = Provider.of<UserModel>(context, listen: false);
    categoriesAndGroups =
        preferenceConfigsToCategoriesAndGroups(userModel.preferenceConfigs!);
    _expanded = List.filled(categoriesAndGroups.length + 1, false);
    _expanded[0] = true;
    _fetchPreferCounts();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text(
              "See the results of your filters at the bottom of this page",
              style: TextStyle(fontSize: 16),
            ),
            _buildExpansionPanelList(context),
            Card(
              margin: const EdgeInsets.all(16.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildFlipCounters(),
                    if (_error != null) _buildErrorText(context),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () => _logout(context),
                    child: const Text('Logout'),
                  ),
                  ElevatedButton(
                    onPressed: _modified && !_saving ? _saveChanges : null,
                    child: _saving
                        ? const Text('Saving...')
                        : const Text('Save Changes'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildExpansionPanelList(BuildContext context) {
    return ExpansionPanelList(
      expansionCallback: (int index, bool isExpanded) {
        setState(() {
          for (var i = 0; i < _expanded.length; i++) {
            _expanded[i] = false;
          }
          _expanded[index] = isExpanded;
        });
      },
      children: [
        _buildBasicInfoPanel(context),
        ..._buildCategoryPanels(context),
      ],
    );
  }

  ExpansionPanel _buildBasicInfoPanel(BuildContext context) {
    var userModel = Provider.of<UserModel>(context, listen: false);
    return ExpansionPanel(
      canTapOnHeader: true,
      headerBuilder: (BuildContext context, bool isExpanded) {
        return const ListTile(
          title: Text("Basic Info"),
        );
      },
      isExpanded: _expanded[0],
      body: Form(
        key: formKey,
        child: Column(
          children: [
            const SizedBox(height: 20),
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 250,
                    child: Column(children: [
                      _buildTextFormField(
                        initialValue: userModel.me.displayName,
                        labelText: 'Display Name',
                        onChanged: (value) => userModel.me.displayName = value,
                      ),
                      const SizedBox(height: 20),
                      _buildTextFormField(
                        initialValue: userModel.me.description,
                        labelText: 'Description',
                        onChanged: (value) => userModel.me.description = value,
                        maxLines: 10,
                      ),
                    ]),
                  ),
                  SizedBox(
                    width: 100,
                    child: Column(children: [
                      Text('My Elo',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 20),
                      EloBadge(
                          eloLabel: userModel.me.elo, elo: userModel.me.eloNum),
                    ]),
                  ),
                ]),
            const SizedBox(height: 20),
            Text('Images', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 20),
            _buildImagePickerGrid(userModel),
          ],
        ),
      ),
    );
  }

  List<ExpansionPanel> _buildCategoryPanels(BuildContext context) {
    return categoriesAndGroups.map((categoryAndGroup) {
      var categoryIndex = categoriesAndGroups.indexOf(categoryAndGroup) + 1;
      return ExpansionPanel(
        canTapOnHeader: true,
        headerBuilder: (BuildContext context, bool isExpanded) {
          return ListTile(
            title: Text(categoryAndGroup.$1.toString()),
          );
        },
        isExpanded: _expanded[categoryIndex],
        body: _expanded[categoryIndex]
            ? _buildCategoryPanelBody(context, categoryAndGroup)
            : Container(),
      );
    }).toList();
  }

  Widget _buildCategoryPanelBody(
      BuildContext context,
      (
        PreferenceConfigPublicCategoryEnum,
        List<(String, List<PreferenceConfigPublic>, int)>
      ) categoryAndGroup) {
    return Column(
      children: categoryAndGroup.$2.map((group) {
        var (props, prefs) = Provider.of<UserModel>(context, listen: false)
            .getPropertyGroup(group.$2);
        var configs = group.$2;
        var index = group.$3;
        return _buildCategoryGroup(context, configs, props, prefs, index);
      }).toList(),
    );
  }

  Column _buildCategoryGroup(
      BuildContext context,
      List<PreferenceConfigPublic> configs,
      List<ApiUserPropsInner> props,
      List<ApiUserPrefsInner> prefs,
      int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(configs.first.display,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 20),
        if (configs.first.valueQuestion.isNotEmpty) ...[
          Text(configs.first.valueQuestion),
          Prop(
            configs: configs,
            props: props,
            onUpdated: (props) {
              Provider.of<UserModel>(context, listen: false)
                  .setPropertyGroup(props, prefs, index);
              _fetchPreferCounts();
              setState(() {
                _modified = true;
              });
            },
          ),
          const SizedBox(height: 20),
        ],
        Text(configs.first.rangeQuestion),
        Pref(
          configs: configs,
          prefs: prefs,
          onUpdated: (prefs) {
            Provider.of<UserModel>(context, listen: false)
                .setPropertyGroup(props, prefs, index);
            _fetchPreferCounts();
            setState(() {
              _modified = true;
            });
          },
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  TextFormField _buildTextFormField({
    required String initialValue,
    required String labelText,
    required Function(String) onChanged,
    int maxLines = 1,
  }) {
    return TextFormField(
      initialValue: initialValue,
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(),
      ),
      onChanged: (value) {
        setState(() {
          _modified = true;
        });
        onChanged(value);
      },
      maxLines: maxLines,
    );
  }

  GridView _buildImagePickerGrid(UserModel userModel) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 9 / 16,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return AdaptiveFilePicker(
          onUuidChanged: (newUuid) async {
            if (index == 0) {
              //it's a preview image, pull it, resize it,
              var image = await userModel.getImage(newUuid);
              var imageBytes = base64Decode(image.content);
              var newBytes = await makePreview(imageBytes);
              var previewUuid = await userModel.putImage(newBytes, null);
              userModel.me.previewImage = previewUuid;
            }
            if (index < userModel.me.images.length) {
              userModel.me.images[index] = newUuid;
            } else {
              userModel.me.images = [...userModel.me.images, newUuid];
            }
            setState(() {
              _modified = true;
            });
          },
          initialUuid: index < userModel.me.images.length
              ? userModel.me.images[index]
              : null,
        );
      },
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
    );
  }

  Widget _buildErrorText(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Text(
          _error!,
          style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.red) ??
              const TextStyle(color: Colors.red),
        ),
      ],
    );
  }

  Row _buildFlipCounters() {
    var suffixIPrefer = _usersThatIPrefer == 1 ? 'user' : 'users';
    var suffixAlsoPreferMe = _usersThatAlsoPreferMe == 1 ? 'user' : 'users';
    var suffixAlsoPrefers = _usersThatAlsoPreferMe == 1 ? 'prefers' : 'prefer';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AnimatedFlipCounter(
          value: _usersThatIPrefer,
          duration: const Duration(milliseconds: 500),
          suffix: ' $suffixIPrefer after filter',
        ),
        AnimatedFlipCounter(
          value: _usersThatAlsoPreferMe,
          duration: const Duration(milliseconds: 500),
          suffix: ' $suffixAlsoPreferMe also $suffixAlsoPrefers me',
        ),
      ],
    );
  }

  void _logout(BuildContext context) {
    localStorage.removeItem("jwt");
    localStorage.removeItem("uuid");
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  Timer? _debounce;

  void _fetchPreferCounts() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      if (!mounted) return;
      final userModel = Provider.of<UserModel>(context, listen: false);
      userModel
          .getNumUsersIPreferDryRun()
          .then((value) => setState(() => _usersThatIPrefer = value));
      userModel
          .getNumUsersMutuallyPreferDryRun()
          .then((value) => setState(() => _usersThatAlsoPreferMe = value));
    });
  }

  Future<void> _saveChanges() async {
    try {
      final userModel = Provider.of<UserModel>(context, listen: false);
      setState(() {
        _error = null;
        _saving = true;
        _modified = false;
      });
      await userModel.updateMe();
      setState(() {
        _saving = false;
      });
    } catch (error) {
      setState(() => _error = formatApiError(error.toString()));
    }
  }
}

import 'package:client/api/pkg/lib/api.dart';
import 'package:client/components/image_picker.dart';
import 'package:client/components/prop_pref_components/pref.dart';
import 'package:client/components/prop_pref_components/prop.dart';
import 'package:client/models/page_state_model.dart';
import 'package:client/models/user_model.dart';
import 'package:client/pages/login.dart';
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

  @override
  void initState() {
    super.initState();
    var userModel = Provider.of<UserModel>(context, listen: false);
    categoriesAndGroups =
        preferenceConfigsToCategoriesAndGroups(userModel.preferenceConfigs!);
    _expanded = List.filled(categoriesAndGroups.length, false);
    _expanded = [true, ..._expanded];
  }

  @override
  Widget build(BuildContext context) {
    var userModel = Provider.of<UserModel>(context, listen: false);
    return Column(
      children: [
        ExpansionPanelList(
          expansionCallback: (int index, bool isExpanded) {
            setState(() {
              for (var i = 0; i < _expanded.length; i++) {
                _expanded[i] = false;
              }
              _expanded[index] = isExpanded;
            });
          },
          children: [
            ExpansionPanel(
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
                    TextFormField(
                      initialValue: userModel.me.displayName,
                      decoration: const InputDecoration(
                          labelText: 'Display Name',
                          border: OutlineInputBorder()),
                      onChanged: (value) {
                        userModel.me.displayName = value;
                      },
                    ),
                    //spacer
                    const SizedBox(height: 20),
                    TextFormField(
                      initialValue: userModel.me.description,
                      decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder()),
                      onChanged: (value) {
                        userModel.me.description = value;
                      },
                      maxLines: 10,
                    ),
                    //spacer
                    const SizedBox(height: 20),
                    Text(
                      'Images',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 9 / 16,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                      ),
                      itemCount: 6,
                      itemBuilder: (context, index) {
                        return AdaptiveFilePicker(
                          onUuidChanged: (newUuid) {
                            if (index < userModel.me.images.length) {
                              userModel.me.images[index] = newUuid;
                            } else {
                              userModel.me.images = [
                                ...userModel.me.images,
                                newUuid,
                              ];
                            }
                          },
                          initialUuid: index < userModel.me.images.length
                              ? userModel.me.images[index]
                              : null,
                        );
                      },
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                    ),
                  ],
                ),
              ),
            ),
            ...categoriesAndGroups.map(
              (categoryAndGroup) {
                var categoryIndex =
                    categoriesAndGroups.indexOf(categoryAndGroup) + 1;
                return ExpansionPanel(
                  canTapOnHeader: true,
                  headerBuilder: (BuildContext context, bool isExpanded) {
                    return ListTile(
                      title: Text(categoryAndGroup.$1.toString()),
                    );
                  },
                  isExpanded: _expanded[categoryIndex],
                  body: _expanded[categoryIndex]
                      ? FutureBuilder(
                          future: Future.delayed(
                              const Duration(milliseconds: 0), () {
                            return categoryAndGroup;
                          }),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            } else if (snapshot.hasError) {
                              return Center(
                                  child: Text('Error: ${snapshot.error}'));
                            } else {
                              var categoryData = snapshot.data!;
                              return Column(
                                children: categoryData.$2.map((group) {
                                  var (props, prefs) =
                                      userModel.getPropertyGroup(group.$2);
                                  var configs = group.$2;
                                  var index = group.$3;
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        configs.first.display,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                      const SizedBox(height: 20),
                                      if (configs
                                          .first.valueQuestion.isNotEmpty) ...[
                                        Text(
                                          configs.first.valueQuestion,
                                        ),
                                        Prop(
                                          configs: configs,
                                          props: props,
                                          onUpdated: (props) {
                                            userModel.setPropertyGroup(
                                                props, prefs, index);
                                          },
                                        ),
                                        const SizedBox(height: 20),
                                      ],
                                      Text(
                                        configs.first.rangeQuestion,
                                      ),
                                      Pref(
                                        configs: configs,
                                        prefs: prefs,
                                        onUpdated: (prefs) {
                                          userModel.setPropertyGroup(
                                              props, prefs, index);
                                        },
                                      ),
                                      const SizedBox(height: 40),
                                    ],
                                  );
                                }).toList(),
                              );
                            }
                          },
                        )
                      : Container(),
                );
              },
            ),
            // Logout button
          ],
        ),
        ElevatedButton(
          onPressed: () {
            _logout(context);
          },
          child: const Text('Logout'),
        ),
      ],
    );
  }

  void _logout(BuildContext context) {
    localStorage.removeItem("jwt");
    localStorage.removeItem("uuid");
    //remove all page history and push login page
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  // Timer? _debounce;

  // void _fetchPreferCounts() {
  //   if (_debounce?.isActive ?? false) _debounce!.cancel();
  //   _debounce = Timer(const Duration(milliseconds: 300), () async {
  //     if (_hasChanges) {
  //       await _flagUnpublished();
  //     }
  //     if (!mounted) {
  //       return;
  //     }
  //     final homeModel = Provider.of<HomeModel>(context, listen: false);

  //     homeModel
  //         .getNumUsersIPreferDryRun(_prefsController.value)
  //         .then((value) => setState(() => _numUsersIPrefer = value));

  //     homeModel
  //         .getNumUsersMutuallyPreferDryRun(
  //             _meController.value.props, _prefsController.value)
  //         .then((value) => setState(() => _numUsersMutuallyPrefer = value));
  //   });
  // }

  // Future<void> _saveChanges() async {
  //   try {
  //     final homeModel = Provider.of<HomeModel>(context, listen: false);
  //     await homeModel.updateMe(ApiUserWritable(
  //         birthdate: _meController.value.birthdate,
  //         description: _meController.value.description,
  //         displayName: _meController.value.displayName,
  //         prefs: _prefsController.value,
  //         props: _meController.value.props,
  //         published: true,
  //         username: _meController.value.username,
  //         uuid: homeModel.me.uuid,
  //         images: homeModel.me.images
  //             .map((e) => ApiUserWritableImagesInner(
  //                 b64Content: e.b64Content,
  //                 imageType: ApiUserWritableImagesInnerImageTypeEnum.webP))
  //             .toList()));

  //     _loadData(); // Reload data
  //     setState(() {
  //       _hasChanges = false; // Reset change flag
  //     });
  //   } catch (error) {
  //     setState(() {
  //       _error = formatApiError(error.toString());
  //     });
  //   }
  // }

  // Future<void> _flagUnpublished() async {
  //   try {
  //     final homeModel = Provider.of<HomeModel>(context, listen: false);
  //     var unpublishedUser = ApiUserWritable(
  //         birthdate: homeModel.me.birthdate,
  //         description: homeModel.me.description,
  //         displayName: homeModel.me.displayName,
  //         prefs: homeModel.me.prefs,
  //         props: homeModel.me.props,
  //         published: homeModel.me.published,
  //         username: homeModel.me.username,
  //         uuid: homeModel.me.uuid,
  //         images: homeModel.me.images
  //             .map((e) => ApiUserWritableImagesInner(
  //                 b64Content: e.b64Content,
  //                 imageType: ApiUserWritableImagesInnerImageTypeEnum.webP))
  //             .toList());
  //     await homeModel.updateMe(unpublishedUser);
  //   } catch (error) {
  //     setState(() {
  //       _error = formatApiError(error.toString());
  //     });
  //   }
  // }
}

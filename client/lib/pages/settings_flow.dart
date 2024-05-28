import 'package:client/api/pkg/lib/api.dart';
import 'package:client/components/prop_pref_components/gender_prop_pref.dart';
import 'package:client/components/prop_pref_components/location_prop_pref.dart';
import 'package:client/components/prop_pref_components/slider_prop_pref.dart';
import 'package:client/components/responsive_scaffold.dart';
import 'package:client/models/page_state_model.dart';
import 'package:client/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsFlowPage extends StatefulWidget {
  const SettingsFlowPage({super.key});

  @override
  SettingsFlowPageState createState() => SettingsFlowPageState();
}

class SettingsFlowPageState extends State<SettingsFlowPage> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final FocusNode _buttonFocusNode = FocusNode();
  bool loaded = false;

  @override
  void initState() {
    super.initState();
    var userModel = Provider.of<UserModel>(context, listen: false);
    var pageStateModel = Provider.of<PageStateModel>(context, listen: false);
    _buttonFocusNode.requestFocus();

    if (!userModel.isLoading && !userModel.isLoaded) {
      userModel.initAll().then(
        (userModel) {
          setState(
            () {
              loaded = true;
              pageStateModel.initPreferencesCategories(userModel);
            },
          );
        },
      );
    } else {
      setState(() {
        loaded = true;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!loaded) {
      return const CircularProgressIndicator();
    }

    var pageStateModel = Provider.of<PageStateModel>(context, listen: false);
    var userModel = Provider.of<UserModel>(context, listen: false);

    var (_, configs, index) = pageStateModel.getCurrentGroup();
    var (props, prefs) = pageStateModel.getPropertyGroup(configs, userModel);

    return PopScope(
      onPopInvoked: (_) => pageStateModel.revertGroup(context),
      child: ResponsiveScaffold(
        title: configs.first.category.toString(),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              if (configs.first.valueQuestion.isNotEmpty) ...[
                Text(
                  configs.first.valueQuestion,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                if (configs.first.uiElement ==
                    PreferenceConfigPublicUiElementEnum.slider)
                  PropSlider(
                    key: Key(configs.first.group),
                    properties: props,
                    preferenceConfigs: configs,
                    onUpdated: (props) {
                      pageStateModel.setPropertyGroup(
                          props, prefs, index, userModel);
                    },
                  ),
                if (configs.first.uiElement ==
                    PreferenceConfigPublicUiElementEnum.genderPicker)
                  GenderPicker(
                      key: Key(configs.first.group),
                      properties: props,
                      preferenceConfigs: configs,
                      onUpdated: (props) {
                        pageStateModel.setPropertyGroup(
                            props, prefs, index, userModel);
                      }),
                if (configs.first.uiElement ==
                    PreferenceConfigPublicUiElementEnum.locationPicker)
                  LocationPicker(
                      key: Key(configs.first.group),
                      properties: props,
                      preferenceConfigs: configs,
                      onUpdated: (props) {
                        pageStateModel.setPropertyGroup(
                            props, prefs, index, userModel);
                      }),
                const SizedBox(height: 40),
              ],
              Text(
                configs.first.rangeQuestion,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              if (configs.first.uiElement ==
                  PreferenceConfigPublicUiElementEnum.slider)
                PrefSlider(
                  key: Key("${configs.first.group}pref"),
                  preferences: prefs,
                  preferenceConfigs: configs,
                  onUpdated: (prefs) {
                    pageStateModel.setPropertyGroup(
                        props, prefs, index, userModel);
                  },
                ),
              if (configs.first.uiElement ==
                  PreferenceConfigPublicUiElementEnum.genderPicker)
                GenderRangePicker(
                    key: Key("${configs.first.group}pref"),
                    preferences: prefs,
                    preferenceConfigs: configs,
                    onUpdated: (prefs) {
                      pageStateModel.setPropertyGroup(
                          props, prefs, index, userModel);
                    }),
              if (configs.first.uiElement ==
                  PreferenceConfigPublicUiElementEnum.locationPicker)
                LocationRangePicker(
                    key: Key("${configs.first.group}pref"),
                    preferences: prefs,
                    preferenceConfigs: configs,
                    onUpdated: (prefs) {
                      pageStateModel.setPropertyGroup(
                          props, prefs, index, userModel);
                    }),
              //next button
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  pageStateModel.advanceGroup(context);
                },
                focusNode: _buttonFocusNode,
                child: const Text('Next'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

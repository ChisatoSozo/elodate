import 'package:client/api/pkg/lib/api.dart';
import 'package:client/components/settings/prop_pref_components/gender_prop_pref.dart';
import 'package:client/components/settings/prop_pref_components/location_prop_pref.dart';
import 'package:client/components/settings/prop_pref_components/slider_prop_pref.dart';
import 'package:flutter/material.dart';

class Pref extends StatefulWidget {
  final List<PreferenceConfigPublic> configs;
  final List<ApiUserPrefsInner> prefs;
  final Function(List<ApiUserPrefsInner>) onUpdated;

  const Pref({
    required this.configs,
    required this.prefs,
    required this.onUpdated,
    super.key,
  });

  @override
  PrefState createState() => PrefState();
}

class PrefState extends State<Pref> {
  @override
  Widget build(BuildContext context) {
    if (widget.configs.first.uiElement ==
        PreferenceConfigPublicUiElementEnum.slider) {
      return PrefSlider(
        key: ValueKey(widget.configs.first.group),
        prefs: widget.prefs,
        preferenceConfigs: widget.configs,
        onUpdated: widget.onUpdated,
      );
    }

    if (widget.configs.first.uiElement ==
        PreferenceConfigPublicUiElementEnum.genderPicker) {
      return GenderRangePicker(
          key: ValueKey(widget.configs.first.group),
          prefs: widget.prefs,
          preferenceConfigs: widget.configs,
          onUpdated: widget.onUpdated);
    }
    if (widget.configs.first.uiElement ==
        PreferenceConfigPublicUiElementEnum.locationPicker) {
      return LocationRangePicker(
          key: ValueKey(widget.configs.first.group),
          prefs: widget.prefs,
          preferenceConfigs: widget.configs,
          onUpdated: widget.onUpdated);
    }
    throw Exception(
        'Unsupported UI element: ${widget.configs.first.uiElement}');
  }
}

import 'package:client/api/pkg/lib/api.dart';
import 'package:client/components/prop_pref_components/gender_prop_pref.dart';
import 'package:client/components/prop_pref_components/location_prop_pref.dart';
import 'package:client/components/prop_pref_components/slider_prop_pref.dart';
import 'package:flutter/material.dart';

class Prop extends StatefulWidget {
  final List<PreferenceConfigPublic> configs;
  final List<ApiUserPropsInner> props;
  final Function(List<ApiUserPropsInner>) onUpdated;

  const Prop({
    required this.configs,
    required this.props,
    required this.onUpdated,
    super.key,
  });

  @override
  PropState createState() => PropState();
}

class PropState extends State<Prop> {
  @override
  Widget build(BuildContext context) {
    if (widget.configs.first.uiElement ==
        PreferenceConfigPublicUiElementEnum.slider) {
      return PropSlider(
        key: Key(widget.configs.first.group),
        props: widget.props,
        preferenceConfigs: widget.configs,
        onUpdated: widget.onUpdated,
      );
    }

    if (widget.configs.first.uiElement ==
        PreferenceConfigPublicUiElementEnum.genderPicker) {
      return GenderPicker(
          key: Key(widget.configs.first.group),
          props: widget.props,
          preferenceConfigs: widget.configs,
          onUpdated: widget.onUpdated);
    }
    if (widget.configs.first.uiElement ==
        PreferenceConfigPublicUiElementEnum.locationPicker) {
      return LocationPicker(
          key: Key(widget.configs.first.group),
          props: widget.props,
          preferenceConfigs: widget.configs,
          onUpdated: widget.onUpdated);
    }
    throw Exception(
        'Unsupported UI element: ${widget.configs.first.uiElement}');
  }
}

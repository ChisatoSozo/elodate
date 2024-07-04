import 'package:client/api/pkg/lib/api.dart';
import 'package:client/models/user_model.dart';
import 'package:client/pages/home/settings/labeled_checkbox.dart';
import 'package:client/pages/home/settings/prop_pref_components/gender_prop_pref.dart';
import 'package:client/pages/home/settings/prop_pref_components/location_prop_pref.dart';
import 'package:client/pages/home/settings/prop_pref_components/slider_prop_pref.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
        key: ValueKey(widget.configs.first.group),
        props: widget.props,
        preferenceConfigs: widget.configs,
        onUpdated: widget.onUpdated,
      );
    }

    if (widget.configs.first.uiElement ==
        PreferenceConfigPublicUiElementEnum.genderPicker) {
      return GenderPicker(
          key: ValueKey(widget.configs.first.group),
          props: widget.props,
          preferenceConfigs: widget.configs,
          onUpdated: widget.onUpdated);
    }
    if (widget.configs.first.uiElement ==
        PreferenceConfigPublicUiElementEnum.locationPicker) {
      return LocationPicker(
          key: ValueKey(widget.configs.first.group),
          props: widget.props,
          preferenceConfigs: widget.configs,
          onUpdated: widget.onUpdated);
    }
    if (widget.configs.first.uiElement ==
        PreferenceConfigPublicUiElementEnum.heightAndWeight) {
      //check that widget.props.length == 2
      if (widget.props.length != 2) {
        return Text('Invalid props length: ${widget.props.length}');
      }
      var heightProp = widget.props.first;
      var weightProp = widget.props.last;

      var heightConfig = PreferenceConfigPublic(
          group: widget.configs.first.group,
          min: widget.configs.first.min,
          max: widget.configs.first.max,
          labels: widget.configs.first.labels,
          uiElement: PreferenceConfigPublicUiElementEnum.slider,
          category: PreferenceConfigPublicCategoryEnum.physical,
          display: '',
          name: '',
          rangeQuestion: '',
          valueQuestion: '');
      var weightConfig = PreferenceConfigPublic(
          group: widget.configs.last.group,
          min: widget.configs.last.min,
          max: widget.configs.last.max,
          labels: widget.configs.last.labels,
          uiElement: PreferenceConfigPublicUiElementEnum.slider,
          category: PreferenceConfigPublicCategoryEnum.physical,
          display: '',
          name: '',
          rangeQuestion: '',
          valueQuestion: '');

      var userModel = Provider.of<UserModel>(context, listen: true);
      var isMetric = userModel.metric;
      List<String> heightLabels = [];
      List<String> weightLabels = [];

      var heightIsUnset = heightProp.value == -32768;
      var defaultHeight = isMetric ? 170 : 67;

      if (isMetric) {
        for (var cm = heightConfig.min; cm <= heightConfig.max; cm++) {
          heightLabels.add('$cm cm');
        }
        for (var bmi = weightConfig.min; bmi <= weightConfig.max; bmi++) {
          var heightCm = heightIsUnset ? defaultHeight : heightProp.value;
          var heightM = heightCm / 100;
          //bmi = kg / m^2
          var kg = bmi * heightM * heightM;
          weightLabels.add('${kg.round()} kg');
        }
      } else {
        for (var cm = heightConfig.min; cm <= heightConfig.max; cm++) {
          var inches = cm.toDouble() / 2.54;
          var nearestInch = inches.round();
          var feet = nearestInch ~/ 12;
          var inch = nearestInch % 12;
          heightLabels.add('$feet ft $inch in');
        }
        for (var bmi = weightConfig.min; bmi <= weightConfig.max; bmi++) {
          var heightCm = heightIsUnset ? defaultHeight : heightProp.value;
          var heightInches = heightCm / 2.54;
          //bmi = lb / in^2 * 703
          var lb = bmi * heightInches * heightInches / 703;
          weightLabels.add('${lb.round()} lb');
        }
      }

      heightConfig.labels = heightLabels;
      weightConfig.labels = weightLabels;

      return Column(
        children: [
          LabeledCheckbox(
            checked: isMetric,
            onChanged: (metric) => userModel.metric = metric!,
            labelOnRight: false,
            alignRight: true,
            label: "Metric",
          ),
          PropSlider(
            key: ValueKey('${widget.configs.first.group}height$isMetric'),
            props: [heightProp],
            preferenceConfigs: [heightConfig],
            onUpdated: widget.onUpdated,
          ),
          PropSlider(
            key: ValueKey(
                '${widget.configs.last.group}weight$isMetric${heightProp.value}'),
            props: [weightProp],
            preferenceConfigs: [weightConfig],
            onUpdated: widget.onUpdated,
          ),
        ],
      );
    }
    throw Exception(
        'Unsupported UI element: ${widget.configs.first.uiElement}');
  }
}

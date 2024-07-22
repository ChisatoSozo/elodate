import 'package:client/api/pkg/lib/api.dart';
import 'package:client/components/spacer.dart';
import 'package:client/models/user_model.dart';
import 'package:client/pages/home/settings/prop_pref_components/gender_prop_pref.dart';
import 'package:client/pages/home/settings/prop_pref_components/location_prop_pref.dart';
import 'package:client/pages/home/settings/prop_pref_components/number_prop_pref.dart';
import 'package:client/pages/home/settings/prop_pref_components/slider_prop_pref.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

    if (widget.configs.first.uiElement ==
        PreferenceConfigPublicUiElementEnum.numberInput) {
      return PrefNumericalInput(
        key: ValueKey(widget.configs.first.group),
        prefs: widget.prefs,
        preferenceConfigs: widget.configs,
        onUpdated: widget.onUpdated,
      );
    }

    if (widget.configs.first.uiElement ==
        PreferenceConfigPublicUiElementEnum.heightAndWeight) {
      var heightPref = widget.prefs.first;
      var weightPref = widget.prefs.last;

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

      if (isMetric) {
        for (var cm = heightConfig.min; cm <= heightConfig.max; cm++) {
          heightLabels.add('$cm cm');
        }
        for (var bmi = weightConfig.min; bmi <= weightConfig.max; bmi++) {
          var bmiClass = '';
          if (bmi < 18.5) {
            bmiClass = 'Underweight';
          } else if (bmi < 24.9) {
            bmiClass = 'Average';
          } else if (bmi < 29.9) {
            bmiClass = 'Chubby';
          } else if (bmi < 34.9) {
            bmiClass = '"Big"';
          } else if (bmi < 39.9) {
            bmiClass = '"Husky"';
          } else if (bmi < 44.9) {
            bmiClass = '"Fluffy"';
          } else {
            bmiClass = '"Damn"';
          }
          weightLabels.add('$bmi bmi ($bmiClass)');
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
          var bmiClass = '';
          if (bmi < 18.5) {
            bmiClass = 'Underweight';
          } else if (bmi < 24.9) {
            bmiClass = 'Average';
          } else if (bmi < 29.9) {
            bmiClass = 'Chubby';
          } else if (bmi < 34.9) {
            bmiClass = '"Big"';
          } else if (bmi < 39.9) {
            bmiClass = '"Husky"';
          } else if (bmi < 44.9) {
            bmiClass = '"Fluffy"';
          } else {
            bmiClass = '"Damn"';
          }
          weightLabels.add('$bmi bmi ($bmiClass)');
        }
      }

      heightConfig.labels = heightLabels;
      weightConfig.labels = weightLabels;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const VerticalSpacer(size: SpacerSize.large),
          Text(
            'Height',
            style: Theme.of(context).textTheme.labelMedium,
            textAlign: TextAlign.left,
          ),
          PrefSlider(
            key: ValueKey('${widget.configs.first.group}height$isMetric'),
            prefs: [heightPref],
            preferenceConfigs: [heightConfig],
            onUpdated: widget.onUpdated,
          ),
          const VerticalSpacer(),
          Text(
            'Weight',
            style: Theme.of(context).textTheme.labelMedium,
            textAlign: TextAlign.left,
          ),
          PrefSlider(
            key: ValueKey('${widget.configs.last.group}weight$isMetric'),
            prefs: [weightPref],
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

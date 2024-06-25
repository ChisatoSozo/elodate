import 'package:client/api/pkg/lib/api.dart';
import 'package:client/pages/home/settings/labeled_checkbox.dart';
import 'package:client/pages/home/settings/labeled_radio_group.dart';
import 'package:client/utils/prefs_utils.dart';
import 'package:flutter/material.dart';

String formatLabel(int intValue, PreferenceConfigPublic config) {
  intValue = intValue.clamp(config.min, config.max);
  final value = config.linearMapping == null
      ? intValue.toDouble()
      : decodeFromI16(intValue, config.linearMapping!.realMin,
          config.linearMapping!.realMax, config.min, config.max);

  String formattedValue = value.toStringAsFixed(0);

  final unitMatch = RegExp(r'\((.*?)\)').firstMatch(config.display);
  if (unitMatch != null) {
    formattedValue += ' ${unitMatch.group(1)}';
  }

  if (config.display.contains('Percent')) {
    formattedValue += '%';
  }

  if (config.labels.isNotEmpty &&
      config.labels.every((element) => element.isNotEmpty)) {
    formattedValue = config.labels[value.toInt()];
  }

  return formattedValue;
}

abstract class BaseSlider<Item> extends StatefulWidget {
  final List<Item> items;
  final String unsetLabel;
  final List<PreferenceConfigPublic> preferenceConfigs;
  final Function(List<Item>) onUpdated;

  const BaseSlider({
    required this.items,
    required this.preferenceConfigs,
    required this.onUpdated,
    required this.unsetLabel,
    super.key,
  });

  @override
  BaseSliderState createState();
}

abstract class BaseSliderState<Item, UpdateValue, T extends BaseSlider<Item>>
    extends State<T> {
  late PreferenceConfigPublic _preferenceConfig;
  bool isUnset();

  @override
  void initState() {
    super.initState();
    if (widget.items.length > 1 || widget.preferenceConfigs.length > 1) {
      throw Exception(
          'BaseSlider only supports a single item and preference config');
    }
    _preferenceConfig = widget.preferenceConfigs.first;
    initializeState();
  }

  void initializeState();

  void updateValue(UpdateValue value);

  void updateUnsetValue(bool? newUnset);

  Widget buildSlider();

  @override
  Widget build(BuildContext context) {
    if (_preferenceConfig.min == 0 && _preferenceConfig.max == 1) {
      return buildBooleanRadioGroup();
    } else {
      return buildSliderWithUnsetOption();
    }
  }

  Widget buildBooleanRadioGroup();

  Widget buildSliderWithUnsetOption() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Opacity(
          opacity: isUnset() ? 0.5 : 1.0,
          child: buildSlider(),
        ),
        LabeledCheckbox(
            alignRight: true,
            labelOnRight: false,
            label: widget.unsetLabel,
            checked: isUnset(),
            onChanged: updateUnsetValue),
      ],
    );
  }
}

class PropSlider<T> extends BaseSlider<T> {
  const PropSlider({
    required List<T> props,
    required super.preferenceConfigs,
    required super.onUpdated,
    super.key,
  }) : super(
          items: props,
          unsetLabel: 'No answer',
        );

  @override
  PropSliderState createState() => PropSliderState();
}

class PropSliderState extends BaseSliderState<ApiUserPropsInner, int,
    PropSlider<ApiUserPropsInner>> {
  late int _value;

  @override
  bool isUnset() {
    return widget.items.first.value == -32768;
  }

  @override
  void initializeState() {
    _value = widget.items.first.value;
  }

  @override
  void updateValue(int value) {
    setState(() {
      _value = value;
    });
    widget.items[0].value = _value;
    widget.onUpdated(widget.items.cast<ApiUserPropsInner>());
  }

  @override
  void updateUnsetValue(bool? newUnset) {
    _value = newUnset == true ? -32768 : _preferenceConfig.min;
    updateValue(_value);
  }

  @override
  Widget buildSlider() {
    return Column(
      children: [
        Slider(
          value:
              isUnset() ? _preferenceConfig.min.toDouble() : _value.toDouble(),
          min: _preferenceConfig.min.toDouble(),
          max: _preferenceConfig.max.toDouble(),
          divisions: _preferenceConfig.max - _preferenceConfig.min,
          onChanged: (value) => updateValue(value.round()),
        ),
        if (!isUnset())
          Text(
            formatLabel(_value, _preferenceConfig),
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    );
  }

  @override
  Widget buildBooleanRadioGroup() {
    return LabeledRadioGroup(
      values: const [("Yes", 1), ("No", 0), ("No answer", -32768)],
      initialValue: widget.items.first.value,
      onChanged: (value) => updateValue(value),
    );
  }
}

class PrefSlider<T> extends BaseSlider<T> {
  const PrefSlider({
    required List<T> prefs,
    required super.preferenceConfigs,
    required super.onUpdated,
    super.key,
  }) : super(
          items: prefs,
          unsetLabel: 'No preference',
        );

  @override
  PrefSliderState createState() => PrefSliderState();
}

class PrefSliderState extends BaseSliderState<ApiUserPrefsInner,
    ApiUserPrefsInnerRange, PrefSlider<ApiUserPrefsInner>> {
  late ApiUserPrefsInnerRange range;

  @override
  bool isUnset() {
    return widget.items.first.range.max == 32767 &&
        widget.items.first.range.min == -32768;
  }

  @override
  void initializeState() {
    range = widget.items.first.range;
  }

  @override
  void updateValue(ApiUserPrefsInnerRange value) {
    //are the values min and max? if so, set to -32768 and 32767
    if (value.min == _preferenceConfig.min &&
        value.max == _preferenceConfig.max) {
      value = ApiUserPrefsInnerRange(min: -32768, max: 32767);
    }
    setState(() {
      range = value;
    });
    widget.items[0].range = range;
    widget.onUpdated(widget.items.cast<ApiUserPrefsInner>());
  }

  @override
  void updateUnsetValue(bool? newUnset) {
    range = newUnset == true
        ? ApiUserPrefsInnerRange(min: -32768, max: 32767)
        : ApiUserPrefsInnerRange(
            min: _preferenceConfig.min + 1, max: _preferenceConfig.max);
    updateValue(range);
  }

  @override
  Widget buildSlider() {
    return Column(
      children: [
        RangeSlider(
          values: isUnset()
              ? RangeValues(_preferenceConfig.min.toDouble(),
                  _preferenceConfig.max.toDouble())
              : RangeValues(
                  range.min.toDouble().clamp(_preferenceConfig.min.toDouble(),
                      _preferenceConfig.max.toDouble()),
                  range.max.toDouble().clamp(_preferenceConfig.min.toDouble(),
                      _preferenceConfig.max.toDouble()),
                ),
          min: _preferenceConfig.min.toDouble(),
          max: _preferenceConfig.max.toDouble(),
          divisions: _preferenceConfig.max - _preferenceConfig.min,
          onChanged: (values) => updateValue(ApiUserPrefsInnerRange(
            min: values.start.round(),
            max: values.end.round(),
          )),
        ),
        if (!isUnset())
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(formatLabel(range.min, _preferenceConfig),
                  style: Theme.of(context).textTheme.bodySmall),
              Text(formatLabel(range.max, _preferenceConfig),
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
      ],
    );
  }

  @override
  Widget buildBooleanRadioGroup() {
    return LabeledRadioGroup(
      values: [
        ("Yes", ApiUserPrefsInnerRange(max: 1, min: 1)),
        ("No", ApiUserPrefsInnerRange(max: 0, min: 0)),
        ("No preference", ApiUserPrefsInnerRange(max: 1, min: 0))
      ],
      initialValue: widget.items.first.range.max == 32767 &&
              widget.items.first.range.min == -32768
          ? ApiUserPrefsInnerRange(max: 1, min: 0)
          : widget.items.first.range,
      onChanged: (value) => updateValue(value),
    );
  }
}

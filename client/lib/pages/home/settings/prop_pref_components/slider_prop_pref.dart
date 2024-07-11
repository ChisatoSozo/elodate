import 'package:client/api/pkg/lib/api.dart';
import 'package:client/components/spacer.dart';
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

  if (config.display.contains('(')) {
    final unitMatch = RegExp(r'\((.*?)\)').firstMatch(config.display);
    if (unitMatch != null) {
      formattedValue += ' ${unitMatch.group(1)}';
    }
  }

  if (config.display.contains('Percent')) {
    formattedValue += '%';
  }

  if (config.labels.isNotEmpty &&
      config.labels.every((element) => element.isNotEmpty)) {
    formattedValue = config.labels[value.toInt()];
  }

  if (config.name == 'retirement_age' && value == 75) {
    formattedValue = 'Never';
  }

  return formattedValue;
}

abstract class BaseSlider<T> extends StatefulWidget {
  final List<T> items;
  final String? unsetLabel;
  final List<PreferenceConfigPublic> preferenceConfigs;
  final Function(List<T>) onUpdated;

  const BaseSlider({
    required this.items,
    required this.preferenceConfigs,
    required this.onUpdated,
    this.unsetLabel,
    super.key,
  });

  @override
  BaseSliderState<T, BaseSlider<T>> createState();
}

abstract class BaseSliderState<T, W extends BaseSlider<T>> extends State<W> {
  late PreferenceConfigPublic _preferenceConfig;

  @override
  void initState() {
    super.initState();
    if (widget.items.length != 1 || widget.preferenceConfigs.length != 1) {
      throw Exception(
          'BaseSlider only supports a single item and preference config');
    }
    _preferenceConfig = widget.preferenceConfigs.first;
    initializeState();
  }

  void initializeState();
  bool isUnset();
  void updateValue(dynamic value);
  void updateUnsetValue(bool? newUnset);
  Widget buildSlider();
  Widget buildBooleanRadioGroup();

  @override
  Widget build(BuildContext context) {
    if (_preferenceConfig.min == 0 && _preferenceConfig.max == 1) {
      return buildBooleanRadioGroup();
    } else {
      return widget.unsetLabel == null
          ? buildSlider()
          : buildSliderWithUnsetOption();
    }
  }

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
          label: widget.unsetLabel!,
          checked: isUnset(),
          onChanged: updateUnsetValue,
        ),
      ],
    );
  }
}

class PropSlider extends BaseSlider<ApiUserPropsInner> {
  const PropSlider({
    required List<ApiUserPropsInner> props,
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

class PropSliderState extends BaseSliderState<ApiUserPropsInner, PropSlider> {
  late int _value;

  @override
  bool isUnset() => _value == -32768;

  @override
  void initializeState() {
    _value = widget.items.first.value;
  }

  @override
  void updateValue(dynamic value) {
    if (value is int) {
      setState(() {
        _value = value;
      });
      widget.items[0].value = _value;
      widget.onUpdated(widget.items);
    }
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

class PrefSlider extends BaseSlider<ApiUserPrefsInner> {
  const PrefSlider({
    required List<ApiUserPrefsInner> prefs,
    required super.preferenceConfigs,
    required super.onUpdated,
    super.key,
  }) : super(
          items: prefs,
        );

  @override
  PrefSliderState createState() => PrefSliderState();
}

class PrefSliderState extends BaseSliderState<ApiUserPrefsInner, PrefSlider> {
  late ApiUserPrefsInnerRange range;

  @override
  bool isUnset() =>
      widget.items.first.range.max == 32767 &&
      widget.items.first.range.min == -32768;

  @override
  void initializeState() {
    range = widget.items.first.range;
  }

  @override
  void updateValue(dynamic value) {
    if (value is ApiUserPrefsInnerRange) {
      if (value.min == _preferenceConfig.min &&
          value.max == _preferenceConfig.max) {
        value = ApiUserPrefsInnerRange(min: -32768, max: 32767);
      }
      setState(() {
        range = value;
      });
      widget.items[0].range = range;
      widget.onUpdated(widget.items);
    }
  }

  @override
  void updateUnsetValue(bool? newUnset) {
    range = newUnset == true
        ? ApiUserPrefsInnerRange(min: -32768, max: 32767)
        : ApiUserPrefsInnerRange(
            min: _preferenceConfig.min, max: _preferenceConfig.max - 1);
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
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              flex: 1,
              child: Container(
                alignment: Alignment.topLeft,
                child: Text(
                  formatLabel(range.min, _preferenceConfig),
                  style: Theme.of(context).textTheme.bodySmall,
                  softWrap: true,
                  textAlign: TextAlign.left,
                ),
              ),
            ),
            const HorizontalSpacer(),
            Flexible(
              flex: 1,
              child: Container(
                alignment: Alignment.topRight,
                child: Text(
                  formatLabel(range.max, _preferenceConfig),
                  style: Theme.of(context).textTheme.bodySmall,
                  softWrap: true,
                  textAlign: TextAlign.right,
                ),
              ),
            ),
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

import 'package:client/api/pkg/lib/api.dart';
import 'package:client/utils/preference_utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String formatLabel(int intValue, PreferenceConfigPublic config) {
  //clamp intValue to min and max
  intValue = intValue.clamp(config.min, config.max);
  var label = config.display;
  var labels = config.labels;
  var value = config.linearMapping == null
      ? intValue.toDouble()
      : decodeFromI16(intValue, config.linearMapping!.realMin,
          config.linearMapping!.realMax, config.min, config.max);
  String formattedValue = value.toStringAsFixed(0);
  RegExp unitRegex = RegExp(r'\((.*?)\)');
  var unitMatch = unitRegex.firstMatch(label);
  if (unitMatch != null) {
    formattedValue += ' ${unitMatch.group(1)}';
  }
  if (label.contains('Salary')) {
    final numberFormat = NumberFormat('#,##0.00');
    formattedValue = '\$${numberFormat.format(value)}';
  }
  if (label.contains('Percent')) {
    formattedValue += '%';
  }
  if (labels.length == 5 && labels.every((element) => element.isNotEmpty)) {
    formattedValue = labels[value.toInt()];
  }
  return formattedValue;
}

class PropSlider extends StatefulWidget {
  final List<ApiUserPropertiesInner> properties;
  final List<PreferenceConfigPublic> preferenceConfigs;
  final Function(List<ApiUserPropertiesInner>) onUpdated;

  const PropSlider({
    required this.properties,
    required this.preferenceConfigs,
    required this.onUpdated,
    super.key,
  });

  @override
  PropSliderState createState() => PropSliderState();
}

class PropSliderState extends State<PropSlider> {
  late int _value;
  late PreferenceConfigPublic _preferenceConfig;
  bool _isUnset = false;

  @override
  void initState() {
    super.initState();
    if (widget.properties.length > 1) {
      throw Exception('PropSlider only supports a single property');
    }
    if (widget.preferenceConfigs.length > 1) {
      throw Exception('PropSlider only supports a single preference config');
    }
    _value = widget.properties.first.value;
    _preferenceConfig = widget.preferenceConfigs.first;
    _isUnset = _value == -32768;
  }

  void _updateValue(int index, double value) {
    setState(() {
      _value = value.round();
      _isUnset = false;
    });
    widget.properties[index].value = _value;
    widget.onUpdated(widget.properties);
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: _isUnset ? 0.5 : 1.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Slider(
            value:
                _isUnset ? _preferenceConfig.min.toDouble() : _value.toDouble(),
            min: _preferenceConfig.min.toDouble(),
            max: _preferenceConfig.max.toDouble(),
            divisions: _preferenceConfig.max - _preferenceConfig.min,
            label: formatLabel(
              _value,
              _preferenceConfig,
            ),
            onChanged: (value) => _updateValue(0, value),
          ),
          Row(
            children: [
              Checkbox(
                value: _isUnset,
                onChanged: (checked) {
                  setState(() {
                    _isUnset = checked ?? false;
                    _value = _isUnset ? -32768 : _preferenceConfig.min;
                  });
                  widget.properties[0].value = _value;
                  widget.onUpdated(widget.properties);
                },
              ),
              const Text('Unset'),
            ],
          ),
        ],
      ),
    );
  }
}

class PrefSlider extends StatefulWidget {
  final List<ApiUserPreferencesInner> preferences;
  final List<PreferenceConfigPublic> preferenceConfigs;
  final Function(List<ApiUserPreferencesInner>) onUpdated;

  const PrefSlider({
    required this.preferences,
    required this.preferenceConfigs,
    required this.onUpdated,
    super.key,
  });

  @override
  PrefSliderState createState() => PrefSliderState();
}

class PrefSliderState extends State<PrefSlider> {
  late ApiUserPreferencesInnerRange range;
  late PreferenceConfigPublic _preferenceConfig;
  bool _isUnset = false;

  @override
  void initState() {
    super.initState();
    if (widget.preferences.length > 1) {
      throw Exception('PrefSlider only supports a single property');
    }
    if (widget.preferenceConfigs.length > 1) {
      throw Exception('PrefSlider only supports a single preference config');
    }
    range = widget.preferences.first.range;
    _preferenceConfig = widget.preferenceConfigs.first;
    _isUnset = range.min <= _preferenceConfig.min &&
        range.max >= _preferenceConfig.max;
  }

  void _updateRange(ApiUserPreferencesInnerRange newRange) {
    var isUnset = newRange.min == _preferenceConfig.min &&
        newRange.max == _preferenceConfig.max;
    newRange = _isUnset
        ? ApiUserPreferencesInnerRange(
            min: -32768,
            max: 32767,
          )
        : newRange;
    setState(() {
      range = newRange;
      _isUnset = isUnset;
    });
    widget.preferences.first.range = range;
    widget.onUpdated(widget.preferences);
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: _isUnset ? 0.5 : 1.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RangeSlider(
            values: _isUnset
                ? RangeValues(
                    _preferenceConfig.min.toDouble(),
                    _preferenceConfig.max.toDouble(),
                  )
                //higher of _preferenceConfig.min and range.min
                //lower of _preferenceConfig.max and range.max
                : RangeValues(
                    range.min.toDouble().clamp(
                          _preferenceConfig.min.toDouble(),
                          _preferenceConfig.max.toDouble(),
                        ),
                    range.max.toDouble().clamp(
                          _preferenceConfig.min.toDouble(),
                          _preferenceConfig.max.toDouble(),
                        ),
                  ),
            min: _preferenceConfig.min.toDouble(),
            max: _preferenceConfig.max.toDouble(),
            divisions: _preferenceConfig.max - _preferenceConfig.min,
            labels: RangeLabels(
              formatLabel(
                range.min,
                _preferenceConfig,
              ),
              formatLabel(
                range.max,
                _preferenceConfig,
              ),
            ),
            onChanged: (values) => {
              _updateRange(
                ApiUserPreferencesInnerRange(
                  min: values.start.round(),
                  max: values.end.round(),
                ),
              ),
            },
          ),
          Row(
            children: [
              Checkbox(
                value: _isUnset,
                onChanged: (checked) {
                  if (checked == null || checked == false) {
                    _updateRange(
                      ApiUserPreferencesInnerRange(
                        min: _preferenceConfig.min + 1,
                        max: _preferenceConfig.max,
                      ),
                    );
                  } else {
                    _updateRange(
                      ApiUserPreferencesInnerRange(
                        min: _preferenceConfig.min,
                        max: _preferenceConfig.max,
                      ),
                    );
                  }
                },
              ),
              const Text('No preference'),
            ],
          ),
        ],
      ),
    );
  }
}

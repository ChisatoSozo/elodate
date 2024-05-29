import 'package:client/api/pkg/lib/api.dart';
import 'package:client/components/labeled_checkbox.dart';
import 'package:client/components/labeled_radio_group.dart';
import 'package:client/utils/prefs_utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String formatLabel(int intValue, PreferenceConfigPublic config) {
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
  final List<ApiUserPropsInner> props;
  final List<PreferenceConfigPublic> preferenceConfigs;
  final Function(List<ApiUserPropsInner>) onUpdated;

  const PropSlider({
    required this.props,
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
    if (widget.props.length > 1) {
      throw Exception('PropSlider only supports a single property');
    }
    if (widget.preferenceConfigs.length > 1) {
      throw Exception('PropSlider only supports a single preference config');
    }
    _value = widget.props.first.value;
    _preferenceConfig = widget.preferenceConfigs.first;
    _isUnset = _value == -32768;
  }

  void _updateValue(int value) {
    setState(() {
      _value = value;
      _isUnset = false;
    });
    widget.props[0].value = _value;
    widget.onUpdated(widget.props);
  }

  void _toggleUnset(bool? checked) {
    setState(() {
      _isUnset = checked ?? false;
      _value = _isUnset ? -32768 : _preferenceConfig.min;
    });
    widget.props[0].value = _value;
    widget.onUpdated(widget.props);
  }

  @override
  Widget build(BuildContext context) {
    if (_preferenceConfig.min == 0 && _preferenceConfig.max == 1) {
      return LabeledRadioGroup(
          values: const [("Yes", 1), ("No", 0), ("No answer", -32768)],
          initialValue: widget.props.first.value,
          onChanged: (value) => _updateValue(value));
    } else {
      return Opacity(
        opacity: _isUnset ? 0.5 : 1.0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Slider(
              value: _isUnset
                  ? _preferenceConfig.min.toDouble()
                  : _value.toDouble(),
              min: _preferenceConfig.min.toDouble(),
              max: _preferenceConfig.max.toDouble(),
              divisions: _preferenceConfig.max - _preferenceConfig.min,
              label: formatLabel(
                _value,
                _preferenceConfig,
              ),
              onChanged: (value) => _updateValue(value.round()),
            ),
            LabeledCheckbox(
              alignRight: true,
              labelOnRight: false,
              label: 'Unset',
              checked: _isUnset,
              onChanged: _toggleUnset,
            ),
          ],
        ),
      );
    }
  }
}

class PrefSlider extends StatefulWidget {
  final List<ApiUserPrefsInner> prefs;
  final List<PreferenceConfigPublic> preferenceConfigs;
  final Function(List<ApiUserPrefsInner>) onUpdated;

  const PrefSlider({
    required this.prefs,
    required this.preferenceConfigs,
    required this.onUpdated,
    super.key,
  });

  @override
  PrefSliderState createState() => PrefSliderState();
}

class PrefSliderState extends State<PrefSlider> {
  late ApiUserPrefsInnerRange range;
  late PreferenceConfigPublic _preferenceConfig;
  bool _isUnset = false;

  @override
  void initState() {
    super.initState();
    if (widget.prefs.length > 1) {
      throw Exception('PrefSlider only supports a single property');
    }
    if (widget.preferenceConfigs.length > 1) {
      throw Exception('PrefSlider only supports a single preference config');
    }
    range = widget.prefs.first.range;
    _preferenceConfig = widget.preferenceConfigs.first;
    _isUnset = range.min <= _preferenceConfig.min &&
        range.max >= _preferenceConfig.max;
  }

  void _updateRange(ApiUserPrefsInnerRange newRange) {
    var isUnset = newRange.min == _preferenceConfig.min &&
        newRange.max == _preferenceConfig.max;
    newRange = _isUnset
        ? ApiUserPrefsInnerRange(
            min: -32768,
            max: 32767,
          )
        : newRange;
    setState(() {
      range = newRange;
      _isUnset = isUnset;
    });
    widget.prefs.first.range = range;
    widget.onUpdated(widget.prefs);
  }

  void _toggleUnset(bool? checked) {
    if (checked == null || checked == false) {
      _updateRange(
        ApiUserPrefsInnerRange(
          min: _preferenceConfig.min + 1,
          max: _preferenceConfig.max,
        ),
      );
    } else {
      _updateRange(
        ApiUserPrefsInnerRange(
          min: _preferenceConfig.min,
          max: _preferenceConfig.max,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    var range = widget.prefs.first.range;

    if (_preferenceConfig.min == 0 && _preferenceConfig.max == 1) {
      return LabeledRadioGroup(
          values: [
            ("Yes", ApiUserPrefsInnerRange(max: 1, min: 1)),
            ("No", ApiUserPrefsInnerRange(max: 0, min: 0)),
            ("No preference", ApiUserPrefsInnerRange(max: 1, min: 0))
          ],
          initialValue: widget.prefs.first.range.max == 32767 &&
                  widget.prefs.first.range.min == -32768
              ? ApiUserPrefsInnerRange(max: 1, min: 0)
              : widget.prefs.first.range,
          onChanged: (value) => _updateRange(value));
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Opacity(
            opacity: _isUnset ? 0.5 : 1.0,
            child: RangeSlider(
              values: _isUnset
                  ? RangeValues(
                      _preferenceConfig.min.toDouble(),
                      _preferenceConfig.max.toDouble(),
                    )
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
                  ApiUserPrefsInnerRange(
                    min: values.start.round(),
                    max: values.end.round(),
                  ),
                ),
              },
            ),
          ),
          LabeledCheckbox(
            alignRight: true,
            labelOnRight: false,
            label: 'No preference',
            checked: _isUnset,
            onChanged: _toggleUnset,
          ),
        ],
      );
    }
  }
}

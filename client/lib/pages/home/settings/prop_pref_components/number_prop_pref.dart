import 'package:client/api/pkg/lib/api.dart';
import 'package:client/components/spacer.dart';
import 'package:client/pages/home/settings/labeled_checkbox.dart';
import 'package:client/pages/home/settings/labeled_radio_group.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

abstract class BaseNumericalInput<T> extends StatefulWidget {
  final List<T> items;
  final String? unsetLabel;
  final List<PreferenceConfigPublic> preferenceConfigs;
  final Function(List<T>) onUpdated;

  const BaseNumericalInput({
    required this.items,
    required this.preferenceConfigs,
    required this.onUpdated,
    this.unsetLabel,
    super.key,
  });

  @override
  BaseNumericalInputState<T, BaseNumericalInput<T>> createState();
}

abstract class BaseNumericalInputState<T, W extends BaseNumericalInput<T>>
    extends State<W> {
  late PreferenceConfigPublic _preferenceConfig;

  @override
  void initState() {
    super.initState();
    if (widget.items.length != 1 || widget.preferenceConfigs.length != 1) {
      throw Exception(
          'BaseNumericalInput only supports a single item and preference config');
    }
    _preferenceConfig = widget.preferenceConfigs.first;
    initializeState();
  }

  void initializeState();
  bool isUnset();
  void updateValue(dynamic value);
  void updateUnsetValue(bool? newUnset);
  Widget buildNumericalInput();
  Widget buildBooleanRadioGroup();

  @override
  Widget build(BuildContext context) {
    if (_preferenceConfig.min == 0 && _preferenceConfig.max == 1) {
      return buildBooleanRadioGroup();
    } else {
      return widget.unsetLabel == null
          ? buildNumericalInput()
          : buildNumericalInputWithUnsetOption();
    }
  }

  Widget buildNumericalInputWithUnsetOption() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Opacity(
          opacity: isUnset() ? 0.5 : 1.0,
          child: buildNumericalInput(),
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

class PropNumericalInput extends BaseNumericalInput<ApiUserPropsInner> {
  const PropNumericalInput({
    required List<ApiUserPropsInner> props,
    required super.preferenceConfigs,
    required super.onUpdated,
    super.key,
  }) : super(
          items: props,
          unsetLabel: 'No answer',
        );

  @override
  PropNumericalInputState createState() => PropNumericalInputState();
}

class PropNumericalInputState
    extends BaseNumericalInputState<ApiUserPropsInner, PropNumericalInput> {
  late int _value;
  late int _previousValue;
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _value.toString());
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus) {
      _validateAndUpdateValue();
    }
  }

  void _validateAndUpdateValue() {
    final newValue = int.tryParse(_controller.text);
    if (newValue != null) {
      final clampedValue =
          newValue.clamp(_preferenceConfig.min, _preferenceConfig.max);
      _controller.text = clampedValue.toString();
      updateValue(clampedValue);
    } else {
      updateUnsetValue(true);
    }
  }

  @override
  bool isUnset() => _value == -32768;

  @override
  void initializeState() {
    _value = widget.items.first.value;
    _previousValue = _value == -32768 ? _preferenceConfig.min : _value;
  }

  @override
  void updateValue(dynamic value) {
    if (value is int) {
      setState(() {
        _value = value;
        if (!isUnset()) {
          _previousValue = _value;
        }
        _controller.text = _value.toString();
      });
      widget.items[0].value = _value;
      widget.onUpdated(widget.items);
    }
  }

  @override
  void updateUnsetValue(bool? newUnset) {
    setState(() {
      if (newUnset == true) {
        _value = -32768;
        _controller.text = '';
      } else {
        _value = _previousValue;
        _controller.text = _value.toString();
      }
    });
    widget.items[0].value = _value;
    widget.onUpdated(widget.items);
  }

  @override
  Widget buildNumericalInput() {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: _preferenceConfig.display,
        hintText:
            'Enter a value between ${_preferenceConfig.min} and ${_preferenceConfig.max}',
      ),
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

class PrefNumericalInput extends BaseNumericalInput<ApiUserPrefsInner> {
  const PrefNumericalInput({
    required List<ApiUserPrefsInner> prefs,
    required super.preferenceConfigs,
    required super.onUpdated,
    super.key,
  }) : super(
          items: prefs,
        );

  @override
  PrefNumericalInputState createState() => PrefNumericalInputState();
}

class PrefNumericalInputState
    extends BaseNumericalInputState<ApiUserPrefsInner, PrefNumericalInput> {
  late ApiUserPrefsInnerRange range;
  late ApiUserPrefsInnerRange previousRange;
  late TextEditingController _minController;
  late TextEditingController _maxController;
  final FocusNode _minFocusNode = FocusNode();
  final FocusNode _maxFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _minController = TextEditingController(text: range.min.toString());
    _maxController = TextEditingController(text: range.max.toString());
    _minFocusNode.addListener(_handleMinFocusChange);
    _maxFocusNode.addListener(_handleMaxFocusChange);
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    _minFocusNode.removeListener(_handleMinFocusChange);
    _maxFocusNode.removeListener(_handleMaxFocusChange);
    _minFocusNode.dispose();
    _maxFocusNode.dispose();
    super.dispose();
  }

  void _handleMinFocusChange() {
    if (!_minFocusNode.hasFocus) {
      _validateAndUpdateMinValue();
    }
  }

  void _handleMaxFocusChange() {
    if (!_maxFocusNode.hasFocus) {
      _validateAndUpdateMaxValue();
    }
  }

  void _validateAndUpdateMinValue() {
    final newValue = int.tryParse(_minController.text);
    if (newValue != null) {
      final clampedValue = newValue.clamp(_preferenceConfig.min, range.max);
      _minController.text = clampedValue.toString();
      updateValue(ApiUserPrefsInnerRange(min: clampedValue, max: range.max));
    } else {
      updateUnsetValue(true);
    }
  }

  void _validateAndUpdateMaxValue() {
    final newValue = int.tryParse(_maxController.text);
    if (newValue != null) {
      final clampedValue = newValue.clamp(range.min, _preferenceConfig.max);
      _maxController.text = clampedValue.toString();
      updateValue(ApiUserPrefsInnerRange(min: range.min, max: clampedValue));
    } else {
      updateUnsetValue(true);
    }
  }

  @override
  bool isUnset() => range.max == 32767 && range.min == -32768;

  @override
  void initializeState() {
    range = widget.items.first.range;
    previousRange = ApiUserPrefsInnerRange(min: range.min, max: range.max);
  }

  @override
  void updateValue(dynamic value) {
    if (value is ApiUserPrefsInnerRange) {
      setState(() {
        range = value;
        if (!isUnset()) {
          previousRange =
              ApiUserPrefsInnerRange(min: range.min, max: range.max);
        }
        _minController.text = range.min.toString();
        _maxController.text = range.max.toString();
      });
      widget.items[0].range = range;
      widget.onUpdated(widget.items);
    }
  }

  @override
  void updateUnsetValue(bool? newUnset) {
    setState(() {
      if (newUnset == true) {
        range = ApiUserPrefsInnerRange(min: -32768, max: 32767);
        _minController.text = '';
        _maxController.text = '';
      } else {
        range = ApiUserPrefsInnerRange(
            min: previousRange.min, max: previousRange.max);
        _minController.text = range.min.toString();
        _maxController.text = range.max.toString();
      }
    });
    widget.items[0].range = range;
    widget.onUpdated(widget.items);
  }

  @override
  Widget buildNumericalInput() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _minController,
            focusNode: _minFocusNode,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: 'Min ${_preferenceConfig.display}',
              hintText: 'Min: ${_preferenceConfig.min}',
            ),
          ),
        ),
        const HorizontalSpacer(),
        Expanded(
          child: TextField(
            controller: _maxController,
            focusNode: _maxFocusNode,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: 'Max ${_preferenceConfig.display}',
              hintText: 'Max: ${_preferenceConfig.max}',
            ),
          ),
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

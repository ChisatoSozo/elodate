import 'package:client/api/pkg/lib/api.dart';
import 'package:client/utils/slider_utils.dart';
import 'package:flutter/material.dart';

class ValueSliderFormFieldController extends ValueNotifier<int> {
  ValueSliderFormFieldController(super.value);
}

class ValueSliderFormField extends FormField<int> {
  final ValueSliderFormFieldController controller;
  final String title;
  final AdditionalPreferencePublic config;
  final void Function(int)? onUpdate;

  ValueSliderFormField({
    super.key,
    super.validator,
    required this.controller,
    required this.title,
    required this.config,
    this.onUpdate,
    bool autovalidate = false,
  }) : super(
          initialValue: controller.value,
          autovalidateMode: autovalidate
              ? AutovalidateMode.always
              : AutovalidateMode.disabled,
          builder: (FormFieldState<int> state) {
            var value = controller.value;
            if (value != -32768 && (value < config.min || value > config.max)) {
              value = config.min;
            }

            bool isUnset = value == -32768;

            Widget buildValueSlider() {
              String valueLabel;
              if (config.linearMapping != null) {
                valueLabel = isUnset
                    ? 'Unset'
                    : formatLabel(
                        title,
                        decodeFromI16(
                          value,
                          config.linearMapping!.realMin,
                          config.linearMapping!.realMax,
                          config.min,
                          config.max,
                        ),
                        config.labels);
              } else {
                valueLabel = isUnset
                    ? 'Unset'
                    : formatLabel(title, value.toDouble(), config.labels);
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(title),
                      if (isUnset)
                        Text(
                          'Unset',
                          style: TextStyle(
                            color:
                                Theme.of(state.context).colorScheme.secondary,
                          ),
                        ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Opacity(
                          opacity: isUnset ? 0.5 : 1.0,
                          child: Slider(
                            value: isUnset
                                ? config.min.toDouble()
                                : value.toDouble(),
                            min: config.min.toDouble(),
                            max: config.max.toDouble(),
                            divisions: config.max - config.min,
                            label: valueLabel,
                            onChanged: (newValue) {
                              var outValue = newValue.toInt();
                              state.didChange(outValue);
                              controller.value = outValue;
                              if (onUpdate != null) {
                                onUpdate(outValue);
                              }
                            },
                          ),
                        ),
                      ),
                      Checkbox(
                        value: isUnset,
                        onChanged: (checked) {
                          if (checked != null) {
                            var newValue = checked ? -32768 : config.min;
                            state.didChange(newValue);
                            controller.value = newValue;
                            if (onUpdate != null) {
                              onUpdate(newValue);
                            }
                          }
                        },
                      ),
                      const Text('Unset'),
                    ],
                  ),
                  if (state.hasError)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        state.errorText!,
                        style: TextStyle(
                          color: Theme.of(state.context).colorScheme.error,
                        ),
                      ),
                    ),
                ],
              );
            }

            Widget buildRadioButtons() {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<int>(
                          title: const Text('Yes'),
                          value: 1,
                          groupValue: isUnset ? -1 : value,
                          onChanged: (val) {
                            if (val != null) {
                              state.didChange(val);
                              controller.value = val;
                              if (onUpdate != null) {
                                onUpdate(val);
                              }
                            }
                          },
                          activeColor:
                              Theme.of(state.context).colorScheme.secondary,
                          visualDensity: VisualDensity.compact,
                          dense: true,
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<int>(
                          title: const Text('No'),
                          value: 0,
                          groupValue: isUnset ? -1 : value,
                          onChanged: (val) {
                            if (val != null) {
                              state.didChange(val);
                              controller.value = val;
                              if (onUpdate != null) {
                                onUpdate(val);
                              }
                            }
                          },
                          activeColor:
                              Theme.of(state.context).colorScheme.secondary,
                          visualDensity: VisualDensity.compact,
                          dense: true,
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<int>(
                          title: const Text('No Preference'),
                          value: -32768,
                          groupValue: isUnset ? -1 : value,
                          onChanged: (val) {
                            if (val != null) {
                              state.didChange(val);
                              controller.value = val;
                              if (onUpdate != null) {
                                onUpdate(val);
                              }
                            }
                          },
                          activeColor:
                              Theme.of(state.context).colorScheme.secondary,
                          visualDensity: VisualDensity.compact,
                          dense: true,
                        ),
                      ),
                    ],
                  ),
                  if (state.hasError)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        state.errorText!,
                        style: TextStyle(
                          color: Theme.of(state.context).colorScheme.error,
                        ),
                      ),
                    ),
                ],
              );
            }

            if (config.min == 0 && config.max == 1) {
              return buildRadioButtons();
            } else {
              return buildValueSlider();
            }
          },
        );

  @override
  FormFieldState<int> createState() => ValueSliderFormFieldState();
}

class ValueSliderFormFieldState extends FormFieldState<int> {
  @override
  void initState() {
    super.initState();
    (widget as ValueSliderFormField)
        .controller
        .addListener(_handleControllerChanged);
  }

  @override
  void dispose() {
    (widget as ValueSliderFormField)
        .controller
        .removeListener(_handleControllerChanged);
    super.dispose();
  }

  void _handleControllerChanged() {
    setState(() {
      setValue((widget as ValueSliderFormField).controller.value);
    });
  }
}

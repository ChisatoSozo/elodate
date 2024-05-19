import 'package:client/api/pkg/lib/api.dart';
import 'package:client/utils/slider_utils.dart';
import 'package:flutter/material.dart';

class RangeSliderFormFieldController
    extends ValueNotifier<PreferenceAdditionalPreferencesValue> {
  RangeSliderFormFieldController(super.value);
}

class RangeSliderFormField
    extends FormField<PreferenceAdditionalPreferencesValue> {
  final RangeSliderFormFieldController controller;
  final String title;
  final AdditionalPreferencePublic config;
  final void Function(PreferenceAdditionalPreferencesValue)? onUpdate;

  RangeSliderFormField({
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
          builder:
              (FormFieldState<PreferenceAdditionalPreferencesValue> state) {
            var rangeValueMin = controller.value.min;
            if (rangeValueMin < config.min) {
              rangeValueMin = config.min;
            }
            var rangeValueMax = controller.value.max;
            if (rangeValueMax > config.max) {
              rangeValueMax = config.max;
            }

            Widget buildRangeSlider() {
              RangeLabels rangeLabels;
              if (config.linearMapping != null) {
                rangeLabels = RangeLabels(
                  formatLabel(
                      title,
                      decodeFromI16(
                        rangeValueMin,
                        config.linearMapping!.realMin,
                        config.linearMapping!.realMax,
                        config.min,
                        config.max,
                      ),
                      config.labels),
                  formatLabel(
                      title,
                      decodeFromI16(
                        rangeValueMax,
                        config.linearMapping!.realMin,
                        config.linearMapping!.realMax,
                        config.min,
                        config.max,
                      ),
                      config.labels),
                );
              } else {
                rangeLabels = RangeLabels(
                  formatLabel(title, rangeValueMin as double, config.labels),
                  formatLabel(title, rangeValueMax as double, config.labels),
                );
              }

              var unset =
                  rangeValueMin == config.min && rangeValueMax == config.max;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(title),
                        if (unset)
                          Text(
                            'No preference',
                            style: TextStyle(
                              color:
                                  Theme.of(state.context).colorScheme.secondary,
                            ),
                          ),
                      ]),
                  Opacity(
                    opacity: unset ? 0.5 : 1.0,
                    child: RangeSlider(
                      values: RangeValues(
                        rangeValueMin.toDouble(),
                        rangeValueMax.toDouble(),
                      ),
                      min: config.min.toDouble(),
                      max: config.max.toDouble(),
                      divisions: config.max - config.min,
                      labels: rangeLabels,
                      onChanged: (values) {
                        var outStart = values.start.toInt();
                        var outEnd = values.end.toInt();
                        if (values.start == config.min &&
                            values.end == config.max) {
                          outStart = -32768;
                          outEnd = 32767;
                        }

                        var outPref = PreferenceAdditionalPreferencesValue(
                          min: outStart,
                          max: outEnd,
                        );

                        state.didChange(outPref);
                        controller.value = outPref;
                        if (onUpdate != null) {
                          onUpdate(outPref);
                        }
                      },
                    ),
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
                          groupValue: rangeValueMin == 1 && rangeValueMax == 1
                              ? 1
                              : rangeValueMin == 0 && rangeValueMax == 1
                                  ? -1
                                  : 0,
                          onChanged: (value) {
                            if (value != null) {
                              var outPref =
                                  PreferenceAdditionalPreferencesValue(
                                min: 1,
                                max: 1,
                              );
                              state.didChange(outPref);
                              controller.value = outPref;
                              if (onUpdate != null) {
                                onUpdate(outPref);
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
                          groupValue: rangeValueMin == 0 && rangeValueMax == 0
                              ? 0
                              : rangeValueMin == 0 && rangeValueMax == 1
                                  ? -1
                                  : 1,
                          onChanged: (value) {
                            if (value != null) {
                              var outPref =
                                  PreferenceAdditionalPreferencesValue(
                                min: 0,
                                max: 0,
                              );
                              state.didChange(outPref);
                              controller.value = outPref;
                              if (onUpdate != null) {
                                onUpdate(outPref);
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
                          value: -1,
                          groupValue: rangeValueMin == 0 && rangeValueMax == 1
                              ? -1
                              : rangeValueMin == 0 && rangeValueMax == 0
                                  ? 0
                                  : 1,
                          onChanged: (value) {
                            if (value != null) {
                              var outPref =
                                  PreferenceAdditionalPreferencesValue(
                                min: 0,
                                max: 1,
                              );
                              state.didChange(outPref);
                              controller.value = outPref;
                              if (onUpdate != null) {
                                onUpdate(outPref);
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
              return buildRangeSlider();
            }
          },
        );

  @override
  FormFieldState<PreferenceAdditionalPreferencesValue> createState() =>
      RangeSliderFormFieldState();
}

class RangeSliderFormFieldState
    extends FormFieldState<PreferenceAdditionalPreferencesValue> {
  @override
  void initState() {
    super.initState();
    (widget as RangeSliderFormField)
        .controller
        .addListener(_handleControllerChanged);
  }

  @override
  void dispose() {
    (widget as RangeSliderFormField)
        .controller
        .removeListener(_handleControllerChanged);
    super.dispose();
  }

  void _handleControllerChanged() {
    setState(() {
      setValue((widget as RangeSliderFormField).controller.value);
    });
  }
}

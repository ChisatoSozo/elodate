import 'package:client/api/pkg/lib/api.dart';
import 'package:client/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RangeSliderFormFieldController
    extends ValueNotifier<PreferenceAdditionalPreferencesValue> {
  RangeSliderFormFieldController(super.value);
}

class RangeSliderFormField
    extends FormField<PreferenceAdditionalPreferencesValue> {
  final RangeSliderFormFieldController controller;
  final String title;
  final AdditionalPreferencePublic config;

  RangeSliderFormField({
    super.key,
    super.validator,
    required this.controller,
    required this.title,
    required this.config,
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

            String formatLabel(String label, double value) {
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
              if (config.labels.length == 5 &&
                  config.labels.every((element) => element != "")) {
                formattedValue = config.labels[value.toInt()];
              }
              return formattedValue;
            }

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
                    )),
                formatLabel(
                    title,
                    decodeFromI16(
                      rangeValueMax,
                      config.linearMapping!.realMin,
                      config.linearMapping!.realMax,
                      config.min,
                      config.max,
                    )),
              );
            } else {
              rangeLabels = RangeLabels(
                formatLabel(title, rangeValueMin as double),
                formatLabel(title, rangeValueMax as double),
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
                    },
                  ),
                ),
                if (state.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      state.errorText!,
                      style: TextStyle(
                          color: Theme.of(state.context).colorScheme.error),
                    ),
                  ),
              ],
            );
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

import 'package:client/pages/home/settings/labeled_radio.dart';
import 'package:flutter/material.dart';

class LabeledRadioGroup<T> extends StatefulWidget {
  final List<(String, T)> values;
  final T initialValue;
  final Function(T) onChanged;

  const LabeledRadioGroup({
    super.key,
    required this.values,
    required this.initialValue,
    required this.onChanged,
  });

  @override
  LabeledRadioGroupState<T> createState() => LabeledRadioGroupState<T>();
}

class LabeledRadioGroupState<T> extends State<LabeledRadioGroup<T>> {
  late int index;

  @override
  void initState() {
    super.initState();
    index = widget.values
        .indexWhere((element) => element.$2 == widget.initialValue);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widget.values
          .map((value) => LabeledRadio<T>(
                label: value.$1,
                groupValue: widget.values[index].$2,
                value: value.$2,
                onChanged: (T? value) {
                  setState(() {
                    index = widget.values
                        .indexWhere((element) => element.$2 == value);
                  });
                  widget.onChanged(value as T);
                },
              ))
          .toList(),
    );
  }
}

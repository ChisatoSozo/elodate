import 'package:flutter/material.dart';

class LabeledRadio<T> extends StatelessWidget {
  final T value;
  final T groupValue;
  final ValueChanged<T?> onChanged;
  final String label;
  final TextStyle? labelStyle;
  final bool labelOnLeft;
  final Color? activeColor;
  final Color? focusColor;
  final Color? hoverColor;
  final MouseCursor? mouseCursor;
  final MaterialTapTargetSize? materialTapTargetSize;
  final VisualDensity? visualDensity;
  final bool toggleable;

  const LabeledRadio({
    super.key,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    required this.label,
    this.labelStyle,
    this.labelOnLeft = true,
    this.activeColor,
    this.focusColor,
    this.hoverColor,
    this.mouseCursor,
    this.materialTapTargetSize,
    this.visualDensity,
    this.toggleable = false,
  });

  @override
  Widget build(BuildContext context) {
    return labelOnLeft
        ? ListTile(
            title: Text(label, style: labelStyle),
            leading: Radio<T>(
              value: value,
              groupValue: groupValue,
              onChanged: onChanged,
              activeColor: activeColor,
              focusColor: focusColor,
              hoverColor: hoverColor,
              mouseCursor: mouseCursor,
              materialTapTargetSize: materialTapTargetSize,
              visualDensity: visualDensity,
              toggleable: toggleable,
            ),
          )
        : ListTile(
            title: Text(label, style: labelStyle),
            trailing: Radio<T>(
              value: value,
              groupValue: groupValue,
              onChanged: onChanged,
              activeColor: activeColor,
              focusColor: focusColor,
              hoverColor: hoverColor,
              mouseCursor: mouseCursor,
              materialTapTargetSize: materialTapTargetSize,
              visualDensity: visualDensity,
              toggleable: toggleable,
            ),
          );
  }
}

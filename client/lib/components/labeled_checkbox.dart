import 'package:flutter/material.dart';

class LabeledCheckbox extends StatelessWidget {
  final bool checked;
  final ValueChanged<bool?> onChanged;
  final String label;
  final TextStyle? labelStyle;
  final bool labelOnRight;
  final bool alignRight;
  final Color? activeColor;
  final Color? checkColor;
  final Color? focusColor;
  final Color? hoverColor;
  final MouseCursor? mouseCursor;
  final MaterialTapTargetSize? materialTapTargetSize;
  final VisualDensity? visualDensity;

  const LabeledCheckbox({
    super.key,
    required this.checked,
    required this.onChanged,
    required this.label,
    this.labelStyle,
    this.labelOnRight = true,
    this.alignRight = false,
    this.activeColor,
    this.checkColor,
    this.focusColor,
    this.hoverColor,
    this.mouseCursor,
    this.materialTapTargetSize,
    this.visualDensity,
  });

  @override
  Widget build(BuildContext context) {
    final labelWidget = Expanded(
      child: InkWell(
        onTap: () => onChanged(!checked),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Text(
            label,
            style: labelStyle,
            softWrap: true,
            overflow: TextOverflow.visible,
          ),
        ),
      ),
    );

    final checkboxWidget = Checkbox(
      value: checked,
      onChanged: onChanged,
      activeColor: activeColor,
      checkColor: checkColor,
      focusColor: focusColor,
      hoverColor: hoverColor,
      mouseCursor: mouseCursor,
      materialTapTargetSize: materialTapTargetSize,
      visualDensity: visualDensity,
    );

    return Container(
      alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: labelOnRight
            ? [
                checkboxWidget,
                const SizedBox(width: 8),
                labelWidget,
              ]
            : [
                labelWidget,
                const SizedBox(width: 8),
                checkboxWidget,
              ],
      ),
    );
  }
}

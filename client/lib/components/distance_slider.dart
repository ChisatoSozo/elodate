import 'package:flutter/material.dart';

class DistanceSliderWidget extends StatelessWidget {
  final String title;
  final int distanceIndex;
  final List<int> presetDistances;
  final ValueChanged<int> onChanged;

  const DistanceSliderWidget({
    super.key,
    required this.title,
    required this.distanceIndex,
    required this.presetDistances,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title),
        Slider(
          value: distanceIndex.toDouble(),
          min: 0,
          max: (presetDistances.length - 1).toDouble(),
          divisions: presetDistances.length - 1,
          label: presetDistances[distanceIndex].toString(),
          onChanged: (value) => onChanged(value.toInt()),
        ),
      ],
    );
  }
}

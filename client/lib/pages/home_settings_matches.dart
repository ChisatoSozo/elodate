import 'package:client/api/pkg/lib/api.dart';
import 'package:flutter/material.dart';

class UserPreferenceForm extends StatefulWidget {
  const UserPreferenceForm({super.key});

  @override
  UserPreferenceFormState createState() => UserPreferenceFormState();
}

class UserPreferenceFormState extends State<UserPreferenceForm> {
  RangeValues _ageRange = const RangeValues(18, 100);
  RangeValues _latitudeRange = const RangeValues(0, 65535);
  RangeValues _longitudeRange = const RangeValues(0, 65535);
  RangeValues _percentFemaleRange = const RangeValues(0, 100);
  RangeValues _percentMaleRange = const RangeValues(0, 100);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildRangeSlider(
            title: 'Age Range',
            rangeValues: _ageRange,
            min: 18,
            max: 100,
            onChanged: (values) {
              setState(() {
                _ageRange = values;
              });
            },
          ),
          _buildRangeSlider(
            title: 'Latitude Range',
            rangeValues: _latitudeRange,
            min: 0,
            max: 65535,
            onChanged: (values) {
              setState(() {
                _latitudeRange = values;
              });
            },
          ),
          _buildRangeSlider(
            title: 'Longitude Range',
            rangeValues: _longitudeRange,
            min: 0,
            max: 65535,
            onChanged: (values) {
              setState(() {
                _longitudeRange = values;
              });
            },
          ),
          _buildRangeSlider(
            title: 'Percent Female',
            rangeValues: _percentFemaleRange,
            min: 0,
            max: 100,
            onChanged: (values) {
              setState(() {
                _percentFemaleRange = values;
              });
            },
          ),
          _buildRangeSlider(
            title: 'Percent Male',
            rangeValues: _percentMaleRange,
            min: 0,
            max: 100,
            onChanged: (values) {
              setState(() {
                _percentMaleRange = values;
              });
            },
          ),
          ElevatedButton(
            onPressed: () {
              final preferences = UserWithImagesUserPreference(
                age: UserWithImagesUserPreferenceAge(
                    min: _ageRange.start.toInt(), max: _ageRange.end.toInt()),
                latitude: UserWithImagesUserPreferenceAge(
                    min: _latitudeRange.start.toInt(),
                    max: _latitudeRange.end.toInt()),
                longitude: UserWithImagesUserPreferenceAge(
                    min: _longitudeRange.start.toInt(),
                    max: _longitudeRange.end.toInt()),
                percentFemale: UserWithImagesUserPreferenceAge(
                    min: _percentFemaleRange.start.toInt(),
                    max: _percentFemaleRange.end.toInt()),
                percentMale: UserWithImagesUserPreferenceAge(
                    min: _percentMaleRange.start.toInt(),
                    max: _percentMaleRange.end.toInt()),
              );

              // Do something with the preferences
              print('Preferences: $preferences');
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildRangeSlider({
    required String title,
    required RangeValues rangeValues,
    required double min,
    required double max,
    required ValueChanged<RangeValues> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title),
        RangeSlider(
          values: rangeValues,
          min: min,
          max: max,
          divisions: 100,
          labels: RangeLabels(
            rangeValues.start.round().toString(),
            rangeValues.end.round().toString(),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

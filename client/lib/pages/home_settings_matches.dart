import 'package:client/api/pkg/lib/api.dart';
import 'package:client/models/home_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UserPreferenceForm extends StatefulWidget {
  const UserPreferenceForm({super.key});

  @override
  UserPreferenceFormState createState() => UserPreferenceFormState();
}

class UserPreferenceFormState extends State<UserPreferenceForm> {
  RangeValues _ageRange = const RangeValues(18, 100);
  RangeValues _latitudeRange = const RangeValues(-32768, 32767);
  RangeValues _longitudeRange = const RangeValues(-32768, 32767);
  RangeValues _percentFemaleRange = const RangeValues(0, 100);
  RangeValues _percentMaleRange = const RangeValues(0, 100);

  int numUsersIPrefer = 0;
  int numUsersMutuallyPrefer = 0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text('Number of users I prefer: $numUsersIPrefer'),
          Text('Number of users that mutually prefer: $numUsersMutuallyPrefer'),
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
            min: -32768,
            max: 32767,
            onChanged: (values) {
              setState(() {
                _latitudeRange = values;
              });
            },
          ),
          _buildRangeSlider(
            title: 'Longitude Range',
            rangeValues: _longitudeRange,
            min: -32768,
            max: 32767,
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
              final preference = Preference(
                age: PreferenceAge(
                    min: _ageRange.start.toInt(), max: _ageRange.end.toInt()),
                latitude: PreferenceAge(
                    min: _latitudeRange.start.toInt(),
                    max: _latitudeRange.end.toInt()),
                longitude: PreferenceAge(
                    min: _longitudeRange.start.toInt(),
                    max: _longitudeRange.end.toInt()),
                percentFemale: PreferenceAge(
                    min: _percentFemaleRange.start.toInt(),
                    max: _percentFemaleRange.end.toInt()),
                percentMale: PreferenceAge(
                    min: _percentMaleRange.start.toInt(),
                    max: _percentMaleRange.end.toInt()),
              );

              Provider.of<HomeModel>(context, listen: false)
                  .getNumUsersIPreferDryRun(preference)
                  .then((value) => {
                        setState(() {
                          numUsersIPrefer = value;
                        })
                      });

              Provider.of<HomeModel>(context, listen: false)
                  .getNumUsersMutuallyPreferDryRun(preference)
                  .then((value) => setState(() {
                        numUsersMutuallyPrefer = value;
                      }));
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

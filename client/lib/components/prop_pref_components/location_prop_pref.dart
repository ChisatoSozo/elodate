import 'dart:async';
import 'dart:math';

import 'package:client/api/pkg/lib/api.dart';
import 'package:client/models/user_model.dart';
import 'package:client/utils/prefs_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:js/js.dart';
import 'package:provider/provider.dart';

const double minLat = -90.0;
const double maxLat = 90.0;
const double minLon = -180.0;
const double maxLon = 180.0;

int calculateInitialDistance(
    List<ApiUserPropsInner> props, List<ApiUserPrefsInner> prefs) {
  var lat = getPropByName(props, "latitude").value;
  var lng = getPropByName(props, "longitude").value;
  var latPref = getPrefByName(prefs, "latitude").range;
  var lngPref = getPrefByName(prefs, "longitude").range;
  final userLatLng = decodeLatLongFromI16(lat, lng);
  final preferenceMinLatLng = decodeLatLongFromI16(latPref.min, lngPref.min);
  final preferenceMaxLatLng = decodeLatLongFromI16(latPref.max, lngPref.max);

  double deltaLat = (preferenceMaxLatLng.$1 - preferenceMinLatLng.$1) / 2;
  double deltaLng = (preferenceMaxLatLng.$2 - preferenceMinLatLng.$2) / 2;

  const double earthRadiusKm = 6371.0;
  double distance = sqrt(pow(deltaLat * pi / 180 * earthRadiusKm, 2) +
      pow(deltaLng * pi / 180 * earthRadiusKm * cos(userLatLng.$1 * pi / 180),
          2));

  return distance.round();
}

int findClosestDistanceIndex(int distance, List<int> presetDistances) {
  //go through each ajacent pair of distances and find the one that is closest to the distance
  int closestDistanceIndex = 0;
  double closestDistance = double.infinity;
  for (int i = 0; i < presetDistances.length - 1; i++) {
    int currentDistance = presetDistances[i];
    int nextDistance = presetDistances[i + 1];
    if (distance >= currentDistance && distance <= nextDistance) {
      double currentDistanceDiff =
          (distance - currentDistance).abs().toDouble();
      double nextDistanceDiff = (distance - nextDistance).abs().toDouble();
      if (currentDistanceDiff < nextDistanceDiff) {
        if (currentDistanceDiff < closestDistance) {
          closestDistanceIndex = i;
          closestDistance = currentDistanceDiff;
        }
      } else {
        if (nextDistanceDiff < closestDistance) {
          closestDistanceIndex = i + 1;
          closestDistance = nextDistanceDiff;
        }
      }
    }
  }

  return closestDistanceIndex;
}

(ApiUserPrefsInnerRange, ApiUserPrefsInnerRange) getLatLngRange(
  List<ApiUserPropsInner> props,
  int distanceInKm,
) {
  var lat = getPropByName(props, "latitude").value;
  var lng = getPropByName(props, "longitude").value;

  final userLatLng = decodeLatLongFromI16(lat, lng);

  const double earthRadiusKm = 6371.0;

  double deltaLat = distanceInKm / earthRadiusKm;
  double deltaLng =
      distanceInKm / (earthRadiusKm * cos(userLatLng.$1 * pi / 180));

  double minLat = userLatLng.$1 - deltaLat * 180 / pi;
  double maxLat = userLatLng.$1 + deltaLat * 180 / pi;
  double minLng = userLatLng.$2 - deltaLng * 180 / pi;
  double maxLng = userLatLng.$2 + deltaLng * 180 / pi;

  final minLatLng = encodeLatLongToI16(minLat, minLng);
  final maxLatLng = encodeLatLongToI16(maxLat, maxLng);

  return (
    ApiUserPrefsInnerRange(min: minLatLng.$1, max: maxLatLng.$1),
    ApiUserPrefsInnerRange(min: minLatLng.$2, max: maxLatLng.$2)
  );
}

(int, int) encodeLatLongToI16(double lat, double lon) {
  int quantizedLat = encodeToI16(lat, minLat, maxLat, null, null);
  int quantizedLon = encodeToI16(lon, minLon, maxLon, null, null);
  return (quantizedLat, quantizedLon);
}

(double, double) decodeLatLongFromI16(int quantizedLat, int quantizedLon) {
  double decodedLat = decodeFromI16(quantizedLat, minLat, maxLat, null, null);
  double decodedLon = decodeFromI16(quantizedLon, minLon, maxLon, null, null);
  return (decodedLat, decodedLon);
}

@JS('getCurrentLocation')
external void _getCurrentLocation(
    void Function(double lat, double lon) successCallback,
    void Function(String errorMessage) errorCallback);

Future<Map<String, double>?> getCurrentPosition() async {
  Completer<Map<String, double>?> completer = Completer();

  _getCurrentLocation(
    allowInterop((double lat, double lon) {
      completer.complete({'latitude': lat, 'longitude': lon});
    }),
    allowInterop((String errorMessage) {
      completer.complete(null);
    }),
  );

  return completer.future;
}

class LocationPicker extends StatefulWidget {
  final List<ApiUserPropsInner> props;
  final List<PreferenceConfigPublic> preferenceConfigs;
  final Function(List<ApiUserPropsInner>) onUpdated;

  const LocationPicker({
    super.key,
    required this.props,
    required this.preferenceConfigs,
    required this.onUpdated,
  });

  @override
  LocationPickerState createState() => LocationPickerState();
}

class LocationPickerState extends State<LocationPicker> {
  late double latitude;
  late double longitude;
  String? locationError;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.props.length != 2) {
      throw Exception('LocationPicker requires exactly two props');
    }
    if (widget.preferenceConfigs.length != 2) {
      throw Exception('LocationPicker requires exactly one preference config');
    }

    //get double from i16 input
    var (lat, lon) =
        decodeLatLongFromI16(widget.props[0].value, widget.props[1].value);

    latitude = lat;
    longitude = lon;
  }

  Future<void> _getCurrentPosition() async {
    setState(() {
      isLoading = true;
      locationError = null;
    });

    if (kIsWeb) {
      var position = await getCurrentPosition();
      if (position == null) {
        setState(() {
          locationError = 'Failed to get location';
        });
      } else {
        var newLatitude = position['latitude']!;
        var newLongitude = position['longitude']!;

        _updateLocation(newLatitude, newLongitude);
      }
    } else {
      _determinePosition();
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        locationError = 'Location services are disabled.';
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          locationError = 'Location permissions are denied';
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        locationError =
            'Location permissions are permanently denied, we cannot request permissions.';
      });
      return;
    }

    try {
      var position = await Geolocator.getCurrentPosition();

      var newLatitude = position.latitude;
      var newLongitude = position.longitude;

      _updateLocation(newLatitude, newLongitude);
    } catch (e) {
      setState(() {
        locationError = 'Failed to get location: ${e.toString()}';
      });
    }
  }

  void _updateLocation(double newLatitude, double newLongitude) {
    setState(() {
      latitude = newLatitude;
      longitude = newLongitude;
    });

    //connvert to int
    var (lat, lon) = encodeLatLongToI16(latitude, longitude);

    widget.props[0].value = lat;
    widget.props[1].value = lon;
    widget.onUpdated(widget.props);
  }

  @override
  Widget build(BuildContext context) {
    var unset = latitude == -90.0 && longitude == -180.0;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (locationError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                locationError!,
                style: const TextStyle(color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          if (isLoading) const CircularProgressIndicator(),
          if (!isLoading) ...[
            ...(!unset
                ? [
                    Text(
                      'Latitude: ${latitude.toStringAsFixed(3)}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      'Longitude: ${longitude.toStringAsFixed(3)}',
                      style: Theme.of(context).textTheme.titleMedium,
                    )
                  ]
                : []),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _getCurrentPosition,
              icon: const Icon(Icons.location_on),
              label: const Text('Get Location'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 12.0),
                textStyle: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

const List<int> presetDistances = [1, 2, 5, 10, 20, 50, 100, 250, 500, 12000];

class LocationRangePicker extends StatefulWidget {
  final List<ApiUserPrefsInner> prefs;
  final List<PreferenceConfigPublic> preferenceConfigs;
  final Function(List<ApiUserPrefsInner>) onUpdated;

  const LocationRangePicker({
    required this.prefs,
    required this.preferenceConfigs,
    required this.onUpdated,
    super.key,
  });

  @override
  LocationRangePickerState createState() => LocationRangePickerState();
}

class LocationRangePickerState extends State<LocationRangePicker> {
  late int selectedDistanceIndex;
  late int selectedDistance;

  @override
  void initState() {
    super.initState();
    var userModel = Provider.of<UserModel>(context, listen: false);
    var user = userModel.me;
    selectedDistanceIndex = findClosestDistanceIndex(
        calculateInitialDistance(user.props, widget.prefs), presetDistances);
    selectedDistance = presetDistances[selectedDistanceIndex];
  }

  void _onSliderChanged(double value, ApiUser user) {
    setState(() {
      selectedDistanceIndex = value.round();
      selectedDistance = presetDistances[selectedDistanceIndex];
    });

    var (latRange, lngRange) = getLatLngRange(user.props, selectedDistance);

    widget.prefs.first.range = latRange;
    widget.prefs.last.range = lngRange;
    widget.onUpdated(widget.prefs);
  }

  @override
  Widget build(BuildContext context) {
    var userModel = Provider.of<UserModel>(context, listen: false);
    var user = userModel.me;

    var isEarth = selectedDistance == 12000;

    var message = isEarth
        ? 'Anywhere on Earth'
        : 'Within $selectedDistance km of your location';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Slider(
          value: selectedDistanceIndex.toDouble(),
          min: 0,
          max: (presetDistances.length - 1).toDouble(),
          divisions: presetDistances.length - 1,
          label: '${presetDistances[selectedDistanceIndex]} km',
          onChanged: (value) => _onSliderChanged(value, user),
        ),
        Text(
          message,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }
}

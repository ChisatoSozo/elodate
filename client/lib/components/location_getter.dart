import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:js/js.dart';

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

class LocationController extends ValueNotifier<(double, double)> {
  LocationController({required double latitude, required double longitude})
      : super((latitude, longitude));

  void updateValues(double latitude, double longitude) {
    value = (latitude, longitude);
  }
}

class LocationPicker extends StatefulWidget {
  final LocationController controller;
  final Function(double, double) onUpdate;

  const LocationPicker({
    super.key,
    required this.controller,
    required this.onUpdate,
  });

  @override
  LocationPickerState createState() => LocationPickerState();
}

class LocationPickerState extends State<LocationPicker> {
  String? locationError;
  bool isLoading = false;

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
        var latitude = position['latitude']!;
        var longitude = position['longitude']!;

        widget.controller.updateValues(latitude, longitude);
        widget.onUpdate(latitude, longitude);
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

      var latitude = position.latitude;
      var longitude = position.longitude;

      widget.controller.updateValues(latitude, longitude);
      widget.onUpdate(latitude, longitude);
    } catch (e) {
      setState(() {
        locationError = 'Failed to get location: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
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
          Text(
            'Latitude: ${widget.controller.value.$1.toStringAsFixed(3)}',
            style: const TextStyle(fontSize: 18),
          ),
          Text(
            'Longitude: ${widget.controller.value.$2.toStringAsFixed(3)}',
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _getCurrentPosition,
            icon: const Icon(Icons.location_on),
            label: const Text('Get Location'),
            style: ElevatedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              textStyle: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ],
    );
  }
}

class LocationPickerFormField extends FormField<(double, double)> {
  LocationPickerFormField({
    super.key,
    required LocationController controller,
    required FormFieldSetter<(double, double)> onSaved,
    required void Function((double, double)?) onChanged,
    super.validator,
    AutovalidateMode autovalidateMode = AutovalidateMode.disabled,
  }) : super(
          initialValue: controller.value,
          onSaved: onSaved,
          builder: (FormFieldState<(double, double)> state) {
            return Column(
              children: <Widget>[
                LocationPicker(
                  controller: controller,
                  onUpdate: (double newLatitude, double newLongitude) {
                    state.didChange((newLatitude, newLongitude));
                    onChanged((newLatitude, newLongitude));
                  },
                ),
                if (state.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      state.errorText ?? '',
                      style: TextStyle(
                        color: Theme.of(state.context).colorScheme.error,
                        fontSize: 12.0,
                      ),
                    ),
                  ),
              ],
            );
          },
        );
}

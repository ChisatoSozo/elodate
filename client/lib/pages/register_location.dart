@JS()
library location;

import 'dart:async';

import 'package:client/components/responseive_scaffold.dart';
import 'package:client/models/register_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:js/js.dart';
import 'package:provider/provider.dart';

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

class RegisterLocationPage extends StatefulWidget {
  const RegisterLocationPage({super.key});

  @override
  RegisterLocationPageState createState() => RegisterLocationPageState();
}

class RegisterLocationPageState extends State<RegisterLocationPage> {
  final TextEditingController nameController = TextEditingController();
  String? locationError;
  double latitude = 0;
  double longitude = 0;

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: latitude == 0 && longitude == 0
          ? 'Getting your location...'
          : 'Got your location',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (locationError != null)
            Column(
              children: [
                Text(
                  locationError!,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _multiplatformGetCurrentPosition,
                  child: const Text('Retry'),
                ),
              ],
            ),

          const SizedBox(height: 20),
          //location first 3 digits
          Text('Latitude: ${latitude.toStringAsFixed(3)}'),
          Text('Longitude: ${longitude.toStringAsFixed(3)}'),
          if (latitude != 0 && longitude != 0) ...[
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => {
                Provider.of<RegisterModel>(context, listen: false)
                    .setLocation(latitude, longitude),
                nextPage(context, widget)
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Next'),
                  Icon(Icons.arrow_forward),
                ],
              ),
            )
          ],
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _multiplatformGetCurrentPosition();
  }

  Future<void> _multiplatformGetCurrentPosition() async {
    if (kIsWeb) {
      var position = await getCurrentPosition();
      if (position == null) {
        setState(() {
          locationError = 'Failed to get location';
        });
      }
      setState(() {
        latitude = position!['latitude']!;
        longitude = position['longitude']!;
      });
    } else {
      _determinePosition();
    }
  }

  Future<void> _determinePosition() async {
    setState(() {
      locationError = null; // Clear previous error messages
    });

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
      setState(() {
        latitude = position.latitude;
        longitude = position.longitude;
      });
    } catch (e) {
      setState(() {
        locationError = 'Failed to get location: ${e.toString()}';
      });
    }
  }
}

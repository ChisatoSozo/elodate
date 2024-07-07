import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';

class LocationModal extends StatefulWidget {
  //update location callback
  final void Function(double lat, double lng) onLocationUpdate;

  const LocationModal({super.key, required this.onLocationUpdate});

  @override
  LocationModalState createState() => LocationModalState();
}

class LocationModalState extends State<LocationModal>
    with SingleTickerProviderStateMixin {
  MapController mapController = MapController();
  LatLng? tappedPoint;
  late AnimationController _animationController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 0.9), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.1), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 0.95), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.05), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void onClick(dynamic _, LatLng point) {
    widget.onLocationUpdate(point.latitude, point.longitude);
    setState(() {
      tappedPoint = point;
    });
    _animationController.reset();
    _animationController.forward();
  }

  void onConfirm() {
    if (tappedPoint != null) {
      widget.onLocationUpdate(tappedPoint!.latitude, tappedPoint!.longitude);
      Navigator.of(context).pop(tappedPoint);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: mapController,
          options: MapOptions(
            initialCenter: const LatLng(37.0902, -95.7129),
            initialZoom: 3.0,
            onPointerUp: onClick,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              tileProvider: CancellableNetworkTileProvider(),
            ),
            MarkerLayer(markers: [
              if (tappedPoint != null)
                Marker(
                  width: 40.0,
                  height: 58.0,
                  point: tappedPoint!,
                  child: AnimatedBuilder(
                    animation: _bounceAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: const Offset(0, -18),
                        child: Transform.scale(
                          scale: _bounceAnimation.value,
                          alignment: Alignment.bottomCenter,
                          child: const Icon(
                            Icons.location_on,
                            size: 40.0,
                            color: Colors.red,
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ]),
          ],
        ),
        // title at the top center, backed by a card
        Positioned(
          top: 16,
          left: 0,
          right: 0,
          child: Center(
            child: Card(
              //select your location with padding
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  tappedPoint != null
                      ? 'Selected Location: ${tappedPoint!.latitude.toStringAsFixed(3)}, ${tappedPoint!.longitude.toStringAsFixed(3)}'
                      : 'Select your location',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          right: 16,
          bottom: 100,
          child: Column(
            children: [
              FloatingActionButton(
                heroTag: "zoomIn",
                onPressed: () {
                  mapController.move(mapController.camera.center,
                      mapController.camera.zoom + 1);
                },
                child: const Icon(Icons.add),
              ),
              const SizedBox(height: 16),
              FloatingActionButton(
                heroTag: "zoomOut",
                onPressed: () {
                  mapController.move(mapController.camera.center,
                      mapController.camera.zoom - 1);
                },
                child: const Icon(Icons.remove),
              ),
            ],
          ),
        ),
        //button at bottom center
        Positioned(
          bottom: 16,
          left: 0,
          right: 0,
          child: Center(
            child: ElevatedButton(
              onPressed: tappedPoint != null ? onConfirm : null,
              child: Text(
                tappedPoint != null
                    ? 'Confirm Location'
                    : 'Select your location',
              ),
            ),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

class LocationModal extends StatefulWidget {
  const LocationModal({super.key});

  @override
  LocationModalState createState() => LocationModalState();
}

class LocationModalState extends State<LocationModal> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: const Column(
        children: [
          Text('Location Modal'),
        ],
      ),
    );
  }
}

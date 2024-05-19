import 'package:client/components/location_getter.dart';
import 'package:client/components/responseive_scaffold.dart';
import 'package:client/models/register_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RegisterLocationPage extends StatefulWidget {
  const RegisterLocationPage({super.key});

  @override
  RegisterLocationPageState createState() => RegisterLocationPageState();
}

class RegisterLocationPageState extends State<RegisterLocationPage> {
  final TextEditingController nameController = TextEditingController();
  final LocationController locationController =
      LocationController(latitude: 0, longitude: 0);

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: 'Register Location',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          LocationPickerFormField(
            controller: locationController,
            onSaved: (location) {
              if (location == null) {
                return;
              }
              Provider.of<RegisterModel>(context, listen: false)
                  .setLocation(location.$1, location.$2);
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Provider.of<RegisterModel>(context, listen: false).setLocation(
                  locationController.value.$1, locationController.value.$2);
              nextPage(context, widget);
            },
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Next'),
                Icon(Icons.arrow_forward),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

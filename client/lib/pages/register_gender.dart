import 'package:client/components/gender_picker.dart';
import 'package:client/components/responseive_scaffold.dart';
import 'package:client/models/register_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RegisterGenderPage extends StatefulWidget {
  const RegisterGenderPage({super.key});

  @override
  RegisterGenderPageState createState() => RegisterGenderPageState();
}

class RegisterGenderPageState extends State<RegisterGenderPage> {
  late GenderPickerController _genderPickerController;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Initialize the GenderPickerController with default values
    _genderPickerController =
        GenderPickerController(percentMale: 1.0, percentFemale: 0.0);
  }

  @override
  void dispose() {
    _genderPickerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: ResponsiveScaffold(
        title: "Select your gender:",
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            GenderPicker(
              controller: _genderPickerController,
              onUpdate: (_, __) {},
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveGenderAndProceed,
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
      ),
    );
  }

  void _saveGenderAndProceed() {
    Provider.of<RegisterModel>(context, listen: false).setGenderPercentages(
      _genderPickerController.value.$1,
      _genderPickerController.value.$2,
    );
    nextPage(context, widget);
  }
}

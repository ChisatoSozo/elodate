import 'package:client/components/responsive_scaffold.dart';
import 'package:client/models/register_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RegisterNamePage extends StatefulWidget {
  const RegisterNamePage({super.key});

  @override
  RegisterNamePageState createState() => RegisterNamePageState();
}

class RegisterNamePageState extends State<RegisterNamePage> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: "What should we call you?",
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
              onFieldSubmitted: (_) => _saveNameAndProceed(
                nameController.text,
              ),
              validator: (value) =>
                  value!.isEmpty ? 'Name cannot be empty' : null,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _saveNameAndProceed(
                nameController.text,
              ),
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

  _saveNameAndProceed(String name) {
    if (!formKey.currentState!.validate()) return;

    Provider.of<RegisterModel>(context, listen: false).setDisplayName(name);
    nextPage(context, widget);
  }
}

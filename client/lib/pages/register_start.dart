import 'package:client/models/user_model.dart';
import 'package:client/pages/register_username.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RegisterStartPage extends StatefulWidget {
  const RegisterStartPage({super.key});

  @override
  RegisterStartPageState createState() => RegisterStartPageState();
}

class RegisterStartPageState extends State<RegisterStartPage> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text("What should we call you?",
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 20),
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
        ),
      ),
    );
  }

  _saveNameAndProceed(String name) {
    if (!formKey.currentState!.validate()) return;

    Provider.of<UserModel>(context, listen: false).setName(name);

    // Save the name and proceed to the next step
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RegisterUsernamePage(),
      ),
    );
  }
}
import 'package:client/api/pkg/lib/api.dart';
import 'package:client/models/user_model.dart';
import 'package:client/pages/register_password.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RegisterUsernamePage extends StatefulWidget {
  const RegisterUsernamePage({super.key});

  @override
  RegisterUsernamePageState createState() => RegisterUsernamePageState();
}

class RegisterUsernamePageState extends State<RegisterUsernamePage> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController usernameController = TextEditingController();

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
                Text(
                    "Hello ${Provider.of<RegisterModel>(context).displayName}, pick a username",
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 20),
                TextFormField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                  onFieldSubmitted: (value) => _goNext(),
                  validator: (value) =>
                      value!.isEmpty ? 'Name cannot be empty' : null,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _goNext,
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

  Future<void> _goNext() async {
    if (!formKey.currentState!.validate()) return;

    var valid = await _validateUsername(usernameController.text);
    if (!mounted) return;

    if (valid) {
      // Proceed to the next step
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  const RegisterPasswordPage())); // Update with actual next page
    } else {
      // Show error if username validation fails
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Username is already taken, please choose another one.')),
      );
    }
  }

  Future<bool> _validateUsername(String username) async {
    try {
      var response = await DefaultApi()
          .checkUsernamePost(CheckUsernameInput(username: username));

      if (response != null && response.available) {
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

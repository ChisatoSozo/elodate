import 'package:client/api/pkg/lib/api.dart';
import 'package:client/components/responseive_scaffold.dart';
import 'package:client/models/register_model.dart';
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
    return ResponsiveScaffold(
      title:
          "Hello ${Provider.of<RegisterModel>(context).displayName}, pick a username for logging in.",
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
              onFieldSubmitted: (value) => _goNext(),
              validator: (value) =>
                  value!.isEmpty ? 'Username cannot be empty' : null,
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
    );
  }

  Future<void> _goNext() async {
    if (!formKey.currentState!.validate()) return;

    late bool valid;
    try {
      valid = await _validateUsername(usernameController.text);
    } catch (e) {
      if (!mounted) return;

      String errorMessage = 'An error occurred, please try again later.';
      if (e is ApiException) {
        errorMessage = 'An error occurred: ${e.message}';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
      return;
    }

    if (!mounted) return;

    if (valid) {
      Provider.of<RegisterModel>(context, listen: false)
          .setUsername(usernameController.text);
      nextPage(context, widget);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Username is already taken, please choose another one.')),
      );
    }
  }

  Future<bool> _validateUsername(String username) async {
    var response =
        await DefaultApi(ApiClient(basePath: 'http://localhost:8080'))
            .checkUsernamePost(CheckUsernameInput(username: username));

    return response != null && response.available;
  }
}

import 'package:client/api/pkg/lib/api.dart';
import 'package:client/components/responseive_scaffold.dart';
import 'package:client/models/home_model.dart';
import 'package:client/models/register_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RegisterStartPage extends StatefulWidget {
  const RegisterStartPage({super.key});

  @override
  RegisterStartPageState createState() => RegisterStartPageState();
}

class RegisterStartPageState extends State<RegisterStartPage> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController usernameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: "Hello! Pick a username for logging in.",
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
    var response = await constructClient(null)
        .checkUsernamePost(CheckUsernameInput(username: username));

    return response != null && response.available;
  }
}

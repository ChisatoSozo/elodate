import 'package:client/api/pkg/lib/api.dart';
import 'package:client/models/register_model.dart';
import 'package:client/models/user_model.dart';
import 'package:client/router/elo_router_nav.dart';
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
  final TextEditingController displayNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    var username = Provider.of<RegisterModel>(context, listen: false).username;
    //if it's set, initialize the controller
    if (username != null) {
      usernameController.text = username;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Account Setup",
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          Text(
            "Choose a unique username for your account:",
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: usernameController,
            decoration: const InputDecoration(
              labelText: 'Username',
              hintText: 'Used for login and mentions',
              border: OutlineInputBorder(),
            ),
            validator: (value) =>
                value!.isEmpty ? 'Username cannot be empty' : null,
          ),
          const SizedBox(height: 20),
          Text(
            "Enter your display name:",
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: displayNameController,
            decoration: const InputDecoration(
              labelText: 'Display Name',
              hintText: 'Name shown to other users',
              border: OutlineInputBorder(),
            ),
            validator: (value) =>
                value!.isEmpty ? 'Display name cannot be empty' : null,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: _submitForm,
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
        ],
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!formKey.currentState!.validate()) return;

    try {
      bool usernameValid = await _validateUsername(usernameController.text);
      if (!usernameValid) {
        _showErrorSnackBar(
            'Username is already taken, please choose another one.');
        return;
      }

      if (!mounted) return;

      // Save both username and display name
      Provider.of<RegisterModel>(context, listen: false)
          .setUsername(usernameController.text);
      Provider.of<RegisterModel>(context, listen: false)
          .setDisplayName(displayNameController.text);

      // Proceed to the next page or complete registration
      EloNav.goRegisterPassword(context);
    } catch (e) {
      if (!mounted) return;

      String errorMessage = 'An error occurred, please try again later.';
      if (e is ApiException) {
        errorMessage = 'An error occurred: ${e.message}';
      }
      _showErrorSnackBar(errorMessage);
    }
  }

  Future<bool> _validateUsername(String username) async {
    var response = await constructClient(null)
        .checkUsernamePost(CheckUsernameInput(username: username));

    return response != null && response.available;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

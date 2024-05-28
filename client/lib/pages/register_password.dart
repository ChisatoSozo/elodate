import 'package:client/components/responsive_scaffold.dart';
import 'package:client/models/register_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RegisterPasswordPage extends StatefulWidget {
  const RegisterPasswordPage({super.key});

  @override
  RegisterPasswordPageState createState() => RegisterPasswordPageState();
}

class RegisterPasswordPageState extends State<RegisterPasswordPage> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isPasswordValid(String password) {
    // Implement your own password validation logic
    //password must be at least 8 characters long
    return password.length >= 8;
  }

  bool _isPasswordConfirmed() {
    return _passwordController.text == _confirmPasswordController.text;
  }

  void _submit() {
    if (formKey.currentState?.validate() ?? false) {
      Provider.of<RegisterModel>(context, listen: false)
          .setPassword(_passwordController.text);

      nextPage(context, widget);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: 'Pick a password. If it sucks and you get hacked that\'s on you.',
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                hintText: 'Enter your password',
              ),
              validator: (value) {
                if (value == null ||
                    value.isEmpty ||
                    !_isPasswordValid(value)) {
                  return 'Password must be at least 8 characters long';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
                hintText: 'Confirm your password',
              ),
              validator: (value) {
                if (value == null ||
                    value.isEmpty ||
                    !_isPasswordValid(value) ||
                    !_isPasswordConfirmed()) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _submit,
              child: const Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}

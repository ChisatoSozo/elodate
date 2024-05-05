import 'package:client/models/register_model.dart';
import 'package:client/pages/register_images.dart';
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
    //password must be at least 8 characters long, contain at least one uppercase letter, one lowercase letter, one number, and one special character
    final passwordRegExp = RegExp(
        r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*()_+{}|:<>?]).{8,}$');
    return passwordRegExp.hasMatch(password);
  }

  bool _isPasswordConfirmed() {
    return _passwordController.text == _confirmPasswordController.text;
  }

  void _submit() {
    if (formKey.currentState?.validate() ?? false) {
      Provider.of<RegisterModel>(context, listen: false)
          .setPassword(_passwordController.text);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const RegisterImagesPage(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Password'),
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          constraints: const BoxConstraints(maxWidth: 400),
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
                      return 'Password must be at least 8 characters long, contain at least one uppercase letter, one lowercase letter, one number, and one special character';
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
        ),
      ),
    );
  }
}

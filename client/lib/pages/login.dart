import 'package:client/components/custom_form_field.dart';
import 'package:client/components/spacer.dart';
import 'package:client/models/register_model.dart';
import 'package:client/router/elo_router_nav.dart';
import 'package:client/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loggingIn = false;
  String? _error;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loggingIn = true;
      _error = null;
    });

    try {
      await Provider.of<RegisterModel>(context, listen: false)
          .login(_usernameController.text, _passwordController.text, context);
      if (!mounted) return;
      EloNav.goRedir(context);
    } catch (e) {
      setState(() {
        _error = formatApiError(e.toString());
      });
    } finally {
      if (mounted) {
        setState(() {
          _loggingIn = false;
        });
      }
    }
  }

  void _goToRegister() {
    if (_usernameController.text.isNotEmpty) {
      Provider.of<RegisterModel>(context, listen: false)
          .setUsername(_usernameController.text);
    }
    if (_passwordController.text.isNotEmpty) {
      Provider.of<RegisterModel>(context, listen: false)
          .setPassword(_passwordController.text);
    }
    EloNav.goRegister(context);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: AutofillGroup(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              Theme.of(context).brightness == Brightness.dark
                  ? 'images/icon_text_white.png'
                  : 'images/icon_text.png',
              width: 300,
              height: 300,
            ),
            const VerticalSpacer(),
            CustomFormField(
              controller: _usernameController,
              labelText: 'Username',
              validator: (value) =>
                  value!.isEmpty ? 'Please enter your username' : null,
              keyboardType: TextInputType.text,
            ),
            const VerticalSpacer(),
            CustomFormField(
              controller: _passwordController,
              labelText: 'Password',
              obscureText: true,
              validator: (value) =>
                  value!.isEmpty ? 'Please enter your password' : null,
            ),
            if (_error != null) ...[
              const VerticalSpacer(),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ],
            const VerticalSpacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _goToRegister,
                  child: const Text('Register'),
                ),
                ElevatedButton(
                  onPressed: _loggingIn ? null : _login,
                  child: _loggingIn
                      ? const CircularProgressIndicator()
                      : const Text('Login'),
                ),
              ],
            ),
            const VerticalSpacer(),
            const Text(
              "Welcome to the Elodate alpha! 🚀\n\n"
              "To get the most out of this early version:\n"
              "1. Set your own properties (sliders) ✅\n"
              "2. Leave most preferences (ranges) unset for now ⏳\n"
              "3. Set your location preference to 'Global' 🌍\n\n"
              "Expect bugs - we're still growing! 🐛\n"
              "Found an issue or have a suggestion? Tap the button in the top left to let us know. Your input shapes Elodate's future!\n\n"
              "Thank you for being an early adopter! 💖",
              textAlign: TextAlign.center,
            ),
            const VerticalSpacer(),
          ],
        ),
      ),
    );
  }
}

import 'package:client/models/register_model.dart';
import 'package:client/router.dart';
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
      EloNav.goHomeSwipe();
    } catch (e) {
      setState(() {
        _error = formatApiError(e.toString());
      });
    } finally {
      setState(() {
        _loggingIn = false;
      });
    }
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
            const SizedBox(height: 20),
            TextFormField(
              controller: _usernameController,
              autofillHints: const [AutofillHints.username],
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value!.isEmpty ? 'Please enter your username' : null,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _passwordController,
              autofillHints: const [AutofillHints.password],
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  value!.isEmpty ? 'Please enter your password' : null,
            ),
            const SizedBox(height: 20),
            const Text(
              "This is an INDEV build of elodate. You are likely to encounter bugs. Please report them. We have migration now, so your profile (with high likelihood) won't be randomly deleted.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _loggingIn ? null : _login,
                  child: _loggingIn
                      ? const CircularProgressIndicator()
                      : const Text('Login'),
                ),
                ElevatedButton(
                  onPressed: () {
                    //set username if it's already entered
                    if (_usernameController.text.isNotEmpty) {
                      Provider.of<RegisterModel>(context, listen: false)
                          .setUsername(_usernameController.text);
                    }
                    //set password if it's already entered
                    if (_passwordController.text.isNotEmpty) {
                      Provider.of<RegisterModel>(context, listen: false)
                          .setPassword(_passwordController.text);
                    }
                    EloNav.goRegister();
                  },
                  child: const Text('Register'),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 20),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

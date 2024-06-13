import 'package:client/components/report_bug_scaffold.dart';
import 'package:client/models/register_model.dart';
import 'package:client/pages/home.dart';
import 'package:client/pages/register_start.dart';
import 'package:client/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  bool loggingIn = false;
  String? _error;
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: ReportBugScaffold(
        body: Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  //is dark mode? use dark mode icon
                  Theme.of(context).brightness == Brightness.dark
                      ? 'images/icon_text_white.png'
                      : 'images/icon_text.png',
                  width: 300,
                  height: 300,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                    "This is an INDEV build of elodate. You are likely to encounter bugs. Please report them. Also your profile might occasionally be reset/deleted."),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        login(context);
                      },
                      child: const Text('Login'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const RegisterStartPage()),
                        );
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
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> login(BuildContext context) async {
    if (!mounted) return;
    try {
      setState(() {
        loggingIn = true;
      });
      await Provider.of<RegisterModel>(context, listen: false)
          .login(usernameController.text, passwordController.text, context);
      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } catch (e) {
      setState(() {
        _error = formatApiError(e.toString());
      });
    } finally {
      setState(() {
        loggingIn = false;
      });
    }
  }
}

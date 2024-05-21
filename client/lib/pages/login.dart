import 'package:client/models/register_model.dart';
import 'package:client/pages/home.dart';
import 'package:client/pages/register_start.dart';
import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  bool loggingIn = false;
  String? loginError;
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Scaffold(
        body: Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Image.asset(
                  'images/logo.png',
                  height: 100, // Adjust the height as needed
                ),
                const SizedBox(height: 10),
                Text(
                  "elodate",
                  style: Theme.of(context).textTheme.headlineSmall,
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
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
                if (loginError != null) ...[
                  const SizedBox(height: 20),
                  Text(
                    loginError!,
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
      var jwt = await Provider.of<RegisterModel>(context, listen: false).login(
        usernameController.text,
        passwordController.text,
      );
      if (jwt == null) {
        throw Exception('Failed to login');
      }
      localStorage.setItem("jwt", jwt.jwt);
      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } catch (e) {
      setState(() {
        loginError = e.toString();
      });
    } finally {
      setState(() {
        loggingIn = false;
      });
    }
  }
}

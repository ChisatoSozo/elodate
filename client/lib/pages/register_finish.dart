import 'dart:async';

import 'package:client/components/responsive_scaffold.dart';
import 'package:client/models/register_model.dart';
import 'package:flutter/material.dart';
//import local storage package
import 'package:localstorage/localstorage.dart';
import 'package:provider/provider.dart';

class RegisterFinishPage extends StatefulWidget {
  const RegisterFinishPage({super.key});

  @override
  RegisterFinishPageState createState() => RegisterFinishPageState();
}

class RegisterFinishPageState extends State<RegisterFinishPage> {
  final TextEditingController nameController = TextEditingController();
  String? registerError;
  bool registered = false;

  @override
  Widget build(BuildContext context) {
    return ResponsiveForm(
      title: registered
          ? 'Registered'
          : registerError != null
              ? 'Failed to register: $registerError'
              : 'Registering...',
      //retry button
      body: registerError != null
          ? Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      registered = false;
                      registerError = null;
                    });
                    register();
                  },
                  child: const Text('Retry'),
                )
              ],
            )
          : const CircularProgressIndicator(),
    );
  }

  @override
  void initState() {
    super.initState();
    register();
  }

  Future<void> register() async {
    if (!mounted) return;
    try {
      var jwt =
          await Provider.of<RegisterModel>(context, listen: false).register();
      if (jwt == null) {
        throw Exception('Failed to register');
      }

      localStorage.setItem("jwt", jwt.jwt);
      localStorage.setItem("uuid", jwt.uuid);
      setState(() {
        registered = true;
      });
      if (!mounted) return;
      nextPage(context, widget);
    } catch (e) {
      setState(() {
        registerError = e.toString();
      });
    }
  }
}

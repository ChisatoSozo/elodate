import 'dart:async';

import 'package:client/components/loading.dart';
import 'package:client/models/register_model.dart';
import 'package:client/router/elo_router_nav.dart';
import 'package:client/utils/utils.dart';
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
  final TextEditingController _accessCodeController = TextEditingController();
  String? registerError;
  bool registering = false;
  final _formKey = GlobalKey<FormState>();

  //on access code update
  void onAccessCodeUpdate(String value) {
    if (value.length > 4 && !value.contains("-")) {
      _accessCodeController.text =
          "${value.substring(0, 4)}-${value.substring(4)}";
    }

    if (value.length > 9) {
      _accessCodeController.text = value.substring(0, 9);
    }

    _accessCodeController.selection = TextSelection.fromPosition(
        TextPosition(offset: _accessCodeController.text.length));
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return !registering
        ? Form(
            key: _formKey,
            child: Column(
              children: [
                Text(
                  'Enter your alpha access code to finish registration.',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _accessCodeController,
                  decoration: const InputDecoration(
                    labelText: 'Access Code',
                    hintText: 'XXXX-XXXX',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (registerError != null) Text(registerError!),
                const SizedBox(height: 20),
                Row(
                  //align right
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          registering = true;
                          registerError = null;
                        });
                        register();
                      },
                      child: Row(
                        children: [
                          registerError == null
                              ? const Text('Register')
                              : const Text('Retry'),
                          //right arrow icon
                          const Icon(Icons.arrow_forward),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        : const Loading(text: 'Registering...');
  }

  @override
  void initState() {
    super.initState();
    _accessCodeController.addListener(() {
      onAccessCodeUpdate(_accessCodeController.text);
    });
  }

  Future<void> register() async {
    if (!mounted) return;
    try {
      var accessCode = _accessCodeController.text;
      var jwt = await Provider.of<RegisterModel>(context, listen: false)
          .register(accessCode);
      if (jwt == null) {
        throw Exception('Failed to register');
      }

      localStorage.setItem("jwt", jwt.jwt);
      localStorage.setItem("uuid", jwt.uuid);
      setState(() {
        registering = false;
      });
      if (!mounted) return;
      EloNav.goRedir(context);
    } catch (e) {
      setState(() {
        registerError = formatApiError(e.toString());
        setState(() {
          registering = false;
        });
      });
    }
  }
}

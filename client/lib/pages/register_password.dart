import 'package:client/components/custom_form_field.dart';
import 'package:client/components/spacer.dart';
import 'package:client/models/register_model.dart';
import 'package:client/router/elo_router_nav.dart';
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

  @override
  void initState() {
    super.initState();
    var password = Provider.of<RegisterModel>(context, listen: false).password;
    if (password != null) {
      _passwordController.text = password;
      _confirmPasswordController.text = password;
    }
  }

  bool _isPasswordValid(String password) {
    return password.length >= 8;
  }

  bool _isPasswordConfirmed() {
    return _passwordController.text == _confirmPasswordController.text;
  }

  void _submit() {
    if (formKey.currentState?.validate() ?? false) {
      Provider.of<RegisterModel>(context, listen: false)
          .setPassword(_passwordController.text);

      EloNav.goRegisterBirthdate(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return Form(
      key: formKey,
      child: Column(
        children: [
          Text(
            "Pick a Password. If it sucks and you get hacked, that's on you.",
            style: theme.textTheme.titleLarge,
          ),
          const VerticalSpacer(size: SpacerSize.large),
          CustomFormField(
            controller: _passwordController,
            labelText: 'Password',
            hintText: 'Enter your password',
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty || !_isPasswordValid(value)) {
                return 'Password must be at least 8 characters long';
              }
              return null;
            },
          ),
          const VerticalSpacer(),
          CustomFormField(
            controller: _confirmPasswordController,
            labelText: 'Confirm Password',
            hintText: 'Confirm your password',
            obscureText: true,
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
          const VerticalSpacer(size: SpacerSize.large),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: _submit,
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
}

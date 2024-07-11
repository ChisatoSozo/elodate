import 'package:client/components/custom_form_field.dart';
import 'package:client/components/spacer.dart';
import 'package:client/models/register_model.dart';
import 'package:client/router/elo_router_nav.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class RegisterBirthdatePage extends StatefulWidget {
  const RegisterBirthdatePage({super.key});

  @override
  RegisterBirthdatePageState createState() => RegisterBirthdatePageState();
}

class RegisterBirthdatePageState extends State<RegisterBirthdatePage> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController birthdateController = TextEditingController();
  bool dateSelectorHasBeenOpened = false;
  DateTime? selectedDate;

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return Form(
      key: formKey,
      child: Column(
        children: [
          Text(
            'How old are you?',
            style: theme.textTheme.titleLarge,
          ),
          const VerticalSpacer(),
          CustomFormField(
            controller: birthdateController,
            labelText: 'Birthdate (YYYY-MM-DD)',
            onTap: () {
              if (!dateSelectorHasBeenOpened) _selectDate(context);
            },
            validator: _validateBirthdate,
            readOnly: true,
          ),
          const VerticalSpacer(),
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

  Future<void> _selectDate(BuildContext context) async {
    setState(() {
      dateSelectorHasBeenOpened = true;
    });
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        birthdateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  String? _validateBirthdate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Birthdate cannot be empty';
    }
    final date = DateTime.tryParse(value);
    if (date == null) {
      return 'Invalid date format';
    }
    final age = DateTime.now().difference(date).inDays ~/ 365;
    if (age < 18) {
      return 'You must be at least 18 years old';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!formKey.currentState!.validate()) return;

    if (!mounted) return;

    if (selectedDate == null && birthdateController.text.isNotEmpty) {
      selectedDate = DateTime.tryParse(birthdateController.text);
    }

    Provider.of<RegisterModel>(context, listen: false)
        .setBirthdate(selectedDate!.millisecondsSinceEpoch ~/ 1000);
    EloNav.goRegisterFinish(context);
  }
}

import 'package:client/components/elodate_scaffold.dart';
import 'package:flutter/material.dart';

class ResponsiveForm extends StatelessWidget {
  final Widget body;
  final String? title; // Title property
  final double? progress;
  final bool titleAtTop;
  final GlobalKey<FormState>? _formKey;
  final GlobalKey<FormState> _defaultFormKey = GlobalKey<FormState>();

  // Constructor to take children and title as parameters
  ResponsiveForm(
      {super.key,
      required this.body,
      this.progress,
      this.title,
      this.titleAtTop = false,
      GlobalKey<FormState>? formKey})
      : _formKey = formKey;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey ?? _defaultFormKey,
      child: ElodateScaffold(
        appBar: titleAtTop && title != null
            ? AppBar(
                title: Text(title!),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(4.0),
                  child: progress != null
                      ? LinearProgressIndicator(
                          value: progress,
                          minHeight: 4,
                          backgroundColor: Colors.transparent,
                        )
                      : Container(),
                ),
              )
            : null,
        body: Container(
          constraints: const BoxConstraints(
            maxWidth: 400,
          ),
          child: body,
        ),
      ),
    );
  }
}

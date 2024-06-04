import 'package:flutter/material.dart';

class ResponsiveForm extends StatelessWidget {
  final List<Widget> children;
  final String? title; // Title property
  final double? progress;
  final bool titleAtTop;
  final GlobalKey<FormState>? _formKey;
  final GlobalKey<FormState> _defaultFormKey = GlobalKey<FormState>();

  // Constructor to take children and title as parameters
  ResponsiveForm(
      {super.key,
      required this.children,
      this.progress,
      this.title,
      this.titleAtTop = false,
      GlobalKey<FormState>? formKey})
      : _formKey = formKey;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey ?? _defaultFormKey,
      child: Scaffold(
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
        body: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  constraints: BoxConstraints(
                      maxWidth: 400, minHeight: constraints.maxHeight),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (title != null && !titleAtTop) ...[
                          Text(title!,
                              style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 20),
                        ],
                        ...children,
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

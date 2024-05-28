import 'package:flutter/material.dart';

class ResponsiveScaffold extends StatelessWidget {
  final bool scrollable;
  final Widget child;
  final String? title; // Title property
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  // Constructor to take child and title as parameters
  ResponsiveScaffold(
      {super.key,
      required this.child,
      required this.title,
      this.scrollable = true});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: title != null
          ? AppBar(
              title: Text(title!),
            )
          : null,
      key: scaffoldKey,
      body: scrollable
          ? SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                      maxWidth: 400), // Set maximum width to 400
                  child: child,
                ),
              ),
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                    maxWidth: 400), // Set maximum width to 400
                child: child,
              ),
            ),
    );
  }
}

class ResponsiveContainer extends StatelessWidget {
  final bool scrollable;
  final Widget child;

  // Constructor to take child and title as parameters
  const ResponsiveContainer(
      {super.key, required this.child, this.scrollable = true});

  @override
  Widget build(BuildContext context) {
    return scrollable
        ? SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                    maxWidth: 400), // Set maximum width to 400
                child: child,
              ),
            ),
          )
        : Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                  maxWidth: 400), // Set maximum width to 400
              child: child,
            ),
          );
  }
}

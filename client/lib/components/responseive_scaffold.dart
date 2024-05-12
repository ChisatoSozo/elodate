import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

class ResponsiveScaffold extends StatelessWidget {
  final Widget child;
  final String title; // Title property
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  // Constructor to take child and title as parameters
  ResponsiveScaffold({super.key, required this.child, required this.title});

  @override
  Widget build(BuildContext context) {
    // Check if the platform is web
    if (kIsWeb) {
      return Scaffold(
        key: scaffoldKey,
        body: Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  title, // Use the passed title for web
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(
                    height: 20), // Adding some spacing after the title
                child, // Use the passed child widget
              ],
            ),
          ),
        ),
      );
    } else {
      return Scaffold(
        key: scaffoldKey,
        appBar: AppBar(),
        body: Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  title, // Use the passed title for web
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(
                    height: 20), // Adding some spacing after the title
                child, // Use the passed child widget
              ],
            ),
          ),
        ),
      );
    }
  }
}

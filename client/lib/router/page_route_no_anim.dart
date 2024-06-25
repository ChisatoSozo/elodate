import 'package:flutter/material.dart';

class PageRouteNoAnim<T> extends Page<T> {
  final Widget child;

  const PageRouteNoAnim({
    required this.child,
    super.key,
    super.name,
    super.arguments,
  });

  @override
  Route<T> createRoute(BuildContext context) {
    return PageRouteBuilder(
      settings: this,
      pageBuilder: (context, animation, secondaryAnimation) => child,
    );
  }
}

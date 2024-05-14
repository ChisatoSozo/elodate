import 'package:flutter/material.dart';

class ResponsiveContainer extends StatelessWidget {
  final Widget child;

  const ResponsiveContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double maxWidth = 600.0;
        double screenWidth = constraints.maxWidth;
        double containerWidth = screenWidth < maxWidth ? screenWidth : maxWidth;

        return Center(
          child: SizedBox(
            width: containerWidth,
            child: child,
          ),
        );
      },
    );
  }
}

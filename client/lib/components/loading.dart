import 'package:client/components/spacer.dart';
import 'package:flutter/material.dart';

class Loading extends StatelessWidget {
  final String? text;

  const Loading({super.key, this.text});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          width: 100,
          height: 100,
          child: CircularProgressIndicator(),
        ),
        const VerticalSpacer(),
        if (text != null) Text(text!),
      ],
    );
  }
}

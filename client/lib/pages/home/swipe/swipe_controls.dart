import 'package:flutter/material.dart';

class SwipeControls extends StatelessWidget {
  final VoidCallback onLike;
  final VoidCallback onDislike;

  const SwipeControls({
    super.key,
    required this.onLike,
    required this.onDislike,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: onDislike,
          color: Colors.red,
        ),
        IconButton(
          icon: const Icon(Icons.favorite),
          onPressed: onLike,
          color: Colors.green,
        ),
      ],
    );
  }
}

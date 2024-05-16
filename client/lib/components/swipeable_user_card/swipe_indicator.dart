import 'package:flutter/material.dart';

class SwipeIndicator extends StatelessWidget {
  final bool isLiked;

  const SwipeIndicator({
    super.key,
    required this.isLiked,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        color: isLiked
            ? Colors.green.withOpacity(0.3)
            : Colors.red.withOpacity(0.3),
        child: Center(
          child: Icon(
            isLiked ? Icons.favorite : Icons.close,
            color: Colors.white,
            size: 100,
          ),
        ),
      ),
    );
  }
}

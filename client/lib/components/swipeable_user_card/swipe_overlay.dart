import 'package:flutter/material.dart';

class SwipeOverlay extends StatelessWidget {
  final Color overlayColor;
  final double swipeOffset;

  const SwipeOverlay({
    super.key,
    required this.overlayColor,
    required this.swipeOffset,
  });

  @override
  Widget build(BuildContext context) {
    bool isLiked = overlayColor == Colors.green.withOpacity(0.7);
    bool isNeutral = overlayColor == Colors.transparent;

    double opacity = (swipeOffset.abs() / 200).clamp(0.0, 1.0);
    double iconSize = (swipeOffset.abs() / 200 * 300).clamp(0.0, 300.0);

    return Positioned.fill(
      child: Stack(
        children: [
          if (!isNeutral)
            Center(
              child: Opacity(
                opacity: opacity,
                child: Icon(
                  isLiked ? Icons.favorite : Icons.close,
                  color: overlayColor,
                  size: iconSize,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

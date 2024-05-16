import 'package:flutter/material.dart';

class PageIndicator extends StatelessWidget {
  final int currentIndex;
  final int itemCount;

  const PageIndicator({
    super.key,
    required this.currentIndex,
    required this.itemCount,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 60.0,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(itemCount, (index) {
          return Container(
            margin: const EdgeInsets.all(4.0),
            width: 10.0,
            height: 10.0,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: currentIndex == index ? Colors.blue : Colors.grey,
            ),
          );
        }),
      ),
    );
  }
}

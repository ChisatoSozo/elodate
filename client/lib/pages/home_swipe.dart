import 'package:flutter/material.dart';

class SwipePage extends StatelessWidget {
  const SwipePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Swipe"),
      ),
      body: const Center(
        child: Text("Swipe Page"),
      ),
    );
  }
}

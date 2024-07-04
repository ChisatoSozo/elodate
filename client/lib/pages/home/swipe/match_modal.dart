import 'dart:math';

import 'package:client/api/pkg/lib/api.dart';
import 'package:client/components/uuid_image_provider.dart';
import 'package:client/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MatchModal extends StatefulWidget {
  final ApiUser user;

  const MatchModal({super.key, required this.user});

  @override
  MatchModalState createState() => MatchModalState();
}

class MatchModalState extends State<MatchModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildParticle(double startPositionX, double startPositionY,
      double delay, double startScale, double velocityX, double velocityY) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final animationValue = (_controller.value - delay).clamp(0.0, 1.0);
        if (animationValue == 0.0) {
          return const SizedBox.shrink();
        }
        var scale = startScale - animationValue * startScale;
        return Positioned(
          bottom: velocityY * animationValue * 300 +
              startPositionY +
              15 -
              ((scale * 30) / 2),
          left: startPositionX +
              30 -
              ((scale * 30) / 2) +
              (animationValue * 100 * velocityX),
          child: Opacity(
            opacity: 1 - animationValue,
            child: Transform.scale(
              scale: scale,
              child: const Icon(Icons.favorite, color: Colors.red, size: 30),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildParticles() {
    final random = Random();
    const avatarCenterX = 25;
    const avatarCenterY = 25;
    return List.generate(20, (index) {
      final angle = random.nextDouble() * 2 * pi;
      final radius = random.nextDouble() * 50;
      final startPositionX = avatarCenterX + radius * cos(angle);
      final startPositionY = avatarCenterY + radius * sin(angle);
      final delay = random.nextDouble() * 0.1;
      final startScale = 0.75 + random.nextDouble() * 1;
      final velocityX = 3 - random.nextDouble() * 6;
      final velocityY = 0.5 + random.nextDouble() * 1;
      return _buildParticle(startPositionX, startPositionY, delay, startScale,
          velocityX, velocityY);
    });
  }

  @override
  Widget build(BuildContext context) {
    var userModel = Provider.of<UserModel>(context, listen: false);
    var newCachedImages = <UuidImageProvider>[];
    for (var image in widget.user.images) {
      newCachedImages.add(UuidImageProvider(
        uuid: image,
        userModel: userModel,
      ));
    }

    return Container(
      height: 350,
      width: 300,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          //x button
          SizedBox(
            width: 300,
            child: Align(
              alignment: Alignment.topRight,
              child: SizedBox(
                width: 50,
                height: 50,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ),
          ),

          Stack(clipBehavior: Clip.none, children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: newCachedImages.first,
            ),
            ..._buildParticles(),
          ]),
          const SizedBox(height: 16.0),
          Text(
            "It's a match!",
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16.0),
          Text(
            'You and ${widget.user.displayName} liked each other.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

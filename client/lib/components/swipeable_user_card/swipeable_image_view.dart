import 'package:client/components/uuid_image_provider.dart';
import 'package:flutter/material.dart';
import 'package:preload_page_view/preload_page_view.dart';

class SwipeableImageView extends StatelessWidget {
  final List<UuidImageProvider> images;
  final PreloadPageController controller;
  final Function(int) onPageChanged;

  const SwipeableImageView({
    super.key,
    required this.images,
    required this.controller,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PreloadPageView.builder(
      controller: controller,
      itemCount: images.length,
      preloadPagesCount: 3,
      onPageChanged: onPageChanged,
      itemBuilder: (context, index) {
        return Image(
          image: images[index],
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        );
      },
    );
  }
}

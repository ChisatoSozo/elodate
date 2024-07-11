import 'package:flutter/material.dart';

enum SpacerType { vertical, horizontal }

enum SpacerSize { small, medium, large }

class Spacer extends StatelessWidget {
  final SpacerType type;
  final SpacerSize size;

  const Spacer({
    super.key,
    this.type = SpacerType.vertical,
    this.size = SpacerSize.large,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: type == SpacerType.vertical
          ? _getVerticalSize(size)
          : _getHorizontalSize(size),
      width: type == SpacerType.horizontal
          ? _getHorizontalSize(size)
          : _getVerticalSize(size),
    );
  }

  double _getVerticalSize(SpacerSize size) {
    switch (size) {
      case SpacerSize.small:
        return 8.0;
      case SpacerSize.medium:
        return 16.0;
      case SpacerSize.large:
        return 24.0;
    }
  }

  double _getHorizontalSize(SpacerSize size) {
    switch (size) {
      case SpacerSize.small:
        return 8.0;
      case SpacerSize.medium:
        return 16.0;
      case SpacerSize.large:
        return 24.0;
    }
  }
}

class HorizontalSpacer extends StatelessWidget {
  final SpacerSize size;

  const HorizontalSpacer({
    super.key,
    this.size = SpacerSize.large,
  });

  @override
  Widget build(BuildContext context) {
    return Spacer(
      type: SpacerType.horizontal,
      size: size,
    );
  }
}

class VerticalSpacer extends StatelessWidget {
  final SpacerSize size;

  const VerticalSpacer({
    super.key,
    this.size = SpacerSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    return Spacer(
      type: SpacerType.vertical,
      size: size,
    );
  }
}

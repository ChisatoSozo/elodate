import 'package:flutter/material.dart';

enum EloSpacerType { vertical, horizontal }

enum EloSpacerSize { small, medium, large }

class EloSpacer extends StatelessWidget {
  final EloSpacerType type;
  final EloSpacerSize size;

  const EloSpacer({
    super.key,
    this.type = EloSpacerType.vertical,
    this.size = EloSpacerSize.large,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: type == EloSpacerType.vertical
          ? _getVerticalSize(size)
          : _getHorizontalSize(size),
      width: type == EloSpacerType.horizontal
          ? _getHorizontalSize(size)
          : _getVerticalSize(size),
    );
  }

  double _getVerticalSize(EloSpacerSize size) {
    switch (size) {
      case EloSpacerSize.small:
        return 8.0;
      case EloSpacerSize.medium:
        return 16.0;
      case EloSpacerSize.large:
        return 24.0;
    }
  }

  double _getHorizontalSize(EloSpacerSize size) {
    switch (size) {
      case EloSpacerSize.small:
        return 8.0;
      case EloSpacerSize.medium:
        return 16.0;
      case EloSpacerSize.large:
        return 24.0;
    }
  }
}

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class UuidImageProvider extends ImageProvider<UuidImageProvider> {
  final String uuid;

  UuidImageProvider(this.uuid);

  @override
  Future<UuidImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<UuidImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadImage(
      UuidImageProvider key, ImageDecoderCallback decode) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key.uuid, decode),
      scale: 1.0,
    );
  }

  Future<ui.Codec> _loadAsync(String uuid, ImageDecoderCallback decode) async {
    final Uint8List bytes = await _fetchImageBytes(uuid);
    if (bytes.isEmpty) {
      throw Exception('Failed to load image for UUID: $uuid');
    }
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    return decode(buffer);
  }

  // Method signature to fetch image bytes using UUID
  Future<Uint8List> _fetchImageBytes(String uuid);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! UuidImageProvider) return false;
    return uuid == other.uuid;
  }

  @override
  int get hashCode => uuid.hashCode;
}

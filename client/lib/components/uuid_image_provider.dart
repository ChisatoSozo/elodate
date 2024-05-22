import 'dart:convert';
import 'dart:ui' as ui;

import 'package:client/models/home_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class UuidImageProvider extends ImageProvider<UuidImageProvider> {
  final String uuid;
  final HomeModel homeModel;

  UuidImageProvider({
    required this.uuid,
    required this.homeModel,
  });

  @override
  Future<UuidImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<UuidImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadImage(
      UuidImageProvider key, ImageDecoderCallback decode) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode),
      scale: 1.0,
    );
  }

  Future<ui.Codec> _loadAsync(
      UuidImageProvider input, ImageDecoderCallback decode) async {
    var homeModel = input.homeModel;
    var uuid = input.uuid;
    var image = await homeModel.getImage(uuid);
    var b64 = image.b64Content;
    final Uint8List bytes = base64Decode(b64);
    if (bytes.isEmpty) {
      throw Exception('Failed to load image for UUID: $uuid');
    }
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    return decode(buffer);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! UuidImageProvider) return false;
    return uuid == other.uuid;
  }

  @override
  int get hashCode => uuid.hashCode;
}

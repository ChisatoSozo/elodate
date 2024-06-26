import 'dart:convert';
import 'dart:ui' as ui;

import 'package:client/models/user_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class UuidImageProvider extends ImageProvider<UuidImageProvider> {
  final String uuid;
  final UserModel userModel;

  UuidImageProvider({
    required this.uuid,
    required this.userModel,
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
    var userModel = input.userModel;
    var uuid = input.uuid;
    var image = await userModel.getImage(uuid);
    var b64 = image.content;
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

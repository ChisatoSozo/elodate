import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_compression_flutter/image_compression_flutter.dart';

String formatApiError(String s) {
  //get rid of "ApiException xxx: "
  var match = RegExp(r'ApiException \d+: (.*)').firstMatch(s);
  if (match != null) {
    return match.group(1)!;
  }
  return s;
}

//exponential backoff future retry
Future<T> retry<T>(
  Future<T> Function() fn, {
  Duration initialDelay = const Duration(milliseconds: 100),
  Duration maxDelay = const Duration(seconds: 5),
  double factor = 2,
  int retries = 5,
}) async {
  var attempts = 0;
  var delay = initialDelay;
  while (true) {
    try {
      return await fn();
    } catch (e) {
      if (attempts++ == retries) {
        rethrow;
      }
      await Future.delayed(delay);
      delay = Duration(milliseconds: (delay.inMilliseconds * factor).round());

      if (delay > maxDelay) {
        delay = maxDelay;
      }
      if (delay < initialDelay) {
        delay = initialDelay;
      }
    }
  }
}

Future<Uint8List> compressImage(Uint8List imageBytes) async {
  // Decode the image

  ImageFile input = ImageFile(filePath: "", rawBytes: imageBytes);
  Configuration config = const Configuration(
    outputType: ImageOutputType.jpg,
    // can only be true for Android and iOS while using ImageOutputType.jpg or ImageOutputType.pngÏ
    useJpgPngNativeCompressor: false,
    // set quality between 0-100
    quality: 80,
  );

  final param = ImageFileConfiguration(input: input, config: config);
  final output = await compressor.compress(param);
  return output.rawBytes;
}

Future<Uint8List> makePreview(Uint8List imageBytes) async {
  //resize the image to 200x200
  img.Image image = img.decodeImage(imageBytes)!;
  img.Image thumbnail = img.copyResize(image, width: 200, height: 200);
  Uint8List thumbnailBytes = Uint8List.fromList(img.encodeJpg(thumbnail));
  // Decode the image
  ImageFile input = ImageFile(filePath: "", rawBytes: thumbnailBytes);
  Configuration config = const Configuration(
    outputType: ImageOutputType.jpg,
    // can only be true for Android and iOS while using ImageOutputType.jpg or ImageOutputType.pngÏ
    useJpgPngNativeCompressor: false,
    // set quality between 0-100
    quality: 80,
  );

  final param = ImageFileConfiguration(input: input, config: config);
  final output = await compressor.compress(param);
  return output.rawBytes;
}

const double maxPageWidth = 400.0;
const double pageMargin = 24.0;

double calcPageWidth(BuildContext context) {
  var width = MediaQuery.of(context).size.width;
  var widthWithPadding = width - pageMargin * 2;
  //pageWidth is the smaller of the maxPageWidth and the screen width
  var pageWidth =
      widthWithPadding < maxPageWidth ? widthWithPadding : maxPageWidth;
  return pageWidth;
}

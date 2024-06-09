import 'dart:typed_data';

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

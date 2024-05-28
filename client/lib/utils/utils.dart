import 'dart:typed_data';

import 'package:image/image.dart' as img;

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

Future<Uint8List?> compressImage(Uint8List imageBytes) async {
  // Decode the image
  img.Image? image = img.decodeImage(imageBytes);

  if (image == null) {
    return null;
  }

  // Resize the image
  img.Image resizedImage = img.copyResize(
    image,
    width: 1024,
    height: 1024,
  );

  List<int> jpgBytes = img.encodeJpg(resizedImage, quality: 80);

  return Uint8List.fromList(jpgBytes);
}

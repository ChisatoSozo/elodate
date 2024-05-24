import 'package:client/api/pkg/lib/api.dart';

ApiUserWritableImagesInnerImageTypeEnum mimeToType(String mimeType) {
  switch (mimeType) {
    case "image/jpeg":
      return ApiUserWritableImagesInnerImageTypeEnum.jpeg;
    case "jpeg":
      return ApiUserWritableImagesInnerImageTypeEnum.jpeg;
    case "image/jpg":
      return ApiUserWritableImagesInnerImageTypeEnum.jpeg;
    case "jpg":
      return ApiUserWritableImagesInnerImageTypeEnum.jpeg;
    case "image/png":
      return ApiUserWritableImagesInnerImageTypeEnum.png;
    case "png":
      return ApiUserWritableImagesInnerImageTypeEnum.png;
    case "image/webp":
      return ApiUserWritableImagesInnerImageTypeEnum.webP;
    case "webp":
      return ApiUserWritableImagesInnerImageTypeEnum.webP;
    case "webP":
      return ApiUserWritableImagesInnerImageTypeEnum.webP;
    default:
      throw Exception("Unknown mime type: $mimeType");
  }
}

const double minLat = -90.0;
const double maxLat = 90.0;
const double minLon = -180.0;
const double maxLon = 180.0;
const int minI16 = -32768;
const int maxI16 = 32767;

int encodeToI16(double value, double minValue, double maxValue, int? minI16In,
    int? maxI16In) {
  var minI16Use = minI16In ?? minI16;
  var maxI16Use = maxI16In ?? maxI16;
  // Normalize the value to a range between 0 and 1
  double normalized = (value - minValue) / (maxValue - minValue);

  // Scale the normalized value to the i16 range
  int quantized = ((normalized * (maxI16Use - minI16Use)).round() + minI16Use)
      .clamp(minI16Use, maxI16Use);

  return quantized;
}

double decodeFromI16(
    int value, double minValue, double maxValue, int? minI16In, int? maxI16In) {
  // Normalize the value back to a range between 0 and 1
  var minI16Use = minI16In ?? minI16;
  var maxI16Use = maxI16In ?? maxI16;
  double normalized = (value - minI16Use) / (maxI16Use - minI16Use);

  // Scale the normalized value back to the original range
  double decoded = normalized * (maxValue - minValue) + minValue;

  return decoded;
}

(int, int) encodeLatLongToI16(double lat, double lon) {
  int quantizedLat = encodeToI16(lat, minLat, maxLat, null, null);
  int quantizedLon = encodeToI16(lon, minLon, maxLon, null, null);
  return (quantizedLat, quantizedLon);
}

(double, double) decodeLatLongFromI16(int quantizedLat, int quantizedLon) {
  double decodedLat = decodeFromI16(quantizedLat, minLat, maxLat, null, null);
  double decodedLon = decodeFromI16(quantizedLon, minLon, maxLon, null, null);
  return (decodedLat, decodedLon);
}

String formatApiError(String s) {
  //get rid of "ApiException xxx: "
  var match = RegExp(r'ApiException \d+: (.*)').firstMatch(s);
  if (match != null) {
    return match.group(1)!;
  }
  return s;
}

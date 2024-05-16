import 'package:client/api/pkg/lib/api.dart';

ChatAndLastMessageLastMessageImageImageTypeEnum mimeToType(String mimeType) {
  switch (mimeType) {
    case "image/jpeg":
      return ChatAndLastMessageLastMessageImageImageTypeEnum.JPEG;
    case "jpeg":
      return ChatAndLastMessageLastMessageImageImageTypeEnum.JPEG;
    case "image/jpg":
      return ChatAndLastMessageLastMessageImageImageTypeEnum.JPEG;
    case "jpg":
      return ChatAndLastMessageLastMessageImageImageTypeEnum.JPEG;
    case "image/png":
      return ChatAndLastMessageLastMessageImageImageTypeEnum.PNG;
    case "png":
      return ChatAndLastMessageLastMessageImageImageTypeEnum.PNG;
    case "image/webp":
      return ChatAndLastMessageLastMessageImageImageTypeEnum.WEBP;
    case "webp":
      return ChatAndLastMessageLastMessageImageImageTypeEnum.WEBP;
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

int encodeToI16(double value, double minValue, double maxValue) {
  // Normalize the value to a range between 0 and 1
  double normalized = (value - minValue) / (maxValue - minValue);

  // Scale the normalized value to the i16 range
  int quantized =
      ((normalized * (maxI16 - minI16)).round() + minI16).clamp(minI16, maxI16);

  return quantized;
}

double decodeFromI16(int value, double minValue, double maxValue) {
  // Normalize the value back to a range between 0 and 1
  double normalized = (value - minI16) / (maxI16 - minI16);

  // Scale the normalized value back to the original range
  double decoded = normalized * (maxValue - minValue) + minValue;

  return decoded;
}

(int, int) encodeLatLongToI16(double lat, double lon) {
  int quantizedLat = encodeToI16(lat, minLat, maxLat);
  int quantizedLon = encodeToI16(lon, minLon, maxLon);
  return (quantizedLat, quantizedLon);
}

(double, double) decodeLatLongFromI16(int quantizedLat, int quantizedLon) {
  double decodedLat = decodeFromI16(quantizedLat, minLat, maxLat);
  double decodedLon = decodeFromI16(quantizedLon, minLon, maxLon);
  return (decodedLat, decodedLon);
}

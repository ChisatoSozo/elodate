import 'package:client/api/pkg/lib/api.dart';

MessageImageImageTypeEnum mimeToType(String mimeType) {
  switch (mimeType) {
    case "image/jpeg":
      return MessageImageImageTypeEnum.JPEG;
    case "jpeg":
      return MessageImageImageTypeEnum.JPEG;
    case "image/jpg":
      return MessageImageImageTypeEnum.JPEG;
    case "jpg":
      return MessageImageImageTypeEnum.JPEG;
    case "image/png":
      return MessageImageImageTypeEnum.PNG;
    case "png":
      return MessageImageImageTypeEnum.PNG;
    case "image/webp":
      return MessageImageImageTypeEnum.WEBP;
    case "webp":
      return MessageImageImageTypeEnum.WEBP;
    default:
      throw Exception("Unknown mime type: $mimeType");
  }
}

SendMessageInputMessageImageTypeEnum fromMesageImageImageTypeEnum(
    MessageImageImageTypeEnum type) {
  switch (type) {
    case MessageImageImageTypeEnum.JPEG:
      return SendMessageInputMessageImageTypeEnum.JPEG;
    case MessageImageImageTypeEnum.PNG:
      return SendMessageInputMessageImageTypeEnum.PNG;
    case MessageImageImageTypeEnum.WEBP:
      return SendMessageInputMessageImageTypeEnum.WEBP;
    default:
      throw Exception("Unknown message image image type: $type");
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

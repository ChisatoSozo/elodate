import 'package:client/api/pkg/lib/api.dart';

const int minI16 = -32768;
const int maxI16 = 32767;

ApiUserPropsInner getPropByName(List<ApiUserPropsInner> props, String name) {
  return props.firstWhere((element) => element.name == name);
}

ApiUserPrefsInner getPrefByName(List<ApiUserPrefsInner> prefs, String name) {
  return prefs.firstWhere((element) => element.name == name);
}

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

import 'dart:math';

import 'package:client/api/pkg/lib/api.dart';
import 'package:client/utils/utils.dart';

int calculateInitialDistance(ApiUserMe user) {
  final userLatLng =
      decodeLatLongFromI16(user.properties.latitude, user.properties.longitude);
  final preferenceMinLatLng = decodeLatLongFromI16(
      user.preferences.latitude.min, user.preferences.longitude.min);
  final preferenceMaxLatLng = decodeLatLongFromI16(
      user.preferences.latitude.max, user.preferences.longitude.max);

  double deltaLat = (preferenceMaxLatLng.$1 - preferenceMinLatLng.$1) / 2;
  double deltaLng = (preferenceMaxLatLng.$2 - preferenceMinLatLng.$2) / 2;

  const double earthRadiusKm = 6371.0;
  double distance = sqrt(pow(deltaLat * pi / 180 * earthRadiusKm, 2) +
      pow(deltaLng * pi / 180 * earthRadiusKm * cos(userLatLng.$1 * pi / 180),
          2));

  return distance.round();
}

int findClosestDistanceIndex(int distance, List<int> presetDistances) {
  int closestIndex = 0;
  int closestDifference = (distance - presetDistances[0]).abs();
  for (int i = 1; i < presetDistances.length; i++) {
    int difference = (distance - presetDistances[i]).abs();
    if (difference < closestDifference) {
      closestIndex = i;
      closestDifference = difference;
    }
  }
  return closestIndex;
}

(
  ApiUserPreferencesAdditionalPreferencesInnerRange,
  ApiUserPreferencesAdditionalPreferencesInnerRange
) getLatLngRange(
  ApiUser user,
  int distanceInKm,
) {
  final userLatLng =
      decodeLatLongFromI16(user.properties.latitude, user.properties.longitude);

  const double earthRadiusKm = 6371.0;

  double deltaLat = distanceInKm / earthRadiusKm;
  double deltaLng =
      distanceInKm / (earthRadiusKm * cos(userLatLng.$1 * pi / 180));

  double minLat = userLatLng.$1 - deltaLat * 180 / pi;
  double maxLat = userLatLng.$1 + deltaLat * 180 / pi;
  double minLng = userLatLng.$2 - deltaLng * 180 / pi;
  double maxLng = userLatLng.$2 + deltaLng * 180 / pi;

  final minLatLng = encodeLatLongToI16(minLat, minLng);
  final maxLatLng = encodeLatLongToI16(maxLat, maxLng);

  return (
    ApiUserPreferencesAdditionalPreferencesInnerRange(
        min: minLatLng.$1, max: maxLatLng.$1),
    ApiUserPreferencesAdditionalPreferencesInnerRange(
        min: minLatLng.$2, max: maxLatLng.$2)
  );
}

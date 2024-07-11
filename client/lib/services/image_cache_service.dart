import 'package:client/components/uuid_image_provider.dart';
import 'package:client/models/user_model.dart';

class ImageCacheService {
  static final Map<String, UuidImageProvider> _cache = {};

  static UuidImageProvider getImageProvider(String uuid, UserModel userModel) {
    if (!_cache.containsKey(uuid)) {
      _cache[uuid] = UuidImageProvider(uuid: uuid, userModel: userModel);
    }
    return _cache[uuid]!;
  }

  static List<UuidImageProvider> getImageProviders(
      List<String> uuids, UserModel userModel) {
    return uuids.map((uuid) => getImageProvider(uuid, userModel)).toList();
  }

  static void clearCache() {
    _cache.clear();
  }
}

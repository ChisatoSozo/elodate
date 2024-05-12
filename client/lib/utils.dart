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

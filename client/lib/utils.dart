import 'package:client/api/pkg/lib/api.dart';

UserWithImagesImagesInnerImageTypeEnum mimeToType(String mimeType) {
  switch (mimeType) {
    case "image/jpeg":
      return UserWithImagesImagesInnerImageTypeEnum.JPEG;
    case "jpeg":
      return UserWithImagesImagesInnerImageTypeEnum.JPEG;
    case "image/jpg":
      return UserWithImagesImagesInnerImageTypeEnum.JPEG;
    case "jpg":
      return UserWithImagesImagesInnerImageTypeEnum.JPEG;
    case "image/png":
      return UserWithImagesImagesInnerImageTypeEnum.PNG;
    case "png":
      return UserWithImagesImagesInnerImageTypeEnum.PNG;
    case "image/webp":
      return UserWithImagesImagesInnerImageTypeEnum.WEBP;
    case "webp":
      return UserWithImagesImagesInnerImageTypeEnum.WEBP;
    default:
      throw Exception("Unknown mime type: $mimeType");
  }
}

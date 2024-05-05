import 'dart:typed_data';

class ImageModel {
  Uint8List data;
  String mimeType;

  ImageModel({required this.data, required this.mimeType});
}

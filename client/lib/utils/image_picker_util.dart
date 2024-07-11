import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerUtil {
  static Future<Uint8List?> pickImage({ImageSource? source}) async {
    if (kIsWeb) {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        return result.files.single.bytes!;
      }
    } else {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile =
          await picker.pickImage(source: source ?? ImageSource.gallery);

      if (pickedFile != null) {
        return await pickedFile.readAsBytes();
      }
    }

    return null;
  }
}

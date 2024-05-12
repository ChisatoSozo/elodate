import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';

class AdaptiveFilePicker extends StatefulWidget {
  final Function(Uint8List, String)? onFileChanged;

  const AdaptiveFilePicker({super.key, this.onFileChanged});

  @override
  AdaptiveFilePickerState createState() => AdaptiveFilePickerState();
}

class AdaptiveFilePickerState extends State<AdaptiveFilePicker> {
  Uint8List? imageData;
  late DropzoneViewController dropzoneController;
  String? mimeType;

  @override
  Widget build(BuildContext context) {
    return kIsWeb ? buildWebDropzone() : buildMobilePicker();
  }

  Widget buildMobilePicker() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () async {
            FilePickerResult? result = await FilePicker.platform.pickFiles(
              type: FileType.image,
              allowedExtensions: ['jpg', 'png', 'webp'],
              withData: true,
            );

            if (result != null && result.files.single.bytes != null) {
              setState(() {
                imageData = result.files.single.bytes;
                mimeType = result.files.single.extension;
              });
              widget.onFileChanged?.call(imageData!, mimeType!);
            }
          },
          child: const Text('Pick Image'),
        ),
        if (imageData != null) Image.memory(imageData!),
      ],
    );
  }

  Widget buildWebDropzone() {
    return GestureDetector(
      onTap: () async {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['jpg', 'png', 'webp'],
          withData: true,
        );

        if (result != null && result.files.single.bytes != null) {
          setState(() {
            imageData = result.files.single.bytes;
            mimeType = result.files.single.extension;
          });
          widget.onFileChanged?.call(imageData!, mimeType!);
        }
      },
      child: Stack(
        children: [
          DropzoneView(
            operation: DragOperation.copy,
            onCreated: (controller) => dropzoneController = controller,
            onDrop: (ev) async {
              final bytes = await dropzoneController.getFileData(ev);
              final mime = await dropzoneController.getFileMIME(ev);
              setState(() {
                imageData = bytes;
                mimeType = mime;
              });
              widget.onFileChanged?.call(bytes, mime);
            },
          ),
          if (imageData != null)
            Image.memory(imageData!)
          else
            Container(
              alignment: Alignment.center,
              height: 200,
              width: 200,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                border: Border.all(color: Colors.blueAccent),
              ),
              child: const Text('Click or Drop image here',
                  style: TextStyle(color: Colors.blueAccent)),
            ),
        ],
      ),
    );
  }
}

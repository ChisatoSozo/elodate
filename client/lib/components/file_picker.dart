import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';

class AdaptiveFilePickerController extends ValueNotifier<(Uint8List, String)?> {
  AdaptiveFilePickerController() : super(null);

  void pickFile(Function(Uint8List, String)? onFileChanged) async {
    if (kIsWeb) {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'png', 'webp'],
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        value = (result.files.single.bytes!, result.files.single.extension!);
        if (onFileChanged != null) {
          onFileChanged(
              result.files.single.bytes!, result.files.single.extension!);
        }
      }
    } else {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowedExtensions: ['jpg', 'png', 'webp'],
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        value = (result.files.single.bytes!, result.files.single.extension!);
        if (onFileChanged != null) {
          onFileChanged(
              result.files.single.bytes!, result.files.single.extension!);
        }
      }
    }
  }
}

class AdaptiveFilePicker extends StatefulWidget {
  final Uint8List? imageData;
  final String? mimeType;
  final Function(Uint8List, String)? onFileChanged;
  final AdaptiveFilePickerController controller;

  const AdaptiveFilePicker({
    super.key,
    this.imageData,
    this.mimeType,
    this.onFileChanged,
    required this.controller,
  });

  @override
  AdaptiveFilePickerState createState() => AdaptiveFilePickerState();
}

class AdaptiveFilePickerState extends State<AdaptiveFilePicker> {
  late DropzoneViewController dropzoneController;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleFileChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleFileChange);
    super.dispose();
  }

  void _handleFileChange() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return kIsWeb ? buildWebPicker() : buildMobilePicker();
  }

  Widget buildMobilePicker() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () => widget.controller.pickFile(widget.onFileChanged),
          child: const Text('Pick Image'),
        ),
        const SizedBox(height: 8),
        buildContent(),
      ],
    );
  }

  Widget buildWebPicker() {
    return GestureDetector(
      onTap: () => widget.controller.pickFile(widget.onFileChanged),
      child: AspectRatio(
        aspectRatio: 9 / 16,
        child: Stack(
          children: [
            DropzoneView(
              operation: DragOperation.copy,
              onCreated: (controller) => dropzoneController = controller,
              onDrop: (ev) async {
                final bytes = await dropzoneController.getFileData(ev);
                final mime = await dropzoneController.getFileMIME(ev);
                widget.controller.value = (bytes, mime);
                if (widget.onFileChanged != null) {
                  widget.onFileChanged!(bytes, mime);
                }
              },
            ),
            buildContent(),
          ],
        ),
      ),
    );
  }

  Widget buildContent() {
    Uint8List? imageData = widget.controller.value?.$1;
    return AspectRatio(
      aspectRatio: 9 / 16,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: imageData != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(imageData, fit: BoxFit.cover),
              )
            : const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, size: 50, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'Add Image',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

import 'package:client/models/register_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'package:provider/provider.dart';

class RegisterImagesPage extends StatefulWidget {
  const RegisterImagesPage({super.key});

  @override
  RegisterImagesPageState createState() => RegisterImagesPageState();
}

class RegisterImagesPageState extends State<RegisterImagesPage> {
  List<DropzoneViewController> controllers = List.empty(growable: true);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drop Images Here'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.count(
          crossAxisCount: 3,
          children: List.generate(6, buildDropzone),
        ),
      ),
    );
  }

  Widget buildDropzone(int index) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blueAccent),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          DropzoneView(
            onCreated: (controller) => controllers.add(controller),
            onDrop: (ev) =>
                _flushImageToProvider(controllers[index], ev, index),
            onError: (ev) => print('Drop error on zone $index: $ev'),
            mime: const ['image/jpeg', 'image/png', 'image/webp'],
            operation: DragOperation.copy,
          ),
          Text('Drop Zone ${index + 1}',
              style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  //event, index
  // This function is called when an image is dropped onto a dropzone.
// It retrieves the image file, converts it to a Uint8List, and updates the provider.
  _flushImageToProvider(
      DropzoneViewController controller, dynamic event, int index) async {
    try {
      // Retrieve the last file dropped into the dropzone
      final mimeType = await controller.getFileMIME(event);
      final byteData = await controller.getFileData(event);

      // If file data was retrieved successfully, update the provider
      Provider.of<RegisterModel>(context, listen: false)
          .setImage(byteData, mimeType, index);
    } catch (e) {
      print('Error retrieving file data: $e');
    }
  }
}

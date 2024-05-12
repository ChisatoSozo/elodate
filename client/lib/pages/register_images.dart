import 'dart:typed_data';

import 'package:client/components/file_picker.dart';
import 'package:client/components/responseive_scaffold.dart';
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
    return ResponsiveScaffold(
      title: "Upload your images:",
      child: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 500, // Provide a specific height for the GridView
              child: GridView.count(
                crossAxisCount: 3,
                children: List.generate(6, buildDropzone),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                nextPage(context, widget);
              },
              child: const Text('Register'),
            ),
          ],
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
          AdaptiveFilePicker(
            onFileChanged: (byteData, mimeType) =>
                _flushImageToProvider(byteData, mimeType, index),
          ),
          Text('Drop Zone ${index + 1}',
              style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  _flushImageToProvider(Uint8List byteData, String mimeType, int index) async {
    try {
      Provider.of<RegisterModel>(context, listen: false)
          .setImage(byteData, mimeType, index);
    } catch (e) {
      print('Error retrieving file data: $e');
    }
  }
}

import 'dart:typed_data';

import 'package:client/components/image_grid.dart';
import 'package:client/components/responseive_scaffold.dart';
import 'package:client/models/register_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RegisterImagesPage extends StatefulWidget {
  const RegisterImagesPage({super.key});

  @override
  RegisterImagesPageState createState() => RegisterImagesPageState();
}

class RegisterImagesPageState extends State<RegisterImagesPage> {
  late ImageGridFormFieldController _imageGridController;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _imageGridController = ImageGridFormFieldController();
    // Initialize with empty values or existing values if any
    _imageGridController.value =
        List<(Uint8List?, String?)>.filled(6, (null, null));
  }

  @override
  void dispose() {
    _imageGridController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: ResponsiveScaffold(
        title: "Upload your images:",
        child: SingleChildScrollView(
          child: Column(
            children: [
              ImageGridFormField(
                controller: _imageGridController,
                validator: (images) {
                  // Add validation logic if needed
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  _saveImagesAndProceed();
                },
                child: const Text('Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveImagesAndProceed() {
    var images = _imageGridController.value;

    if (images.every((image) => image.$1 == null || image.$2 == null) ||
        images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload at least one image')),
      );
    }

    for (int i = 0; i < images.length; i++) {
      final image = images[i];
      if (image.$1 != null && image.$2 != null) {
        Provider.of<RegisterModel>(context, listen: false)
            .setImage(image.$1!, image.$2!, i);
      }
    }
    nextPage(context, widget);
  }
}

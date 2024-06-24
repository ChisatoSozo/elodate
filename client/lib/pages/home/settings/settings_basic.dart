import 'dart:convert';

import 'package:client/pages/home/settings/image_picker.dart';
import 'package:client/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/user_model.dart';

class BasicSettings extends StatelessWidget {
  final VoidCallback onModified;

  const BasicSettings({super.key, required this.onModified});

  @override
  Widget build(BuildContext context) {
    final userModel = Provider.of<UserModel>(context, listen: false);
    return Form(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextFormField(
            initialValue: userModel.me.displayName,
            labelText: 'Display Name',
            onChanged: (value) {
              userModel.me.displayName = value;
              onModified();
            },
          ),
          const SizedBox(height: 20),
          _buildTextFormField(
            initialValue: userModel.me.description,
            labelText: 'Description',
            onChanged: (value) {
              userModel.me.description = value;
              onModified();
            },
            maxLines: 10,
          ),
          const SizedBox(height: 20),
          Text('Images', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 20),
          _buildImagePickerGrid(userModel),
        ],
      ),
    );
  }

  Widget _buildTextFormField({
    required String initialValue,
    required String labelText,
    required Function(String) onChanged,
    int maxLines = 1,
  }) {
    return TextFormField(
      initialValue: initialValue,
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(),
      ),
      onChanged: onChanged,
      maxLines: maxLines,
    );
  }

  Widget _buildImagePickerGrid(UserModel userModel) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 9 / 16,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return AdaptiveFilePicker(
          onUuidChanged: (newUuid) async {
            if (index == 0) {
              var image = await userModel.getImage(newUuid);
              var imageBytes = base64Decode(image.content);
              var newBytes = await makePreview(imageBytes);
              var previewUuid = await userModel.putImage(newBytes, null);
              userModel.me.previewImage = previewUuid;
            }
            if (index < userModel.me.images.length) {
              userModel.me.images[index] = newUuid;
            } else {
              userModel.me.images = [...userModel.me.images, newUuid];
            }
            onModified();
          },
          initialUuid: index < userModel.me.images.length
              ? userModel.me.images[index]
              : null,
        );
      },
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
    );
  }
}

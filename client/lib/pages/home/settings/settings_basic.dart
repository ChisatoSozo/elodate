import 'dart:convert';

import 'package:client/components/custom_form_field.dart';
import 'package:client/components/spacer.dart';
import 'package:client/models/user_model.dart';
import 'package:client/pages/home/settings/image_picker.dart';
import 'package:client/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BasicSettings extends StatelessWidget {
  const BasicSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final userModel = Provider.of<UserModel>(context, listen: false);
    return Form(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomFormField(
            controller: TextEditingController(text: userModel.me.displayName),
            labelText: 'Display Name',
            onChanged: (value) {
              userModel.me.displayName = value;
              userModel.setChanges(true);
            },
          ),
          const VerticalSpacer(),
          CustomFormField(
            controller: TextEditingController(text: userModel.me.description),
            labelText: 'Description',
            onChanged: (value) {
              userModel.me.description = value;
              userModel.setChanges(true);
            },
            maxLines: 10,
          ),
          const VerticalSpacer(),
          Text('Images', style: Theme.of(context).textTheme.titleMedium),
          const VerticalSpacer(),
          _buildImagePickerGrid(userModel),
        ],
      ),
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
            userModel.setChanges(true);
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

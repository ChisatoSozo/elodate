import 'package:client/components/loading.dart';
import 'package:client/components/spacer.dart';
import 'package:client/components/uuid_image_provider.dart';
import 'package:client/models/user_model.dart';
import 'package:client/utils/image_picker_util.dart';
import 'package:client/utils/utils.dart';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AdaptiveFilePicker extends StatefulWidget {
  final Function(String) onUuidChanged;
  final String? initialUuid;

  const AdaptiveFilePicker({
    super.key,
    this.initialUuid,
    required this.onUuidChanged,
  });

  @override
  AdaptiveFilePickerState createState() => AdaptiveFilePickerState();
}

class AdaptiveFilePickerState extends State<AdaptiveFilePicker> {
  String? imageUuid;
  bool loading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    imageUuid = widget.initialUuid;
  }

  @override
  Widget build(BuildContext context) {
    return kIsWeb ? buildWebPicker(context) : buildMobilePicker(context);
  }

  Widget buildMobilePicker(BuildContext context) {
    var userModel = Provider.of<UserModel>(context, listen: false);

    return Column(
      children: [
        ElevatedButton(
          onPressed: () => _pickFile(userModel),
          child: Text(errorMessage != null ? 'Retry' : 'Pick Image'),
        ),
        const VerticalSpacer(size: SpacerSize.small),
        buildContent(),
      ],
    );
  }

  Widget buildWebPicker(BuildContext context) {
    var userModel = Provider.of<UserModel>(context, listen: false);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _pickFile(userModel),
        child: AspectRatio(
          aspectRatio: 9 / 16,
          child: buildContent(),
        ),
      ),
    );
  }

  Widget buildContent() {
    if (loading) {
      return const Center(child: Loading(text: "Processing..."));
    }

    var userModel = Provider.of<UserModel>(context, listen: false);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: imageUuid != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image(
                image: UuidImageProvider(
                  uuid: imageUuid!,
                  userModel: userModel,
                ),
                fit: BoxFit.cover,
              ),
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add, size: 50, color: Colors.grey),
                  const VerticalSpacer(size: SpacerSize.small),
                  Text(
                    errorMessage != null ? 'Retry' : 'Add Image',
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  if (errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Future<void> _pickFile(UserModel userModel) async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final pickedImage = await ImagePickerUtil.pickImage();

      if (pickedImage != null) {
        await _onAfterPickFile(userModel, pickedImage);
      } else {
        // User canceled the picker
        setState(() {
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        loading = false;
        errorMessage = 'Failed to pick image. Please try again.';
      });
    }
  }

  Future<void> _onAfterPickFile(UserModel userModel, Uint8List bytes) async {
    try {
      Uint8List compressedBytes = await compressImage(bytes);

      String uuid = await userModel.putImage(compressedBytes, null);
      widget.onUuidChanged(uuid);

      setState(() {
        imageUuid = uuid;
        loading = false;
        errorMessage = null;
      });
    } catch (e) {
      setState(() {
        loading = false;
        errorMessage = 'Failed to process image. Please try again.\n$e';
      });
    }
  }
}

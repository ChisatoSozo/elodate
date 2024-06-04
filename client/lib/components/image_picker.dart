import 'package:client/components/uuid_image_provider.dart';
import 'package:client/models/user_model.dart';
import 'package:client/utils/utils.dart';
import 'package:file_picker/file_picker.dart';
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

  @override
  void initState() {
    super.initState();
    imageUuid = widget.initialUuid;
  }

  @override
  void dispose() {
    super.dispose();
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
          child: const Text('Pick Image'),
        ),
        const SizedBox(height: 8),
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
      return const Center(child: CircularProgressIndicator());
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
    );
  }

  Future<String?> _pickFile(UserModel userModel) async {
    setState(() {
      loading = true;
    });
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      return await _onAfterPickFile(userModel, result.files.single.bytes!);
    }
    return null;
  }

  Future<String?> _onAfterPickFile(UserModel userModel, Uint8List bytes) async {
    Uint8List? compressedBytes = await compressImage(bytes);

    String uuid = await userModel.putImage(compressedBytes, null);
    widget.onUuidChanged(uuid);

    setState(() {
      imageUuid = uuid;
      loading = false;
    });
    return uuid;
  }
}

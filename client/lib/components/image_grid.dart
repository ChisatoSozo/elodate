import 'dart:typed_data';

import 'package:client/components/file_picker.dart'; // Ensure this path is correct
import 'package:flutter/material.dart';

class ImageGridFormFieldController
    extends ValueNotifier<List<(Uint8List?, String?)>> {
  ImageGridFormFieldController()
      : super(List<(Uint8List?, String?)>.filled(6, (null, null)));

  void updateValue(int index, (Uint8List?, String?) newValue) {
    value[index] = newValue;
    notifyListeners();
  }
}

class ImageGridFormField extends FormField<List<(Uint8List?, String?)>> {
  final ImageGridFormFieldController controller;

  ImageGridFormField({
    super.key,
    super.validator,
    required this.controller,
    bool autovalidate = false,
  }) : super(
          initialValue: controller.value,
          autovalidateMode: autovalidate
              ? AutovalidateMode.always
              : AutovalidateMode.disabled,
          builder: (FormFieldState<List<(Uint8List?, String?)>> state) {
            return Column(
              children: <Widget>[
                ImageGrid(
                  controller: controller,
                  onImageChanged: (images) {
                    state.didChange(images);
                  },
                ),
                if (state.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      state.errorText!,
                      style: TextStyle(
                          color: Theme.of(state.context).colorScheme.error),
                    ),
                  ),
              ],
            );
          },
        );

  @override
  FormFieldState<List<(Uint8List?, String?)>> createState() =>
      _ImageGridFormFieldState();
}

class _ImageGridFormFieldState
    extends FormFieldState<List<(Uint8List?, String?)>> {
  @override
  void initState() {
    super.initState();
    (widget as ImageGridFormField)
        .controller
        .addListener(_handleControllerChanged);
  }

  @override
  void dispose() {
    (widget as ImageGridFormField)
        .controller
        .removeListener(_handleControllerChanged);
    super.dispose();
  }

  void _handleControllerChanged() {
    setState(() {
      setValue((widget as ImageGridFormField).controller.value);
    });
  }
}

class ImageGrid extends StatelessWidget {
  final ImageGridFormFieldController controller;
  final ValueChanged<List<(Uint8List?, String?)>> onImageChanged;

  const ImageGrid({
    super.key,
    required this.controller,
    required this.onImageChanged,
  });

  void _handleFileChanged(Uint8List imageData, String mimeType) {
    for (int i = 0; i < controller.value.length; i++) {
      if (controller.value[i].$1 == null) {
        controller.updateValue(i, (imageData, mimeType));
        onImageChanged(controller.value);
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 9 / 16,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemCount: controller.value.length,
        itemBuilder: (context, index) {
          return AdaptiveFilePicker(
            imageData: controller.value[index].$1,
            mimeType: controller.value[index].$2,
            onFileChanged: _handleFileChanged,
            controller: AdaptiveFilePickerController()
              ..value = controller.value[index].$1 != null &&
                      controller.value[index].$2 != null
                  ? (
                      controller.value[index].$1!,
                      controller.value[index].$2!,
                    )
                  : null,
          );
        },
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
      ),
    );
  }
}

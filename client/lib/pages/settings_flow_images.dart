import 'package:client/models/page_state_model.dart';
import 'package:client/models/user_model.dart';
import 'package:client/pages/home/settings/image_picker.dart';
import 'package:client/router.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsFlowImagesPage extends StatefulWidget {
  const SettingsFlowImagesPage({super.key});

  @override
  SettingsFlowImagesPageState createState() => SettingsFlowImagesPageState();
}

class SettingsFlowImagesPageState extends State<SettingsFlowImagesPage> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final FocusNode _buttonFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    var userModel = Provider.of<UserModel>(context, listen: false);
    var pageStateModel = Provider.of<PageStateModel>(context, listen: false);
    pageStateModel.initPrefsCategories(userModel);
    _buttonFocusNode.requestFocus();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var userModel = Provider.of<UserModel>(context, listen: true);

    return Column(
      children: [
        GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 9 / 16,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: 6,
          itemBuilder: (context, index) {
            return AdaptiveFilePicker(
              onUuidChanged: (newUuid) {
                if (index < userModel.me.images.length) {
                  userModel.me.images[index] = newUuid;
                } else {
                  userModel.me.images = [
                    ...userModel.me.images,
                    newUuid,
                  ];
                }
              },
              initialUuid: index < userModel.me.images.length
                  ? userModel.me.images[index]
                  : null,
            );
          },
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
        ),
        const SizedBox(height: 20),
        Row(
          //align button to the right
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            //button with right arrow icon
            ElevatedButton(
              onPressed: () {
                _saveImagesAndProceed();
              },
              focusNode: _buttonFocusNode,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Next'),
                  Icon(Icons.arrow_forward),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _saveImagesAndProceed() {
    var userModel = Provider.of<UserModel>(context, listen: false);
    if (userModel.me.images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload at least one image')),
      );
      return;
    }

    //push material page route
    EloNav.goSettings();
  }
}

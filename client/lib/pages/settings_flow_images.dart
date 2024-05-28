import 'package:client/components/image_picker.dart';
import 'package:client/components/responsive_scaffold.dart';
import 'package:client/models/page_state_model.dart';
import 'package:client/models/user_model.dart';
import 'package:client/pages/settings_flow.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsFlowImagesPage extends StatefulWidget {
  const SettingsFlowImagesPage({super.key});

  @override
  SettingsFlowImagesPageState createState() => SettingsFlowImagesPageState();
}

class SettingsFlowImagesPageState extends State<SettingsFlowImagesPage> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  bool loaded = false;

  @override
  void initState() {
    super.initState();
    super.initState();
    var userModel = Provider.of<UserModel>(context, listen: false);
    var pageStateModel = Provider.of<PageStateModel>(context, listen: false);

    if (!userModel.isLoading && !userModel.isLoaded) {
      userModel.initAll().then(
        (userModel) {
          var me = userModel.me;
          List<String?> images = [...me.images];
          //push null till 6 images
          for (int i = images.length; i < 6; i++) {
            images.add(null);
          }

          setState(
            () {
              loaded = true;
              pageStateModel.initPreferencesCategories(userModel);
            },
          );
        },
      );
    } else {
      setState(() {
        loaded = true;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!loaded) {
      return const CircularProgressIndicator();
    }

    var userModel = Provider.of<UserModel>(context, listen: false);

    return Form(
      key: formKey,
      child: ResponsiveScaffold(
        title: "Upload your images:",
        child: SingleChildScrollView(
          child: Column(
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
    var userModel = Provider.of<UserModel>(context, listen: false);
    if (userModel.me.images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload at least one image')),
      );
      return;
    }

    //push material page route
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsFlowPage()),
    );
  }
}

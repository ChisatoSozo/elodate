import 'package:client/components/loading.dart';
import 'package:client/models/user_model.dart';
import 'package:client/router.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RedirPage extends StatefulWidget {
  const RedirPage({super.key});

  @override
  RedirPageState createState() => RedirPageState();
}

class RedirPageState extends State<RedirPage> {
  @override
  void initState() {
    super.initState();

    var userModel = Provider.of<UserModel>(context, listen: false);

    if (!userModel.isLoading && !userModel.isLoaded && userModel.canLoad()) {
      userModel.initAll(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    var userModel = Provider.of<UserModel>(context, listen: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      var canLoad = userModel.canLoad();
      if (!canLoad) {
        EloNav.goLogin();
        return;
      }

      var isLoaded = userModel.isLoaded;
      var isLoading = userModel.isLoading;

      if (isLoaded) {
        if (!userModel.me.published && userModel.me.images.isEmpty) {
          EloNav.goSettingsImages();
          return;
        }
        EloNav.goHomeSwipe();
        return;
      }
      if (!isLoading) {
        userModel.initAll(context);
      }
    });

    return const Scaffold(
        body:
            Center(child: Loading(text: "Loading User Model For Redirect...")));
  }
}

import 'package:client/models/user_model.dart';
import 'package:client/router.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void redir(BuildContext context) {
  var userModel = Provider.of<UserModel>(context, listen: false);
  var canLoad = userModel.canLoad();
  print("canLoad: $canLoad");
  if (!canLoad) {
    print("Redirecting to login");
    EloNav.goLogin(context);
    return;
  }

  var isLoaded = userModel.isLoaded;
  var isLoading = userModel.isLoading;

  if (isLoaded) {
    if (!userModel.me.published && userModel.me.images.isEmpty) {
      print("Redirecting to settings images");
      EloNav.goSettingsImages(context);
      return;
    }
    print("Redirecting to home swipe");
    EloNav.goHomeSwipe(context);
    return;
  }
  if (!isLoading) {
    userModel.initAll(context).then(
          (_) => redir(context),
        );
  }
}

import 'package:client/components/loading.dart';
import 'package:client/models/user_model.dart';
import 'package:client/router.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UserModelLoadedGuard extends StatefulWidget {
  const UserModelLoadedGuard({super.key, required this.child});

  final Widget child;

  @override
  UserModelLoadedGuardState createState() => UserModelLoadedGuardState();
}

class UserModelLoadedGuardState extends State<UserModelLoadedGuard> {
  @override
  Widget build(BuildContext context) {
    var userModel = Provider.of<UserModel>(context, listen: true);
    if (!userModel.canLoad()) {
      EloNav.goRedir();
    }
    if (!userModel.isLoading && !userModel.isLoaded) {
      userModel.initAll(context);
      return const Loading(text: "Loading User Model...");
    }
    return widget.child;
  }
}

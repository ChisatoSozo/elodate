import 'package:client/models/user_model.dart';
import 'package:client/pages/home.dart';
import 'package:client/pages/login.dart';
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
      userModel.initAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    var userModel = Provider.of<UserModel>(context, listen: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      var canLoad = userModel.canLoad();
      if (!canLoad) {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
            (route) => false);
      }

      var isLoaded = userModel.isLoaded;

      if (isLoaded) {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
            (route) => false);
      }
    });

    return const CircularProgressIndicator();
  }
}

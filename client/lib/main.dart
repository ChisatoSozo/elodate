import 'package:client/models/home_model.dart';
import 'package:client/models/register_model.dart';
import 'package:client/pages/login.dart';
import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initLocalStorage();
  runApp(const MainApp());
  return;
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<HomeModel>(
      create: (context) => HomeModel(),
      child: ChangeNotifierProvider<RegisterModel>(
        create: (context) => RegisterModel(),
        child: MaterialApp(
          title: 'Flutter Demo',
          theme: ThemeData(
            primarySwatch: Colors.blue,
            useMaterial3: true,
          ),
          home: const LoginPage(),
        ),
      ),
    );
  }
}

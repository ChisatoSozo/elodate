import 'package:client/models/page_state_model.dart';
import 'package:client/models/register_model.dart';
import 'package:client/models/user_model.dart';
import 'package:client/pages/redir.dart';
import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initLocalStorage();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<UserModel>(
      create: (context) => UserModel(),
      child: ChangeNotifierProvider<PageStateModel>(
        create: (context) => PageStateModel(),
        child: ChangeNotifierProvider<RegisterModel>(
          create: (context) => RegisterModel(),
          child: MaterialApp(
            title: 'Competitive Dating App',
            theme: ThemeData(
              primarySwatch: Colors.blue,
              useMaterial3: true,
              visualDensity: VisualDensity.adaptivePlatformDensity,
            ),
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              primarySwatch: Colors.blue,
              useMaterial3: true,
              visualDensity: VisualDensity.adaptivePlatformDensity,
            ),
            themeMode: ThemeMode.system,
            home: const RedirPage(),
          ),
        ),
      ),
    );
  }
}

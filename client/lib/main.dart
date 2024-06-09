import 'dart:convert';

import 'package:client/models/page_state_model.dart';
import 'package:client/models/register_model.dart';
import 'package:client/models/user_model.dart';
import 'package:client/pages/redir.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:json_theme/json_theme.dart';
import 'package:localstorage/localstorage.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initLocalStorage();
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  MainAppState createState() => MainAppState();
}

class MainAppState extends State<MainApp> {
  ThemeData? lightTheme;
  ThemeData? darkTheme;

  @override
  void initState() {
    super.initState();
    loadThemes();
  }

  Future<void> loadThemes() async {
    final lightThemeString =
        await rootBundle.loadString('theme/theme_light.json');
    final darkThemeString =
        await rootBundle.loadString('theme/theme_dark.json');

    setState(() {
      lightTheme = ThemeDecoder.decodeThemeData(jsonDecode(lightThemeString));
      darkTheme = ThemeDecoder.decodeThemeData(jsonDecode(darkThemeString));
    });
  }

  @override
  Widget build(BuildContext context) {
    if (lightTheme == null || darkTheme == null) {
      return const CircularProgressIndicator(); // Loading indicator while themes are being loaded
    }

    return ChangeNotifierProvider<UserModel>(
      create: (context) => UserModel(),
      child: ChangeNotifierProvider<PageStateModel>(
        create: (context) => PageStateModel(),
        child: ChangeNotifierProvider<RegisterModel>(
          create: (context) => RegisterModel(),
          child: MaterialApp(
            title: 'elodate',
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: ThemeMode.system,
            home: const RedirPage(),
          ),
        ),
      ),
    );
  }
}

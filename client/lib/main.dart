import 'dart:async';
import 'dart:convert';

import 'package:client/components/loading.dart';
import 'package:client/models/notifications_model.dart';
import 'package:client/models/register_model.dart';
import 'package:client/models/user_model.dart';
import 'package:client/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:json_theme/json_theme.dart';
import 'package:localstorage/localstorage.dart';
import 'package:provider/provider.dart';

void main() async {
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
  bool loadingThemes = false;

  @override
  void initState() {
    super.initState();
    if (!loadingThemes) {
      loadThemes();
      loadingThemes = true;
    }
  }

  ThemeData? lightTheme;
  ThemeData? darkTheme;

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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<NotificationsModel>(
            create: (_) => NotificationsModel()),
        ChangeNotifierProvider<UserModel>(create: (_) => UserModel()),
        ChangeNotifierProvider<RegisterModel>(create: (_) => RegisterModel()),
      ],
      child: MaterialApp.router(
        title: 'elodate',
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: ThemeMode.system,
        routeInformationParser: EloRouterInfoParser(),
        routerDelegate: EloRouterDelegate(),
        builder: (context, child) {
          if (lightTheme == null || darkTheme == null) {
            return const Scaffold(
              body: Center(child: Loading(text: 'Loading themes...')),
            );
          }
          return child!;
        },
      ),
    );
  }
}

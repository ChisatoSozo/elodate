import 'package:client/models/home_model.dart';
import 'package:client/models/register_model.dart';
import 'package:client/pages/login.dart';
import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';
import 'package:provider/provider.dart';

class AppColors {
  static const Color lightCoral = Color(0xFFF28B82);
  static const Color gold = Color.fromARGB(255, 227, 183, 81);
  static const Color darkCoral = Color(0xFFE57373);
}

TextTheme appTextTheme(Color onBackground) {
  return TextTheme(
    displayLarge: TextStyle(
        fontSize: 32.0,
        fontWeight: FontWeight.bold,
        fontFamily: 'Montserrat',
        color: onBackground),
    titleLarge: TextStyle(
        fontSize: 20.0,
        fontWeight: FontWeight.bold,
        fontFamily: 'Montserrat',
        color: onBackground),
    bodyLarge:
        TextStyle(fontSize: 16.0, fontFamily: 'Roboto', color: onBackground),
    bodyMedium:
        TextStyle(fontSize: 14.0, fontFamily: 'Roboto', color: onBackground),
  );
}

InputDecorationTheme appInputDecorationTheme(Color primary) {
  return InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.0),
      borderSide: BorderSide(color: primary),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.0),
      borderSide: BorderSide(color: primary),
    ),
  );
}

ButtonThemeData appButtonTheme(Color primary) {
  return ButtonThemeData(
    buttonColor: primary,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
    textTheme: ButtonTextTheme.primary,
  );
}

IconThemeData appIconTheme(Color primary) {
  return IconThemeData(
    color: primary,
    size: 24.0,
  );
}

CardTheme appCardTheme() {
  return CardTheme(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
    elevation: 4,
  );
}

FloatingActionButtonThemeData appFloatingActionButtonTheme(Color secondary) {
  return FloatingActionButtonThemeData(
    backgroundColor: secondary,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
  );
}

final ThemeData lightTheme = ThemeData(
  colorScheme: ColorScheme.light(
    primary: AppColors.lightCoral,
    secondary: AppColors.gold,
    background: Colors.white,
    surface: Colors.grey[100]!,
    onPrimary: Colors.white,
    onSecondary: Colors.black,
    onBackground: Colors.grey[800]!,
    onSurface: Colors.grey[800]!,
  ),
  textTheme: appTextTheme(Colors.grey[800]!),
  buttonTheme: appButtonTheme(AppColors.lightCoral),
  inputDecorationTheme: appInputDecorationTheme(AppColors.lightCoral),
  iconTheme: appIconTheme(AppColors.lightCoral),
  cardTheme: appCardTheme(),
  floatingActionButtonTheme: appFloatingActionButtonTheme(AppColors.gold),
  visualDensity: VisualDensity.adaptivePlatformDensity,
);

final ThemeData darkTheme = ThemeData(
  colorScheme: ColorScheme.dark(
    primary: AppColors.darkCoral,
    secondary: AppColors.gold,
    background: Colors.grey[900]!,
    surface: Colors.grey[850]!,
    onPrimary: Colors.black,
    onSecondary: Colors.white,
    onBackground: Colors.grey[200]!,
    onSurface: Colors.grey[200]!,
  ),
  textTheme: appTextTheme(Colors.grey[200]!),
  buttonTheme: appButtonTheme(AppColors.darkCoral),
  inputDecorationTheme: appInputDecorationTheme(AppColors.darkCoral),
  iconTheme: appIconTheme(AppColors.darkCoral),
  cardTheme: appCardTheme(),
  floatingActionButtonTheme: appFloatingActionButtonTheme(AppColors.gold),
  visualDensity: VisualDensity.adaptivePlatformDensity,
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initLocalStorage();
  runApp(const MainApp());
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
          title: 'Competitive Dating App',
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: ThemeMode.system,
          home: const LoginPage(),
        ),
      ),
    );
  }
}

import 'package:client/components/elodate_scaffold.dart';
import 'package:client/models/user_model.dart';
import 'package:client/pages/home_chat.dart';
import 'package:client/pages/home_settings.dart';
import 'package:client/pages/home_swipe.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  int _selectedIndex = 1; // Default index for the center tab

  static final List<Widget> _widgetOptions = <Widget>[
    const SettingsPage(key: Key("settings")),
    const SwipePage(key: Key("swipe")),
    const ChatPage(key: Key("chat")),
  ];

  @override
  void initState() {
    super.initState();

    var userModel = Provider.of<UserModel>(context, listen: false);

    if (!userModel.isLoading && !userModel.isLoaded) {
      userModel.initAll(context);
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    var isLoaded = Provider.of<UserModel>(context, listen: true).isLoaded;

    if (!isLoaded) {
      return const CircularProgressIndicator();
    }

    var me = Provider.of<UserModel>(context, listen: true).me;

    if (!me.published) {
      return const ElodateScaffold(body: SettingsPage(key: Key("settings")));
    }

    return ElodateScaffold(
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: me.published
          ? BottomNavigationBar(
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings),
                  label: 'Settings',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.favorite),
                  label: 'Swipe',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.chat),
                  label: 'Chats',
                ),
              ],
              currentIndex: _selectedIndex,
              selectedItemColor: Colors.red[800],
              onTap: _onItemTapped,
            )
          : null,
    );
  }
}

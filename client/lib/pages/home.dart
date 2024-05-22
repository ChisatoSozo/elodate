import 'package:client/components/responsive_container.dart';
import 'package:client/models/home_model.dart';
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
    const SettingsPage(),
    const SwipePage(),
    const ChatPage(),
  ];

  @override
  void initState() {
    super.initState();

    var homeModel = Provider.of<HomeModel>(context, listen: false);

    if (!homeModel.isLoading && !homeModel.isLoaded) {
      homeModel.initAll();
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    var isLoaded = Provider.of<HomeModel>(context, listen: true).isLoaded;

    if (!isLoaded) {
      return const CircularProgressIndicator();
    }

    var me = Provider.of<HomeModel>(context, listen: true).me;

    if (!me.published) {
      if (_selectedIndex != 0) {
        _selectedIndex = 0;
      }
    }

    return Scaffold(
      body: Center(
        child: ResponsiveContainer(
          child: _widgetOptions.elementAt(_selectedIndex),
        ),
      ),
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

import 'package:client/api/pkg/lib/api.dart';
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
  UserWithImagesAndEloAndUuid? _me;
  bool _isLoading = true;
  bool _hasError = false;

  static final List<Widget> _widgetOptions = <Widget>[
    const SettingsPage(),
    const SwipePage(),
    const ChatPage(),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final homeModel = Provider.of<HomeModel>(context, listen: false);
      final me = await homeModel.getMe();
      setState(() {
        _me = me;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return const Center(child: Text("Error loading data"));
    }

    if (_me == null) {
      return const Center(child: Text("No data available"));
    }

    if (_me!.user.published == null || !_me!.user.published!) {
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
      bottomNavigationBar: (_me!.user.published != null && _me!.user.published!)
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

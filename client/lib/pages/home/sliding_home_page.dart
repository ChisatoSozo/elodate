import 'package:client/pages/home/home_chat.dart';
import 'package:client/pages/home/home_swipe.dart';
import 'package:client/pages/home/settings/settings_categories.dart';
import 'package:client/router.dart';
import 'package:flutter/material.dart';

class SlidingHomePage extends StatefulWidget {
  final String tab;

  const SlidingHomePage({super.key, required this.tab});

  @override
  SlidingHomePageState createState() => SlidingHomePageState();
}

class SlidingHomePageState extends State<SlidingHomePage> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = _getIndexFromLocation(widget.tab);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void didUpdateWidget(SlidingHomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tab != widget.tab) {
      final newIndex = _getIndexFromLocation(widget.tab);
      if (newIndex != _currentIndex) {
        _pageController.jumpToPage(newIndex);
        setState(() {
          _currentIndex = newIndex;
        });
      }
    }
  }

  int _getIndexFromLocation(String tab) {
    switch (tab) {
      case 'settings':
        return 0;
      case 'swipe':
        return 1;
      case 'chat':
        return 2;
      default:
        return 1; // Default to swipe page
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    _updateRoute(index);
  }

  void _onBottomNavTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _updateRoute(int index) {
    switch (index) {
      case 0:
        EloNav.goHomeSettings(context);
        break;
      case 1:
        EloNav.goHomeSwipe(context);
        break;
      case 2:
        EloNav.goHomeChat(context);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              children: const [
                SingleChildScrollView(child: SettingsCategories()),
                SwipePage(),
                SingleChildScrollView(child: ChatPage()),
              ],
            ),
          ),
          BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onBottomNavTapped,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: 'Settings',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Swipe',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.chat),
                label: 'Chat',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

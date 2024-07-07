import 'package:client/main.dart';
import 'package:client/pages/chat_screen.dart';
import 'package:client/pages/home/settings/prefer_count_and_save.dart';
import 'package:client/pages/home/settings/settings_basic.dart';
import 'package:client/utils/utils.dart';
import 'package:flutter/material.dart';

import '../components/bug_report_button.dart';
import '../components/loading.dart';
import '../components/user_model_loaded_guard.dart';
import '../pages/home/settings/settings_category.dart';
import '../pages/home/sliding_home_page.dart';
import '../pages/login.dart';
import '../pages/redir.dart';
import '../pages/register_birthdate.dart';
import '../pages/register_finish.dart';
import '../pages/register_password.dart';
import '../pages/register_start.dart';
import '../pages/settings_flow.dart';
import '../pages/settings_flow_images.dart';
import 'page_route_no_anim.dart';
import 'page_route_slide_anim.dart';

enum RouteType { home, homeSettings, chat, other, settingsFlow }

class EloRouterDelegate extends RouterDelegate<String>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<String> {
  // Configuration

  static const String initialRoute = '/';
  static const List<String> noScrollRoutes = ['/home/swipe', '/chat'];

  // Route titles
  static final Map<String, String?> routeTitles = {
    '/home/swipe': null,
    '/home/chat': null,
    '/home/settings': null,
    '/login': null,
    '/register': 'Register',
    '/settings': 'Settings',
    '/settings_images': 'Images',
    '/register_password': 'Register Password',
    '/register_birthdate': 'Register Birthdate',
    '/register_finish': 'Register Finish',
  };

  @override
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final List<String> _routeStack = [initialRoute];

  @override
  String get currentConfiguration => _routeStack.last;

  @override
  Widget build(BuildContext context) {
    _handleInitialRedirect(context);
    return Navigator(
      key: navigatorKey,
      pages: _buildPages(context),
      onPopPage: _handlePopPage,
    );
  }

  void _handleInitialRedirect(BuildContext context) {
    if (_routeStack.last == initialRoute) {
      WidgetsBinding.instance.addPostFrameCallback((_) => redir(context));
    }
  }

  List<Page> _buildPages(BuildContext context) {
    return [
      for (final route in _routeStack)
        _createPage(_getPageForRoute(route), context, route),
    ];
  }

  bool _handlePopPage(Route<dynamic> route, dynamic result) {
    if (!route.didPop(result)) return false;
    pop();
    return true;
  }

  @override
  Future<void> setInitialRoutePath(String configuration) async {}

  @override
  Future<void> setNewRoutePath(String configuration) async {
    //is it one back? Then pop instead of set
    if (_routeStack.length > 1 &&
        configuration == _routeStack[_routeStack.length - 2]) {
      pop();
    } else {
      push(configuration);
    }
    notifyListeners();
  }

  void push(String newRoute) {
    final RouteType newRouteType = _getRouteType(newRoute);
    final RouteType currentRouteType = _getRouteType(_routeStack.last);

    if (newRouteType == RouteType.home && currentRouteType == RouteType.home) {
      _routeStack.last = newRoute;
    } else if (_routeStack.isNotEmpty && _routeStack.last != newRoute) {
      _routeStack.add(newRoute);
    }
    notifyListeners();
  }

  void go(String newRoute) {
    _routeStack.clear();
    _routeStack.add(newRoute);
    notifyListeners();
  }

  void pop() {
    if (_routeStack.length > 1) {
      _routeStack.removeLast();
      notifyListeners();
    }
  }

  void replaceLastRoute(String newRoute) {
    if (_routeStack.isNotEmpty) {
      _routeStack.last = newRoute;
      notifyListeners();
    }
  }

  RouteType _getRouteType(String route) {
    if (route.startsWith('/home/settings/')) {
      return RouteType.homeSettings;
    } else if (route.startsWith('/chat/')) {
      return RouteType.chat;
    } else if (route.startsWith('/home/')) {
      return RouteType.home;
    } else if (route.startsWith('/settings/')) {
      return RouteType.settingsFlow;
    } else {
      return RouteType.other;
    }
  }

  Page _createPage(Widget child, BuildContext context, String route) {
    final routeKey = _getRouteType(route) == RouteType.home ? '/home' : route;
    child = _wrapWithScroll(context, child, route);
    final content = _buildPageContent(context, child, route);
    return _getRouteType(route) == RouteType.home
        ? PageRouteNoAnim(key: ValueKey(routeKey), child: content)
        : PageRouteSlideAnim(key: ValueKey(routeKey), child: content);
  }

  Widget _wrapWithScroll(BuildContext context, Widget child, String route) {
    if (noScrollRoutes.any((r) => route.startsWith(r))) {
      return Column(
        children: [
          Expanded(
            child: child,
          ),
        ],
      );
    }
    var pageWidth = calcPageWidth(context);
    return Center(
      child: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: pageWidth),
            child: Column(
              children: [
                const SizedBox(height: 20),
                child,
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageContent(BuildContext context, Widget child, String route) {
    var routeType = _getRouteType(route);
    Widget? bottomNav;

    var pageWidth = calcPageWidth(context);

    if (routeType == RouteType.homeSettings) {
      bottomNav = Container(
          constraints: BoxConstraints(maxWidth: pageWidth),
          child: const Center(child: PreferCountAndSave()));
    }
    if (routeType == RouteType.settingsFlow) {
      bottomNav = Container(
        constraints: BoxConstraints(maxWidth: pageWidth),
        child: const PreferenceCounters(),
      );
    }
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Scaffold(
          appBar: _buildAppBar(route),
          resizeToAvoidBottomInset: true,
          body: Column(
            children: [
              Expanded(child: child),
              if (bottomNav != null) ...[
                bottomNav,
                const SizedBox(height: 20),
              ],
            ],
          ),
        ),
        const BugReportButton()
      ],
    );
  }

  PreferredSizeWidget? _buildAppBar(String route) {
    final title = _getTitleForRoute(route);
    return title == null ? null : AppBar(title: Text(title));
  }

  String? _getTitleForRoute(String route) {
    if (route.startsWith("/home/settings")) {
      final category = route.split("/").last;
      return category[0].toUpperCase() + category.substring(1);
    }
    return routeTitles[route];
  }

  Widget _wrapInUserModelLoadedGuard(Widget child) {
    return UserModelLoadedGuard(child: child);
  }

  Widget _getPageForRoute(String route) {
    switch (_getRouteType(route)) {
      case RouteType.home:
        return _buildHomePage(route);
      case RouteType.homeSettings:
        return _buildSettingsCategoryPage(route);
      case RouteType.chat:
        return _buildChatPage(route);
      case RouteType.settingsFlow:
        return _buildSettingsFlowPage(route);
      case RouteType.other:
        return _buildStaticPage(route);
    }
  }

  Widget _buildSettingsFlowPage(String route) {
    final parts = route.split("/");
    return _wrapInUserModelLoadedGuard(SettingsFlowPage(
      categoryIndex: int.parse(parts[2]),
      groupIndex: int.parse(parts[3]),
    ));
  }

  Widget _buildHomePage(String route) {
    final tab = route.split("/")[2];
    return _wrapInUserModelLoadedGuard(SlidingHomePage(tab: tab));
  }

  Widget _buildSettingsCategoryPage(String route) {
    final category = route.split("/")[3];
    return _wrapInUserModelLoadedGuard(
      category == constants["basicCategoryName"]
          ? const BasicSettings()
          : SettingsCategory(category: category),
    );
  }

  Widget _buildChatPage(String route) {
    final id = route.split("/")[2];
    final displayName = route.split("/")[3];
    return _wrapInUserModelLoadedGuard(
      ChatScreen(chatId: id, displayName: displayName),
    );
  }

  Widget _buildStaticPage(String route) {
    switch (route) {
      case '/':
        return const Loading(text: 'Loading redir...');
      case '/login':
        return const LoginPage();
      case '/register':
        return const RegisterStartPage();
      case '/register_password':
        return const RegisterPasswordPage();
      case '/register_birthdate':
        return const RegisterBirthdatePage();
      case '/register_finish':
        return const RegisterFinishPage();
      case '/settings_images':
        return const SettingsFlowImagesPage();
      default:
        return Text("404, can't find $route");
    }
  }
}

import 'package:client/components/bug_report_button.dart';
import 'package:client/components/loading.dart';
import 'package:client/components/user_model_loaded_guard.dart';
import 'package:client/pages/home/sliding_home_page.dart';
import 'package:client/pages/login.dart';
import 'package:client/pages/redir.dart';
import 'package:client/pages/register_birthdate.dart';
import 'package:client/pages/register_finish.dart';
import 'package:client/pages/register_password.dart';
import 'package:client/pages/register_start.dart';
import 'package:client/pages/settings_flow.dart';
import 'package:client/pages/settings_flow_images.dart';
import 'package:client/router/page_route_no_anim.dart';
import 'package:client/router/page_route_slide_anim.dart';
import 'package:flutter/material.dart';

String? titleFromPath(String path) {
  if (path.startsWith("/home/settings")) {
    var category = path.split("/").last;
    return category[0].toUpperCase() + category.substring(1);
  }
  switch (path) {
    case '/home/swipe':
      return null;
    case '/home/chat':
      return null;
    case '/home/settings':
      return null;
    case '/login':
      return null;
    case '/register':
      return 'Register';
    case '/settings':
      return 'Settings';
    case '/settings_images':
      return 'Images';
    case '/register_password':
      return 'Register Password';
    case '/register_birthdate':
      return 'Register Birthdate';
    case '/register_finish':
      return 'Register Finish';
    default:
      return null;
  }
}

//Router info parser

class EloRouterInfoParser extends RouteInformationParser<String> {
  @override
  Future<String> parseRouteInformation(
      RouteInformation routeInformation) async {
    print("prarsing $routeInformation");
    return routeInformation.uri.path;
  }

  @override
  RouteInformation? restoreRouteInformation(String configuration) {
    print("restoring $configuration");
    return RouteInformation(uri: Uri.parse(configuration));
  }
}

class EloRouterDelegate extends RouterDelegate<String>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<String> {
  @override
  final GlobalKey<NavigatorState> navigatorKey;

  List<String> _routeStack = ['/'];

  EloRouterDelegate() : navigatorKey = GlobalKey<NavigatorState>();

  @override
  String get currentConfiguration => _routeStack.last;

  @override
  Widget build(BuildContext context) {
    if (_routeStack.last == '/') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        redir(context);
      });
    }
    return Navigator(
      key: navigatorKey,
      pages: [
        for (final route in _routeStack)
          _wrapPage(_getPageForRoute(route), context, route),
      ],
      onPopPage: (route, result) {
        if (!route.didPop(result)) {
          return false;
        }
        pop();
        return true;
      },
    );
  }

  @override
  Future<void> setInitialRoutePath(String configuration) async {}

  @override
  Future<void> setNewRoutePath(String configuration) async {
    print("setting new route path $configuration");
    _routeStack = [configuration];
    notifyListeners();
  }

  void push(String newRoute) {
    print("pushing $newRoute");
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
    print("replacing last route with $newRoute");
    if (_routeStack.isNotEmpty) {
      _routeStack.last = newRoute;
      notifyListeners();
    }
  }

  Page _wrapPage(Widget child, BuildContext context, String route) {
    var content = Stack(
      clipBehavior: Clip.none,
      children: [
        Scaffold(
          appBar: titleFromPath(route) == null
              ? null
              : AppBar(
                  title: Text(titleFromPath(route) ?? ''),
                ),
          resizeToAvoidBottomInset: true,
          body: Center(
            child: SingleChildScrollView(
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: child,
                ),
              ),
            ),
          ),
        ),
        const BugReportButton()
      ],
    );
    if (route.startsWith('/home/')) {
      return PageRouteNoAnim(child: content);
    }

    return PageRouteSlideAnim(child: content);
  }

  Widget _wrapInUserModelLoadedGuard(Widget child) {
    return UserModelLoadedGuard(child: child);
  }

  //this is also where user guards are added
  Widget _getPageForRoute(String route) {
    print("getting page for route $route");
    if (route.startsWith('/settings/')) {
      //form of /settings/categoryIndex/groupIndex
      var categoryIndex = int.parse(route.split("/")[2]);
      var groupIndex = int.parse(route.split("/")[3]);
      return _wrapInUserModelLoadedGuard(SettingsFlowPage(
          categoryIndex: categoryIndex, groupIndex: groupIndex));
    }

    if (route.startsWith('/home/')) {
      var tab = route.split("/")[2];
      return SlidingHomePage(tab: tab);
    }

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

class EloNav {
  static void _go(BuildContext context, String path) {
    print("commanded to go to $path");
    (Router.of(context).routerDelegate as EloRouterDelegate).push(path);
  }

  static void _pop(BuildContext context) {
    (Router.of(context).routerDelegate as EloRouterDelegate).pop();
  }

  static void goHomeSwipe(BuildContext context) => _go(context, '/home/swipe');
  static void goHomeChat(BuildContext context) => _go(context, '/home/chat');
  static void goHomeSettings(BuildContext context) =>
      _go(context, '/home/settings');
  static void goLogin(BuildContext context) => _go(context, '/login');
  static void goRegister(BuildContext context) => _go(context, '/register');
  static void goSettings(
          BuildContext context, int categoryIndex, int groupIndex) =>
      _go(context, '/settings/$categoryIndex/$groupIndex');
  static void goSettingsImages(BuildContext context) =>
      _go(context, '/settings_images');
  static void goChat(BuildContext context, String id, String displayName) =>
      _go(context, '/chat/$id');
  static void goRegisterPassword(BuildContext context) =>
      _go(context, '/register_password');
  static void goRegisterBirthdate(BuildContext context) =>
      _go(context, '/register_birthdate');
  static void goRegisterFinish(BuildContext context) =>
      _go(context, '/register_finish');
  static void goHomeSettingsCategory(BuildContext context, String category) =>
      _go(context, '/home/settings/$category');
  static void goRedir(BuildContext context) => redir(context);
  static void goBack(BuildContext context) => _pop(context);
}

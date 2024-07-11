import 'package:client/pages/redir.dart';
import 'package:flutter/material.dart';

import 'page_builder.dart';
import 'route_configuration.dart';
import 'route_handlers.dart';

class EloRouterDelegate extends RouterDelegate<String>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<String> {
  @override
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final List<String> _routeStack = [RouteConfiguration.initialRoute];

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
    if (_routeStack.last == RouteConfiguration.initialRoute) {
      WidgetsBinding.instance.addPostFrameCallback((_) => redir(context));
    }
  }

  List<Page> _buildPages(BuildContext context) {
    return [
      for (final route in _routeStack)
        PageBuilder.createPage(
          RouteHandlers.getPageForRoute(route),
          context,
          route,
        ),
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
    if (_routeStack.length > 1 &&
        configuration == _routeStack[_routeStack.length - 2]) {
      pop();
    } else {
      push(configuration);
    }
    notifyListeners();
  }

  void push(String newRoute) {
    final RouteType newRouteType = RouteConfiguration.getRouteType(newRoute);
    final RouteType currentRouteType =
        RouteConfiguration.getRouteType(_routeStack.last);

    if (newRouteType == RouteType.home && currentRouteType == RouteType.home) {
      _routeStack.last = newRoute;
    } else if (_routeStack.isNotEmpty && _routeStack.last != newRoute) {
      _routeStack.add(newRoute);
    }
    notifyListeners();
  }

  void go(String newRoute) {
    _routeStack
      ..clear()
      ..add(newRoute);
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
}

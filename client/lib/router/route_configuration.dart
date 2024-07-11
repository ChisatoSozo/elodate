enum RouteType { home, homeSettings, chat, other, settingsFlow }

class RouteConfiguration {
  static const String initialRoute = '/';
  static const List<String> noScrollRoutes = ['/home/swipe', '/chat'];

  static final Map<String, String?> routeTitles = {
    '/home/swipe': null,
    '/home/chat': null,
    '/home/settings': null,
    '/login': null,
    '/register': 'Register',
    '/settings': 'Settings',
    '/manage_account': 'Manage Account',
    '/settings_images': 'Images',
    '/register_password': 'Register Password',
    '/register_birthdate': 'Register Birthdate',
    '/register_finish': 'Register Finish',
  };

  static RouteType getRouteType(String route) {
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

  static String? getTitleForRoute(String route) {
    if (route.startsWith("/home/settings")) {
      final category = route.split("/").last;
      return category[0].toUpperCase() + category.substring(1);
    }
    return routeTitles[route];
  }
}

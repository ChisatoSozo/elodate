import 'package:client/components/bug_report_button.dart';
import 'package:client/components/user_model_loaded_guard.dart';
import 'package:client/pages/home_chat.dart';
import 'package:client/pages/home_chat_single.dart';
import 'package:client/pages/home_settings.dart';
import 'package:client/pages/home_swipe.dart';
import 'package:client/pages/login.dart';
import 'package:client/pages/redir.dart';
import 'package:client/pages/register_birthdate.dart';
import 'package:client/pages/register_finish.dart';
import 'package:client/pages/register_password.dart';
import 'package:client/pages/register_start.dart';
import 'package:client/pages/settings_flow.dart';
import 'package:client/pages/settings_flow_images.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class Page {
  final String path;
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? bottomNav;
  final AppBar? appBar;
  final List<Page>? routes;

  Page({
    required this.path,
    required this.builder,
    this.bottomNav,
    this.appBar,
    this.routes,
  });
}

final pages = [
  Page(
    path: '/home',
    builder: (context, child) => child!,
    routes: [
      Page(
        path: '/home/swipe',
        builder: (context, _) => const UserModelLoadedGuard(child: SwipePage()),
      ),
      Page(
        path: '/home/chat',
        builder: (context, _) => const UserModelLoadedGuard(child: ChatPage()),
      ),
      Page(
        path: '/home/settings',
        builder: (context, _) =>
            const UserModelLoadedGuard(child: SettingsPage()),
      ),
    ],
    bottomNav: BottomNavigationBar(
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.favorite),
          label: 'Swipe',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat),
          label: 'Chat',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ],
    ),
  ),
  Page(
    path: '/register',
    builder: (context, _) => const RegisterStartPage(),
    appBar: AppBar(
      title: const Text('Register'),
    ),
  ),
  Page(
    path: '/register/password',
    builder: (context, _) => const RegisterPasswordPage(),
    appBar: AppBar(
      title: const Text('Register Password'),
    ),
  ),
  Page(
    path: '/login',
    builder: (context, _) => const LoginPage(),
  ),
  Page(
    path: '/register/birthdate',
    builder: (context, _) => const RegisterBirthdatePage(),
    appBar: AppBar(
      title: const Text('Register Birthdate'),
    ),
  ),
  Page(
    path: '/register/finish',
    builder: (context, _) => const RegisterFinishPage(),
    appBar: AppBar(
      title: const Text('Register Finish'),
    ),
  ),
  Page(
    path: '/chat/:id',
    builder: (context, _) => UserModelLoadedGuard(
      child: ChatScreen(
        chatId: GoRouterState.of(context).pathParameters['id'] ?? '',
        displayName:
            GoRouterState.of(context).uri.queryParameters['displayName'] ?? '',
      ),
    ),
  ),
  Page(
    path: '/settings',
    builder: (context, _) =>
        const UserModelLoadedGuard(child: SettingsFlowPage()),
    appBar: AppBar(
      title: const Text('Settings'),
    ),
  ),
  Page(
    path: '/settings/images',
    builder: (context, _) => const SettingsFlowImagesPage(),
    appBar: AppBar(
      title: const Text('Settings Images'),
    ),
  ),
];

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'shell');

final routes = pages
    .map((page) => page.routes == null
        ? GoRoute(
            path: page.path,
            name: page.path,
            builder: (context, state) => page.builder(context, null),
          )
        : ShellRoute(
            navigatorKey: GlobalKey<NavigatorState>(),
            builder: (context, state, child) {
              return page.builder(context, child);
            },
            routes: page.routes!
                .map((subPage) => GoRoute(
                      path: subPage.path,
                      name: subPage.path,
                      builder: (context, state) =>
                          subPage.builder(context, null),
                    ))
                .toList(),
          ))
    .toList();

final GoRouter router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  routes: [
    GoRoute(
      path: '/',
      name: 'redirect',
      builder: (_, __) => const RedirPage(),
    ),
    ShellRoute(
      parentNavigatorKey: _rootNavigatorKey,
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        var topRoute = "/${state.uri.pathSegments[0]}";

        return Stack(
          children: [
            Scaffold(
              appBar:
                  //check if the page has an app bar, if not return null
                  pages.where((page) => page.path == topRoute).isEmpty
                      ? null
                      : pages
                          .firstWhere((page) => page.path == topRoute)
                          .appBar,
              bottomNavigationBar:
                  //check if the page has a bottom nav, if not return null
                  pages.where((page) => page.path == topRoute).isEmpty
                      ? null
                      : pages
                          .firstWhere((page) => page.path == topRoute)
                          .bottomNav,
              resizeToAvoidBottomInset: true,
              body: Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: SizedBox(
                        width: constraints.maxWidth,
                        child: Center(
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 400),
                            margin: const EdgeInsets.symmetric(horizontal: 24),
                            child: child,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const BugReportButton()
          ],
        );
      },
      routes: routes,
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text('Error: ${state.error}'),
    ),
  ),
);

class EloNav {
  static void _go(BuildContext context, String path,
      [Map<String, String>? params]) {
    final uri = Uri(path: path, queryParameters: params);
    GoRouter.of(context).go(uri.toString());
  }

  static void goHomeSwipe(BuildContext context) => _go(context, '/home/swipe');
  static void goHomeChat(BuildContext context) => _go(context, '/home/chat');
  static void goHomeSettings(BuildContext context) =>
      _go(context, '/home/settings');
  static void goLogin(BuildContext context) => _go(context, '/login');
  static void goRegister(BuildContext context) => _go(context, '/register');
  static void goSettings(BuildContext context) => _go(context, '/settings');
  static void goSettingsImages(BuildContext context) =>
      _go(context, '/settings/images');
  static void goChat(BuildContext context, String id, String displayName) =>
      _go(context, '/chat/$id', {'displayName': displayName});
  static void goRegisterPassword(BuildContext context) =>
      _go(context, '/register/password');
  static void goRegisterBirthdate(BuildContext context) =>
      _go(context, '/register/birthdate');
  static void goRegisterFinish(BuildContext context) =>
      _go(context, '/register/finish');
  static void goRedir(BuildContext context) => _go(context, '/');
  static void goBack(BuildContext context) => GoRouter.of(context).pop();
}

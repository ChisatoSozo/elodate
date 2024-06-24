import 'package:client/components/bug_report_button.dart';
import 'package:client/components/user_model_loaded_guard.dart';
import 'package:client/pages/chat_screen.dart';
import 'package:client/pages/home/settings/settings_basic.dart';
import 'package:client/pages/home/settings/settings_category.dart';
import 'package:client/pages/home/sliding_home_page.dart';
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

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _mainShellNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'shell');
final GlobalKey<NavigatorState> _scrollableShellNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'scroll');

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
        navigatorKey: _mainShellNavigatorKey,
        builder: (context, state, child) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Scaffold(resizeToAvoidBottomInset: true, body: child),
              const BugReportButton()
            ],
          );
        },
        routes: [
          //home shell
          GoRoute(
            path: '/home/:tab',
            builder: (context, state) => UserModelLoadedGuard(
              child: SlidingHomePage(tab: state.pathParameters['tab']!),
            ),
          ),

          ShellRoute(
            parentNavigatorKey: _mainShellNavigatorKey,
            navigatorKey: _scrollableShellNavigatorKey,
            builder: (context, state, child) {
              return Scaffold(
                appBar: AppBar(
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => EloNav.goBack(),
                  ),
                  title: Center(
                    child: (state.topRoute?.name ?? 'Name error')
                            .startsWith('param:')
                        ? Text(state.pathParameters[
                            state.topRoute?.name!.split(':')[1]]!)
                        : (state.topRoute?.name ?? "Name error")
                                .startsWith('qparam:')
                            ? Text(state.uri.queryParameters[
                                state.topRoute?.name!.split(':')[1]]!)
                            : Text(state.topRoute?.name ?? "Name error"),
                  ),
                ),
                body: SingleChildScrollView(
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(
                        maxWidth: 400,
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          child,
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
            routes: [
              GoRoute(
                path: '/home/settings/basic',
                name: 'Basic Settings',
                builder: (context, state) => UserModelLoadedGuard(
                  child: BasicSettings(
                    onModified: () {},
                  ),
                ),
              ),
              GoRoute(
                path: '/home/settings/:category',
                name: 'param:category',
                builder: (context, state) => UserModelLoadedGuard(
                  child: SettingsCategory(
                    category: state.pathParameters['category']!,
                    onModified: () {},
                  ),
                ),
              ),
              GoRoute(
                parentNavigatorKey: _scrollableShellNavigatorKey,
                path: '/login',
                name: 'Login',
                builder: (context, state) => const LoginPage(),
              ),
              GoRoute(
                name: 'Register',
                parentNavigatorKey: _scrollableShellNavigatorKey,
                path: '/register',
                builder: (context, state) => const RegisterStartPage(),
              ),
              GoRoute(
                name: 'Register Password',
                parentNavigatorKey: _scrollableShellNavigatorKey,
                path: '/register_password',
                builder: (context, state) => const RegisterPasswordPage(),
              ),
              GoRoute(
                name: 'Register Birthdate',
                parentNavigatorKey: _scrollableShellNavigatorKey,
                path: '/register_birthdate',
                builder: (context, state) => const RegisterBirthdatePage(),
              ),
              GoRoute(
                name: 'Register Finish',
                parentNavigatorKey: _scrollableShellNavigatorKey,
                path: '/register_finish',
                builder: (context, state) => const RegisterFinishPage(),
              ),
              GoRoute(
                name: 'Settings',
                parentNavigatorKey: _scrollableShellNavigatorKey,
                path: '/settings',
                builder: (context, state) => const SettingsFlowPage(),
              ),
              GoRoute(
                name: 'Images',
                parentNavigatorKey: _scrollableShellNavigatorKey,
                path: '/settings_images',
                builder: (context, state) => const SettingsFlowImagesPage(),
              ),
              GoRoute(
                name: 'qparam:displayName',
                parentNavigatorKey: _scrollableShellNavigatorKey,
                path: '/chat/:id',
                builder: (context, state) => UserModelLoadedGuard(
                  child: ChatScreen(
                    chatId: state.pathParameters['id'] ?? '',
                    displayName: state.uri.queryParameters['displayName'] ?? '',
                  ),
                ),
              ),
            ],
          ),
        ]),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text('Error: ${state.error}'),
    ),
  ),
);

class EloNav {
  static void _go(String path, [Map<String, String>? params]) {
    final uri = Uri(path: path, queryParameters: params);
    var context = _rootNavigatorKey.currentContext;
    GoRouter.of(context!).push(uri.toString());
  }

  static void goHomeSwipe() => _go('/home/swipe');
  static void goHomeChat() => _go('/home/chat');
  static void goHomeSettings() => _go('/home/settings');
  static void goLogin() => _go('/login');
  static void goRegister() => _go('/register');
  static void goSettings() => _go('/settings');
  static void goSettingsImages() => _go('/settings_images');
  static void goChat(String id, String displayName) =>
      _go('/chat/$id', {'displayName': displayName});
  static void goRegisterPassword() => _go('/register_password');
  static void goRegisterBirthdate() => _go('/register_birthdate');
  static void goRegisterFinish() => _go('/register_finish');
  static void goHomeSettingsCategory(String category) =>
      _go('/home/settings/$category');
  static void goRedir() => _go('/');
  static void goBack() => GoRouter.of(_rootNavigatorKey.currentContext!).pop();
}

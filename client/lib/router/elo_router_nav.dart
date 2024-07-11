import 'package:client/pages/redir.dart';
import 'package:flutter/material.dart';

import 'elo_router_delegate.dart';

class EloNav {
  static void _push(BuildContext context, String path) {
    (Router.of(context).routerDelegate as EloRouterDelegate).push(path);
  }

  static void _go(BuildContext context, String path) {
    (Router.of(context).routerDelegate as EloRouterDelegate).go(path);
  }

  static void _pop(BuildContext context) {
    (Router.of(context).routerDelegate as EloRouterDelegate).pop();
  }

  static String? getChatId(BuildContext context) {
    //does the current route start with /chat/?
    EloRouterDelegate? delegate =
        Router.of(context).routerDelegate as EloRouterDelegate;
    if (delegate.currentConfiguration.startsWith('/chat/')) {
      return delegate.currentConfiguration.split('/')[2];
    }
    return null;
  }

  static void goHomeSwipe(BuildContext context) =>
      _push(context, '/home/swipe');
  static void goHomeChat(BuildContext context) => _push(context, '/home/chat');
  static void goHomeSettings(BuildContext context) =>
      _push(context, '/home/settings');
  static void goManageAccount(BuildContext context) =>
      _push(context, '/manage_account');
  static void goLogin(BuildContext context) => _go(context, '/login');
  static void goRegister(BuildContext context) => _push(context, '/register');
  static void goSettings(
          BuildContext context, int categoryIndex, int groupIndex) =>
      _push(context, '/settings/$categoryIndex/$groupIndex');
  static void goSettingsImages(BuildContext context) =>
      _push(context, '/settings_images');
  static void goChat(BuildContext context, String id, String displayName) =>
      _push(context, '/chat/$id/$displayName');

  static void goRegisterPassword(BuildContext context) =>
      _push(context, '/register_password');
  static void goRegisterBirthdate(BuildContext context) =>
      _push(context, '/register_birthdate');
  static void goRegisterFinish(BuildContext context) =>
      _push(context, '/register_finish');
  static void goHomeSettingsCategory(BuildContext context, String category) =>
      _push(context, '/home/settings/$category');
  static void goRedir(BuildContext context) => redir(context);
  static void goBack(BuildContext context) => _pop(context);
  static String currentRoute(BuildContext context) =>
      (Router.of(context).routerDelegate as EloRouterDelegate)
          .currentConfiguration;
}

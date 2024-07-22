import 'package:client/components/loading.dart';
import 'package:client/components/user_model_loaded_guard.dart';
import 'package:client/main.dart';
import 'package:client/pages/chat_screen.dart';
import 'package:client/pages/home/settings/settings_basic.dart';
import 'package:client/pages/home/settings/settings_category.dart';
import 'package:client/pages/home/sliding_home_page.dart';
import 'package:client/pages/login.dart';
import 'package:client/pages/manage_account.dart';
import 'package:client/pages/register_birthdate.dart';
import 'package:client/pages/register_finish.dart';
import 'package:client/pages/register_password.dart';
import 'package:client/pages/register_start.dart';
import 'package:client/pages/settings_flow.dart';
import 'package:client/pages/settings_flow_explanation.dart';
import 'package:client/pages/settings_flow_images.dart';
import 'package:flutter/material.dart';

import 'route_configuration.dart';

class RouteHandlers {
  static Widget getPageForRoute(String route) {
    switch (RouteConfiguration.getRouteType(route)) {
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

  static Widget _wrapInUserModelLoadedGuard(Widget child) {
    return UserModelLoadedGuard(child: child);
  }

  static Widget _buildSettingsFlowPage(String route) {
    final parts = route.split("/");
    return _wrapInUserModelLoadedGuard(SettingsFlowPage(
      categoryIndex: int.parse(parts[2]),
      groupIndex: int.parse(parts[3]),
    ));
  }

  static Widget _buildHomePage(String route) {
    final tab = route.split("/")[2];
    return _wrapInUserModelLoadedGuard(SlidingHomePage(tab: tab));
  }

  static Widget _buildSettingsCategoryPage(String route) {
    final category = route.split("/")[3];
    return _wrapInUserModelLoadedGuard(
      category == constants["basicCategoryName"]
          ? const BasicSettings()
          : SettingsCategory(category: category),
    );
  }

  static Widget _buildChatPage(String route) {
    final id = route.split("/")[2];
    final displayName = route.split("/")[3];
    return _wrapInUserModelLoadedGuard(
      ChatScreen(chatId: id, displayName: displayName),
    );
  }

  static Widget _buildStaticPage(String route) {
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
      case '/settings_flow_explainer':
        return const SettingsFlowExplainerPage();
      case '/manage_account':
        return const ManageAccountPage();
      default:
        return Text("404, can't find $route");
    }
  }
}

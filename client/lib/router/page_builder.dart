import 'package:client/components/bug_report_button.dart';
import 'package:client/components/spacer.dart';
import 'package:client/pages/home/settings/prefer_count_and_save.dart';
import 'package:client/utils/utils.dart';
import 'package:flutter/material.dart';

import 'route_configuration.dart';

class PageBuilder {
  static Page createPage(Widget child, BuildContext context, String route) {
    final routeKey = RouteConfiguration.getRouteType(route) == RouteType.home
        ? '/home'
        : route;
    child = _wrapWithScroll(context, child, route);
    final content = _buildPageContent(context, child, route);
    return RouteConfiguration.getRouteType(route) == RouteType.home
        ? PageRouteNoAnim(key: ValueKey(routeKey), child: content)
        : PageRouteSlideAnim(key: ValueKey(routeKey), child: content);
  }

  static Widget _wrapWithScroll(
      BuildContext context, Widget child, String route) {
    if (RouteConfiguration.noScrollRoutes.any((r) => route.startsWith(r))) {
      return Column(
        children: [
          Expanded(child: child),
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
                const VerticalSpacer(),
                child,
                const VerticalSpacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildPageContent(
      BuildContext context, Widget child, String route) {
    var routeType = RouteConfiguration.getRouteType(route);
    Widget? bottomNav;

    var pageWidth = calcPageWidth(context);

    if (routeType == RouteType.homeSettings) {
      bottomNav = Container(
        constraints: BoxConstraints(maxWidth: pageWidth),
        child: const Center(child: PreferCountAndSave()),
      );
    }
    if (routeType == RouteType.settingsFlow) {
      bottomNav = Container(
        constraints: BoxConstraints(maxWidth: pageWidth),
        child: const PreferCountAndElo(),
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
                const VerticalSpacer(),
              ],
            ],
          ),
        ),
        const BugReportButton()
      ],
    );
  }

  static PreferredSizeWidget? _buildAppBar(String route) {
    final title = RouteConfiguration.getTitleForRoute(route);
    return title == null ? null : AppBar(title: Center(child: Text(title)));
  }
}

class PageRouteNoAnim<T> extends Page<T> {
  final Widget child;

  const PageRouteNoAnim({
    required this.child,
    super.key,
    super.name,
    super.arguments,
  });

  @override
  Route<T> createRoute(BuildContext context) {
    return PageRouteBuilder(
      settings: this,
      pageBuilder: (context, animation, secondaryAnimation) => child,
    );
  }
}

class PageRouteSlideAnim<T> extends Page<T> {
  final Widget child;

  const PageRouteSlideAnim({
    required this.child,
    super.key,
    super.name,
    super.arguments,
  });

  @override
  Route<T> createRoute(BuildContext context) {
    return PageRouteBuilder(
      settings: this,
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;
        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 300),
    );
  }
}

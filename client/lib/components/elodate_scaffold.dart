// File: elodate_scaffold.dart

import 'package:client/models/notifications_model.dart';
import 'package:client/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'bug_report_button.dart';

class ElodateScaffold extends StatefulWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomNavigationBar;
  final bool reverseScrollDirection;

  const ElodateScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.bottomNavigationBar,
    this.reverseScrollDirection = false,
  });

  @override
  ElodateScaffoldState createState() => ElodateScaffoldState();
}

class ElodateScaffoldState extends State<ElodateScaffold> {
  bool notificationLoopStarted = false;

  @override
  void initState() {
    super.initState();
    Provider.of<NotificationsModel>(context, listen: false).init(context);
  }

  @override
  void dispose() {
    Provider.of<NotificationsModel>(context, listen: false)
        .stopNotificationLoop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    UserModel userModel = Provider.of<UserModel>(context);
    if (userModel.loggedIn && !notificationLoopStarted) {
      notificationLoopStarted = true;
      Provider.of<NotificationsModel>(context, listen: false)
          .startNotificationLoop(userModel);
    }

    return Scaffold(
      appBar: widget.appBar,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          _buildMainContent(),
          const BugReportButton(),
        ],
      ),
      bottomNavigationBar: widget.bottomNavigationBar,
    );
  }

  Widget _buildMainContent() {
    return widget.reverseScrollDirection
        ? Align(
            alignment: Alignment.bottomCenter,
            child: _buildScrollableContent(),
          )
        : Center(child: _buildScrollableContent());
  }

  Widget _buildScrollableContent() {
    return LayoutBuilder(builder: (context, constraints) {
      return SingleChildScrollView(
        reverse: widget.reverseScrollDirection,
        child: SizedBox(
          width: constraints.maxWidth,
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              child: widget.body,
            ),
          ),
        ),
      );
    });
  }
}

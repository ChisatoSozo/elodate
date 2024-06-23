// File: notification_handler.dart

import 'package:client/models/notifications_model.dart';
import 'package:client/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NotificationHandler extends StatefulWidget {
  final Widget child;

  const NotificationHandler({super.key, required this.child});

  @override
  NotificationHandlerState createState() => NotificationHandlerState();
}

class NotificationHandlerState extends State<NotificationHandler> {
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

    return widget.child;
  }
}

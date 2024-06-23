import 'dart:convert';

import 'package:client/api/pkg/lib/api.dart';
import 'package:client/components/notification.dart';
import 'package:client/models/user_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';

class Notification {
  final int id;
  final String title;
  final String body;
  final String payload;

  Notification(
      {required this.id,
      required this.title,
      required this.body,
      required this.payload});
}

class NotificationsModel extends ChangeNotifier {
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  FToast fToast = FToast();
  bool loopRunning = false;

  Future<void> init(BuildContext context) async {
    fToast.init(context);
    await initNotifications();
  }

  void startNotificationLoop(UserModel userModel) {
    if (loopRunning) {
      return;
    }
    loopRunning = true;
    Future.doWhile(() async {
      if (!loopRunning) {
        return false;
      }
      await Future.delayed(const Duration(seconds: 5));
      fetchNotifications(userModel);
      return true;
    });
  }

  void stopNotificationLoop() {
    loopRunning = false;
  }

  Future<void> showNotification(
      ApiNotification notification, UserModel userModel) async {
    var title = '';
    var body = '';
    Image image;

    switch (notification.notificationType) {
      case ApiNotificationNotificationTypeEnum.match:
        var userUuid = notification.messageOrUuid;
        var user = await userModel.getUser(userUuid);
        var username = user.username;
        var apiImage = await userModel.getImage(user.previewImage!);
        title = 'New Match!';
        body = '$username has matched with you!';
        var b64 = apiImage.content;
        var bytes = base64Decode(b64);
        image = Image.memory(bytes);
        break;
      case ApiNotificationNotificationTypeEnum.system:
        title = 'System Notification';
        body = notification.messageOrUuid;
        image = Image.asset('images/logo.png');
        break;
      case ApiNotificationNotificationTypeEnum.unreadMessage:
        var messageUuid = notification.messageOrUuid;
        var message = await userModel.getMessage(messageUuid);
        var senderUuid = message.author;
        var sender = await userModel.getUser(senderUuid);
        var senderUsername = sender.username;
        var senderImage = await userModel.getImage(sender.previewImage!);
        title = 'New Message from $senderUsername';
        body = message.content;
        var b64 = senderImage.content;
        var bytes = base64Decode(b64);
        image = Image.memory(bytes);
        break;
      default:
        throw Exception('Invalid notification type');
    }

    if (kIsWeb) {
      // toast that takes from the theme

      fToast.showToast(
        child: NotificationComponent(
          title: title,
          body: body,
          leftImage: image,
        ),
        gravity: ToastGravity.TOP,
        toastDuration: const Duration(seconds: 2),
      );
      notifyListeners();
    }
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails('TODO', 'TODO',
            channelDescription: 'TODO',
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'TODO');
    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);
    await flutterLocalNotificationsPlugin
        .show(0, title, body, notificationDetails, payload: 'TODO');
  }

  Future<void> initNotifications() async {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
// initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');
    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
            onDidReceiveLocalNotification: onDidReceiveLocalNotification);
    const LinuxInitializationSettings initializationSettingsLinux =
        LinuxInitializationSettings(defaultActionName: 'Open notification');
    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      macOS: initializationSettingsDarwin,
      linux: initializationSettingsLinux,
    );
    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse: onDidReceiveNotificationResponse);
  }

  void fetchNotifications(UserModel userModel) async {
    var notifications = await userModel.getNotifications();
    for (var notification in notifications) {
      showNotification(notification, userModel);
    }
  }

  void onDidReceiveLocalNotification(
      int id, String? title, String? body, String? payload) {
    print("$id $title $body $payload");
  }

  void onDidReceiveNotificationResponse(NotificationResponse details) {
    print(details);
  }
}

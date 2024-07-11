// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:client/api/pkg/lib/api.dart';
import 'package:client/models/user_model.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

void downloadFile(List<int> zip) async {
  if (kIsWeb) {
    final blob = html.Blob([zip]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', 'elo_data.zip')
      ..click();
    html.Url.revokeObjectUrl(url);
  } else {
    final downloadPath = await getApplicationDocumentsDirectory();
    final downloadFile = File('${downloadPath.path}/elo_data.zip');
    await downloadFile.writeAsBytes(zip);
  }
}

class ManageAccountPage extends StatefulWidget {
  const ManageAccountPage({super.key});

  @override
  ManageAccountPageState createState() => ManageAccountPageState();
}

class ManageAccountPageState extends State<ManageAccountPage> {
  String? _status;
  InternalUser? _user;
  List<ApiImage>? _images;
  List<ApiChat>? _chats;
  List<ApiMessage>? _messages;

  Future<void> downloadAllData() async {
    setState(() {
      _status = 'Downloading data...';
    });

    var userModel = Provider.of<UserModel>(context, listen: false);

    // try {
    var client = userModel.client;
    setState(() {
      _status = 'Getting internal user data...';
    });
    _user = await client.getInternalMePost(true);

    var numImages = _user!.ownedImages.length;
    _images = [];

    for (var i = 0; i < numImages; i++) {
      var image = _user!.ownedImages[i];
      setState(() {
        _status = 'Getting image data ${i + 1}/$numImages...';
      });
      var imageData = await client.getImagesPost([image]);
      if (imageData == null) {
        throw 'Failed to get image data for image $image';
      }
      _images!.add(imageData[0]);
    }

    var numChats = _user!.chats.length;
    _chats = [];
    _messages = [];
    for (var i = 0; i < numChats; i++) {
      var chat = _user!.chats[i];
      setState(() {
        _status = 'Getting chat data ${i + 1}/$numChats...';
      });
      var chatData = await client.getChatsPost([chat]);
      if (chatData == null) {
        throw 'Failed to get chat data for chat $chat';
      }
      _chats!.add(chatData[0]);

      var numMessages = chatData[0].messages.length;
      for (var j = 0; j < numMessages; j++) {
        var message = chatData[0].messages[j];
        setState(() {
          _status =
              'Getting chat data ${i + 1}/$numChats, message data ${j + 1}/$numMessages...';
        });
        var messageData = await client.getMessagePost(message);
        if (messageData == null) {
          throw 'Failed to get message data for message $message';
        }
        _messages!.add(messageData);
      }
    }
    setState(() {
      _status = 'Data downloaded successfully, zipping...';
      /*
      folder structure should be
      - user.json
      - images/
        - image1.jpg
        - image2.jpg
        ...
      - chats/
        - chat1.json
        - chat2.json
        ...
      - messages/
        - message1.json
        - message2.json
        ...
      */

      // keep it all in memory because it needs to work on web
      var archive = Archive();

      var userJson = jsonEncode(_user!.toJson());
      var userBytes = utf8.encode(userJson);
      archive.addFile(ArchiveFile('user.json', userBytes.length, userBytes));

      for (var image in _images!) {
        var imageBytes = base64Decode(image.content);
        archive.addFile(ArchiveFile(
            'images/${image.uuid}.jpg', imageBytes.length, imageBytes));
      }

      for (var chat in _chats!) {
        var chatJson = jsonEncode(chat.toJson());
        var chatBytes = utf8.encode(chatJson);
        archive.addFile(ArchiveFile(
            'chats/${chat.uuid}.json', chatBytes.length, chatBytes));
      }

      for (var message in _messages!) {
        var messageJson = jsonEncode(message.toJson());
        var messageBytes = utf8.encode(messageJson);
        archive.addFile(ArchiveFile('messages/${message.uuid}.json',
            messageBytes.length, messageBytes));
      }

      var zip = ZipEncoder().encode(archive);

      if (zip == null) {
        throw 'Failed to zip data';
      }

      setState(() {
        _status = 'Data zipped successfully, downloading...';
      });

      // download the zip file
      downloadFile(zip);
    });
    // } catch (e) {
    //   setState(() {
    //     _status = 'Failed to download data: $e';
    //   });
    // }
  }

  Future<void> deleteAllData() async {
    setState(() {
      _status = 'Deleting data...';
    });

    var userModel = Provider.of<UserModel>(context, listen: false);
    _user = await userModel.client.getInternalMePost(true);

    try {
      //first delete all messages, get all chats, then for each message that's mine, delete it

      //get all chats
      for (var i = 0; i < _user!.chats.length; i++) {
        var chatUuid = _user!.chats[i];
        var chatData = await userModel.client.getChatsPost([chatUuid]);
        if (chatData == null) {
          throw 'Failed to get chat data for chat $chatUuid';
        }

        setState(() {
          _status = 'Deleting chat ${i + 1}/${_user!.chats.length}...';
        });

        var messagesDeleted = 0;
        //delete all messages
        for (var j = 0; j < chatData[0].messages.length; j++) {
          var messageUuid = chatData[0].messages[j];
          var messageData = await userModel.client.getMessagePost(messageUuid);
          if (messageData == null) {
            throw 'Failed to get message data for message $messageUuid';
          }
          if (messageData.author == _user!.uuid) {
            await userModel.client.deleteMessagePost(DeleteMessageInput(
                chatUuid: chatUuid, messageUuid: messageUuid));
            messagesDeleted++;
          }
          setState(() {
            _status =
                'Deleting chat ${i + 1}/${_user!.chats.length}, message $messagesDeleted}...';
          });
        }
      }

      var images = _user!.ownedImages;
      for (var i = 0; i < images.length; i++) {
        var imageUuid = images[i];
        setState(() {
          _status = 'Deleting image ${i + 1}/${images.length}...';
        });
        await userModel.client.deleteImagePost(imageUuid);
      }

      var client = userModel.client;
      setState(() {
        _status = 'Deleting internal user data...';
      });
      await client.deleteUserPost(true);
      setState(() {
        _status = 'Data deleted successfully, redirecting in 3 seconds...';
      });
      var seconds = 3;
      //count down
      Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _status =
              'Data deleted successfully, redirecting in ${seconds--} seconds...';
        });
        if (seconds == 0) {
          timer.cancel();
          userModel.logout(context);
        }
      });
    } catch (e) {
      setState(() {
        _status = 'Failed to delete data: $e';
      });
    }
  }

  void showDeleteAllDataModal() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete All Data'),
          content: const Text(
              'Are you sure you want to delete all data? This action cannot be undone. You will no longer have access to your account. If you contact support, they won\'t even know if you ever had an account.'),
          actions: [
            ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  deleteAllData();
                },
                child: const Text('Yes, I understand the consequences')),
            ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('No')),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_status != null) Text(_status!),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton(
              onPressed: () {
                downloadAllData();
              },
              child: const Text('Download Data'),
            ),
            ElevatedButton(
              onPressed: showDeleteAllDataModal,
              child: const Text('Delete All Data'),
            ),
          ],
        ),
      ],
    );
  }
}

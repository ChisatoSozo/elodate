import 'dart:convert';
import 'dart:typed_data';

import 'package:client/api/pkg/lib/api.dart';
import 'package:client/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';

class ReportBugScaffold extends StatefulWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final BottomNavigationBar? bottomNavigationBar;

  // Constructor to take children and title as parameters
  const ReportBugScaffold(
      {super.key, this.appBar, required this.body, this.bottomNavigationBar});

  @override
  ReportBugScaffoldState createState() => ReportBugScaffoldState();
}

class ReportBugScaffoldState extends State<ReportBugScaffold> {
  // Screenshot controller
  ScreenshotController screenshotController = ScreenshotController();
  // text controller
  TextEditingController textController = TextEditingController();

  bool sending = false;

  @override
  Widget build(BuildContext context) {
    return Screenshot(
      controller: screenshotController,
      child: Scaffold(
        appBar: widget.appBar,
        body: Stack(
          children: [
            widget.body,
            Positioned(
              top: (MediaQuery.of(context).size.height / 2) - 40,
              right: 0,
              width: 40,
              child: ElevatedButton(
                onPressed: () {
                  // Take screenshot action
                  screenshotController.capture().then((Uint8List? image) {
                    //show modal
                    if (image == null) {
                      throw Exception('Failed to capture screenshot');
                    }
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('Report'),
                          content: Column(
                            children: [
                              Image.memory(image,
                                  width: 400, height: 400, fit: BoxFit.contain),
                              const SizedBox(height: 10),
                              const Text(
                                  'Please describe the bug or suggestion:'),
                              const SizedBox(height: 10),
                              TextField(
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                ),
                                controller: textController,
                                maxLines: 5,
                              ),
                            ],
                          ),
                          actions: [
                            ElevatedButton(
                              onPressed: () {
                                if (sending) {
                                  return;
                                }
                                Navigator.of(context).pop();
                              },
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                                onPressed: sending
                                    ? null
                                    : () {
                                        if (sending) {
                                          return;
                                        }
                                        var client = constructClient(null);
                                        var imageb64 = base64Encode(image);
                                        sending = true;
                                        client
                                            .reportBugPost(ReportBugInput(
                                                content: textController.text,
                                                imageb64: imageb64))
                                            .then((value) {
                                          Navigator.of(context).pop();
                                          sending = false;
                                          showDialog(
                                            context: context,
                                            builder: (context) {
                                              return AlertDialog(
                                                title: const Text('Report'),
                                                content: const Text(
                                                    'Thank you for reporting!'),
                                                actions: [
                                                  ElevatedButton(
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                    child: const Text('OK'),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        }).catchError((onError) {
                                          throw Exception(
                                              'Failed to send report onError');
                                        });
                                      },
                                child: const Text('Send Report')),
                          ],
                        );
                      },
                    );
                  }).catchError((onError) {
                    throw Exception('Failed to capture screenshot onError');
                  });
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  padding: const EdgeInsets.all(10),
                ),
                child: const RotatedBox(
                  quarterTurns: 3,
                  child: Row(
                    children: [
                      Icon(
                        Icons.bug_report,
                        size: 20,
                      ),
                      SizedBox(width: 5),
                      Text('Report Bug / Suggestion'),
                      SizedBox(width: 5),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: widget.bottomNavigationBar,
      ),
    );
  }
}

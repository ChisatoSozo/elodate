import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

import 'package:client/api/pkg/lib/api.dart';
import 'package:client/models/notifications_model.dart';
import 'package:client/models/user_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';

class ElodateScaffold extends StatefulWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final BottomNavigationBar? bottomNavigationBar;

  // Constructor to take children and title as parameters
  const ElodateScaffold(
      {super.key, this.appBar, required this.body, this.bottomNavigationBar});

  @override
  ElodateScaffoldState createState() => ElodateScaffoldState();
}

class ElodateScaffoldState extends State<ElodateScaffold> {
  // Screenshot controller
  ScreenshotController screenshotController = ScreenshotController();
  // text controller
  TextEditingController textController = TextEditingController();

  bool formVisible = false;
  String? image;
  bool sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    Provider.of<NotificationsModel>(context, listen: false).init(context);
  }

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
              top: 60,
              right: 0,
              width: 40,
              child: ElevatedButton(
                onPressed: () {
                  // Take screenshot action
                  if (kIsWeb) {
                    js.context.callMethod('capture', [
                      0,
                      0,
                      MediaQuery.of(context).size.width,
                      MediaQuery.of(context).size.height,
                      js.allowInterop((base64ImageWithoutPrefix) {
                        setState(() {
                          formVisible = true;
                          image = base64ImageWithoutPrefix;
                        });
                      })
                    ]);
                    return;
                  }
                  screenshotController.capture().then((Uint8List? image) {
                    //show modal
                    if (image == null) {
                      setState(() {
                        _error = 'Failed to capture screenshot no image';
                      });
                      return;
                    }
                    setState(() {
                      formVisible = true;
                      this.image = base64Encode(image);
                    });
                  }).catchError((onError) {
                    setState(() {
                      _error = 'Failed to capture screenshot error $onError';
                    });
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
            if (formVisible)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                bottom: 0,
                child: AlertDialog(
                  title: const Text('Report'),
                  content: Column(
                    children: [
                      Image.memory(base64Decode(image!),
                          width: 400, height: 400, fit: BoxFit.contain),
                      const SizedBox(height: 10),
                      const Text('Please describe the bug or suggestion:'),
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
                        setState(() {
                          formVisible = false;
                          textController.clear();
                        });
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

                                setState(() {
                                  sending = true;
                                });
                                client
                                    .reportBugPost(ReportBugInput(
                                        content: textController.text,
                                        imageb64: image!))
                                    .then((value) {
                                  setState(() {
                                    sending = false;
                                    formVisible = false;
                                    textController.clear();
                                  });
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
                                              Navigator.of(context).pop();
                                            },
                                            child: const Text('OK'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                }).catchError((onError) {
                                  setState(() {
                                    sending = false;
                                    _error = 'Failed to send report';
                                  });
                                });
                              },
                        child: sending
                            ? const Text('Sending...')
                            : const Text('Send Report')),
                  ],
                ),
              ),
            if (_error != null)
              Positioned(left: 0, right: 0, top: 0, child: Text(_error!)),
          ],
        ),
        bottomNavigationBar: widget.bottomNavigationBar,
      ),
    );
  }
}

import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

import 'package:client/api/pkg/lib/api.dart';
import 'package:client/models/user_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';

class BugReportButton extends StatefulWidget {
  const BugReportButton({super.key});

  @override
  BugReportButtonState createState() => BugReportButtonState();
}

class BugReportButtonState extends State<BugReportButton> {
  final ScreenshotController _screenshotController = ScreenshotController();
  final TextEditingController _textController = TextEditingController();
  bool _formVisible = false;
  String? _image;
  bool _sending = false;
  bool _loading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      child: Stack(
        children: [
          Positioned(
            top: 60,
            left: 0,
            child: ElevatedButton(
              onPressed: _loading ? null : _captureScreenshot,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(2)),
                padding: const EdgeInsets.all(5),
                minimumSize: const Size(0, 0),
              ),
              child: RotatedBox(
                quarterTurns: 1,
                child: Row(
                  children: [
                    const SizedBox(width: 5),
                    _loading
                        ? const SizedBox(
                            width: 10,
                            height: 10,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.bug_report, size: 10),
                    const SizedBox(width: 5),
                    Text(
                      _loading ? 'Loading...' : 'Report Bug / Suggestion',
                      style: const TextStyle(fontSize: 10),
                    ),
                    const SizedBox(width: 5),
                  ],
                ),
              ),
            ),
          ),
          if (_formVisible) ...[
            Container(
              color: Colors.black.withOpacity(0.5),
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
            ),
            _buildReportForm()
          ],
          if (_error != null) Text(_error!),
        ],
      ),
    );
  }

  void _captureScreenshot() {
    setState(() => _loading = true);
    if (kIsWeb) {
      _captureWebScreenshot();
    } else {
      _captureNativeScreenshot();
    }
  }

  void _captureWebScreenshot() {
    js.context.callMethod('capture', [
      0,
      0,
      MediaQuery.of(context).size.width,
      MediaQuery.of(context).size.height,
      js.allowInterop((base64ImageWithoutPrefix) {
        setState(() {
          _formVisible = true;
          _image = base64ImageWithoutPrefix;
          _loading = false;
        });
      })
    ]);
  }

  void _captureNativeScreenshot() {
    _screenshotController.capture().then((Uint8List? image) {
      if (image == null) {
        setState(() {
          _error = 'Failed to capture screenshot';
          _loading = false;
        });
        return;
      }
      setState(() {
        _formVisible = true;
        _image = base64Encode(image);
        _loading = false;
      });
    }).catchError((onError) {
      setState(() {
        _error = 'Failed to capture screenshot: $onError';
        _loading = false;
      });
    });
  }

  Widget _buildReportForm() {
    return Center(
      child: AlertDialog(
        title: const Text('Report'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              const Text('Please describe the bug or suggestion:'),
              const SizedBox(height: 10),
              TextField(
                decoration: const InputDecoration(border: OutlineInputBorder()),
                controller: _textController,
                maxLines: 5,
              ),
              const SizedBox(height: 10),
              Image.memory(base64Decode(_image!),
                  width: 400, height: 400, fit: BoxFit.contain),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed:
                _sending ? null : () => setState(() => _formVisible = false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _sending ? null : _sendReport,
            child: Text(_sending ? 'Sending...' : 'Send Report'),
          ),
        ],
      ),
    );
  }

  void _sendReport() {
    if (_sending) return;
    setState(() => _sending = true);

    var client = constructClient(null);
    client
        .reportBugPost(
            ReportBugInput(content: _textController.text, imageb64: _image!))
        .then((_) {
      setState(() {
        _sending = false;
        _formVisible = false;
        _textController.clear();
      });
      _showThankYouDialog();
    }).catchError((onError) {
      setState(() {
        _sending = false;
        _error = 'Failed to send report';
      });
    });
  }

  void _showThankYouDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report'),
        content: const Text('Thank you for reporting!'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

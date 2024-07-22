import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

import 'package:client/api/pkg/lib/api.dart';
import 'package:client/components/labeled_checkbox.dart';
import 'package:client/components/spacer.dart';
import 'package:client/models/user_model.dart';
import 'package:client/router/elo_router_nav.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:universal_platform/universal_platform.dart';

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
  String? _reportedUserUuid;
  String? _reportedChatUuid;
  bool _sending = false;
  bool _loading = false;
  String? _error;
  bool _isViolation = false;

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
              onPressed: _loading ? null : _captureData,
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
                    const HorizontalSpacer(size: SpacerSize.small),
                    _loading
                        ? const SizedBox(
                            width: 10,
                            height: 10,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.report, size: 10),
                    const HorizontalSpacer(size: SpacerSize.small),
                    Text(
                      _loading
                          ? 'Loading...'
                          : 'Report User / Bug / Suggestion',
                      style: const TextStyle(fontSize: 10),
                    ),
                    const HorizontalSpacer(size: SpacerSize.small),
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

  Future<String> _getPlatform() async {
    var platformString = '';
    var platform = UniversalPlatform.value;
    platformString += "Platform: ${platform.toString()}" '\n';

    //get screen size
    platformString +=
        "Screen size: ${MediaQuery.of(context).size.width}x${MediaQuery.of(context).size.height}"
        '\n';

    switch (platform) {
      case UniversalPlatformType.Android:
        var androidInfo = await DeviceInfoPlugin().androidInfo;

        platformString += "version: ${androidInfo.version}" '\n';
        platformString += "board: ${androidInfo.board}" '\n';
        platformString += "bootloader: ${androidInfo.bootloader}" '\n';
        platformString += "brand: ${androidInfo.brand}" '\n';
        platformString += "device: ${androidInfo.device}" '\n';
        platformString += "display: ${androidInfo.display}" '\n';
        platformString += "fingerprint: ${androidInfo.fingerprint}" '\n';
        platformString += "hardware: ${androidInfo.hardware}" '\n';
        platformString += "host: ${androidInfo.host}" '\n';
        platformString += "id: ${androidInfo.id}" '\n';
        platformString += "manufacturer: ${androidInfo.manufacturer}" '\n';
        platformString += "model: ${androidInfo.model}" '\n';
        platformString += "product: ${androidInfo.product}" '\n';
        platformString += "tags: ${androidInfo.tags}" '\n';
        platformString += "type: ${androidInfo.type}" '\n';
        platformString +=
            "isPhysicalDevice: ${androidInfo.isPhysicalDevice}" '\n';
        break;
      case UniversalPlatformType.IOS:
        var iosInfo = await DeviceInfoPlugin().iosInfo;

        platformString += "name: ${iosInfo.name}" '\n';
        platformString += "systemName: ${iosInfo.systemName}" '\n';
        platformString += "systemVersion: ${iosInfo.systemVersion}" '\n';
        platformString += "model: ${iosInfo.model}" '\n';
        platformString += "localizedModel: ${iosInfo.localizedModel}" '\n';
        platformString +=
            "identifierForVendor: ${iosInfo.identifierForVendor}" '\n';
        platformString += "isPhysicalDevice: ${iosInfo.isPhysicalDevice}" '\n';
        break;
      case UniversalPlatformType.Web:
        var webInfo = await DeviceInfoPlugin().webBrowserInfo;

        platformString += "browser: ${webInfo.browserName}" '\n';
        platformString += "platform: ${webInfo.platform}" '\n';
        platformString += "appCodeName: ${webInfo.appCodeName}" '\n';
        platformString += "appName: ${webInfo.appName}" '\n';
        platformString += "appVersion: ${webInfo.appVersion}" '\n';
        platformString += "product: ${webInfo.product}" '\n';
        platformString += "userAgent: ${webInfo.userAgent}" '\n';
        platformString += "vendor: ${webInfo.vendor}" '\n';
        platformString += "vendorSub: ${webInfo.vendorSub}" '\n';
        platformString += "deviceMemory: ${webInfo.deviceMemory}" '\n';
        platformString +=
            "hardwareConcurrency: ${webInfo.hardwareConcurrency}" '\n';
        platformString += "maxTouchPoints: ${webInfo.maxTouchPoints}" '\n';
        platformString += "language: ${webInfo.language}" '\n';
        platformString += "languages: ${webInfo.languages}" '\n';
        break;
      case UniversalPlatformType.Windows:
        var windowsInfo = await DeviceInfoPlugin().windowsInfo;
        platformString += "userName: ${windowsInfo.userName}" '\n';
        break;
      case UniversalPlatformType.Linux:
        var linuxInfo = await DeviceInfoPlugin().linuxInfo;
        platformString += "name: ${linuxInfo.name}" '\n';
        break;
      case UniversalPlatformType.MacOS:
        var macInfo = await DeviceInfoPlugin().macOsInfo;
        platformString += "computerName: ${macInfo.computerName}" '\n';
        break;
      case UniversalPlatformType.Fuchsia:
        var fuchsiaInfo = await DeviceInfoPlugin().deviceInfo;
        platformString += "data: ${fuchsiaInfo.data}" '\n';
        break;
    }

    return platformString;
  }

  void _captureData() {
    setState(() => _loading = true);
    _captureScreenshot();
    _captureUserData();
  }

  void _captureUserData() {
    var userModel = Provider.of<UserModel>(context, listen: false);
    var lastUserLoadedUuid = userModel.lastUserLoadedUuid;
    if (lastUserLoadedUuid != null) {
      _reportedUserUuid = lastUserLoadedUuid;
    }
    var chatId = EloNav.getChatId(context);
    if (chatId != null) {
      _reportedChatUuid = chatId;
    }
  }

  void _captureScreenshot() {
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
              //checkbox for violation

              LabeledCheckbox(
                label:
                    'This is a user report, someone is being unsafe, threatening, or inappropriate',
                checked: _isViolation,
                onChanged: (value) {
                  setState(() {
                    _isViolation = value!;
                  });
                },
                labelOnRight: true,
              ),
              const VerticalSpacer(),
              _isViolation
                  ? const Text(
                      'Feel free to add extra context, all the data of any chat or user on your screen has been collected and will be sent with this report')
                  : const Text('Please describe the bug or suggestion:'),
              const VerticalSpacer(),
              TextField(
                decoration: const InputDecoration(border: OutlineInputBorder()),
                controller: _textController,
                maxLines: 5,
              ),
              const VerticalSpacer(),
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

  void _sendReport() async {
    if (_sending) return;
    setState(() => _sending = true);

    var client = constructClient(null);
    client
        .reportPost(
      ReportInput(
        content: _textController.text,
        imageb64: _image!,
        isViolation: _isViolation,
        chat: _reportedChatUuid,
        userUuid: _reportedUserUuid,
        platform: await _getPlatform(),
      ),
    )
        .then(
      (_) {
        setState(
          () {
            _sending = false;
            _formVisible = false;
            _textController.clear();
            _image = null;
            _isViolation = false;
            _reportedUserUuid = null;
            _reportedChatUuid = null;
          },
        );
        _showThankYouDialog();
      },
    ).catchError((onError) {
      setState(
        () {
          _sending = false;
          _error = 'Failed to send report: $onError';
        },
      );
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

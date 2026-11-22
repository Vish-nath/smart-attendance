import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ClassmateApp());
  unawaited(_initializeNotifications());
}

Future<void> _initializeNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('ic_launcher');
  const DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings();
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
  );
  try {
    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
    );
  } catch (_) {}
}

class ClassmateApp extends StatelessWidget {
  const ClassmateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Classmate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff4a56d2)),
        useMaterial3: true,
      ),
      home: const ClassmateHome(),
    );
  }
}

class ClassmateHome extends StatefulWidget {
  const ClassmateHome({super.key});

  @override
  State<ClassmateHome> createState() => _ClassmateHomeState();
}

class _ClassmateHomeState extends State<ClassmateHome> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _loadError;
  Timer? _loadTimeout;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xfff6f7fb))
      ..addJavaScriptChannel(
        'ClassmateNative',
        onMessageReceived: (message) {
          unawaited(_handleNativeMessage(message));
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            _loadTimeout?.cancel();
            if (mounted) {
              setState(() {
                _isLoading = false;
                _loadError = null;
              });
            }
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame == true && mounted) {
              _loadTimeout?.cancel();
              setState(() {
                _isLoading = false;
                _loadError = error.description;
              });
            }
          },
        ),
      );
    unawaited(_loadApp());
  }

  Future<void> _loadApp() async {
    _loadTimeout?.cancel();
    _loadTimeout = Timer(const Duration(seconds: 20), () {
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
          _loadError = 'The app page did not finish loading. Check the bundled app files and retry.';
        });
      }
    });
    try {
      await _controller.loadFlutterAsset('assets/web/app/index.html');
    } on Exception catch (error) {
      _loadTimeout?.cancel();
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadError = error.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _loadTimeout?.cancel();
    super.dispose();
  }

  Future<void> _handleBack() async {
    try {
      if (await _controller.canGoBack()) {
        await _controller.goBack();
        return;
      }
      final hash = (await _controller.runJavaScriptReturningResult(
        'window.location.hash',
      )).toString().replaceAll('"', '');
      if (hash.isNotEmpty && hash != '#dashboard') {
        await _controller.runJavaScript("window.location.hash = '#dashboard';");
        return;
      }
      await SystemNavigator.pop();
    } on Exception catch (error) {
      if (mounted) {
        setState(() {
          _loadError = 'Could not navigate back: $error';
        });
      }
    }
  }

  Future<void> _handleNativeMessage(JavaScriptMessage message) async {
    try {
      final request = jsonDecode(message.message);
      if (request is! Map<String, dynamic>) {
        throw const FormatException('Invalid request from the app page.');
      }

      switch (request['action']) {
        case 'notify':
          final title = request['title'] as String;
          final body = request['body'] as String;
          final androidDetails = const AndroidNotificationDetails(
            'classmate_reminders',
            'Class Reminders',
            channelDescription: 'Notifications for class start and attendance',
            importance: Importance.max,
            priority: Priority.high,
          );
          final iosDetails = const DarwinNotificationDetails();
          final details = NotificationDetails(android: androidDetails, iOS: iosDetails);
          await flutterLocalNotificationsPlugin.show(
            id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
            title: title,
            body: body,
            notificationDetails: details,
          );
          break;
        case 'request-notifications':
          final granted = await flutterLocalNotificationsPlugin
                  .resolvePlatformSpecificImplementation<
                    AndroidFlutterLocalNotificationsPlugin
                  >()
                  ?.requestNotificationsPermission() ??
              false;
          await _controller.runJavaScript('window.classmateSetNotificationPermission($granted);');
          break;
        case 'report':
          final endpoint = request['endpoint'];
          final reportData = request['data'];
          if (endpoint is! String || reportData is! Map<String, dynamic>) {
            throw const FormatException('Invalid report details.');
          }
          try {
            final uri = Uri.parse(endpoint);
            if (uri.host != 'formspree.io' || uri.path != '/f/xwlorglw') {
              throw const FormatException('Invalid report endpoint.');
            }
            final response = await http
                .post(
                  uri,
                  headers: const {
                    'Accept': 'application/json',
                    'Content-Type': 'application/json',
                  },
                  body: jsonEncode(reportData),
                )
                .timeout(const Duration(seconds: 20));
            if (response.statusCode >= 200 && response.statusCode < 300) {
              final responseData = jsonDecode(response.body);
              if (responseData is Map && responseData['ok'] == false) {
                final errors = responseData['errors'];
                final message = errors is List
                    ? errors.map((item) => item is Map ? item['message'] : null)
                        .whereType<String>().join(' ')
                    : 'Formspree did not accept the report.';
                throw FormatException(message);
              }
              await _controller.runJavaScript(
                'if(window.classmateReportStatus) window.classmateReportStatus(true, "");',
              );
            } else {
              var detail = 'Formspree returned status ${response.statusCode}.';
              try {
                final result = jsonDecode(response.body);
                if (result is Map && result['errors'] is List) {
                  detail = (result['errors'] as List)
                      .map((item) => item is Map ? item['message'] : null)
                      .whereType<String>()
                      .join(' ');
                  if (detail.isEmpty) {
                    detail = 'Formspree returned status ${response.statusCode}.';
                  }
                }
              } catch (_) {}
              await _controller.runJavaScript(
                'if(window.classmateReportStatus) window.classmateReportStatus(false, ${jsonEncode(detail)});',
              );
            }
          } catch (error) {
            await _controller.runJavaScript(
              'if(window.classmateReportStatus) window.classmateReportStatus(false, ${jsonEncode(error.toString())});',
            );
          }
          break;
        case 'export':
          final content = request['content'];
          final fileName = request['fileName'];
          if (content is! String || fileName is! String) {
            throw const FormatException('Invalid backup data.');
          }

          await SharePlus.instance.share(
            ShareParams(
              files: [
                XFile.fromData(
                  Uint8List.fromList(utf8.encode(content)),
                  name: fileName,
                  mimeType: 'application/json',
                ),
              ],
              subject: 'Classmate attendance backup',
            ),
          );

        case 'import':
          final result = await FilePicker.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['json'],
          );
          if (result.isEmpty) return;
          final content = utf8.decode(await result.single.readAsBytes());
          await _controller.runJavaScript(
            'window.classmateImportBackup(${jsonEncode(content)});',
          );
        default:
          throw const FormatException('Unsupported backup action.');
      }
    } on Exception catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Backup action failed: $error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Edge-to-edge styling is managed globally via SystemUI APIs
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_handleBack());
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        extendBody: true,
        body: Stack(
          fit: StackFit.expand,
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              const ColoredBox(
                color: Color(0xfff3f5fa),
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xff4a56d2)),
                ),
              ),
            if (_loadError case final error?)
              ColoredBox(
                color: const Color(0xfff3f5fa),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Color(0xffb42332),
                          size: 40,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Classmate could not be opened.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text(error, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () {
                            setState(() {
                              _isLoading = true;
                              _loadError = null;
                            });
                            unawaited(_loadApp());
                          },
                          child: const Text('Try again'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  runApp(const ClassmateApp());
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
            if (mounted) {
              setState(() {
                _isLoading = false;
                _loadError = null;
              });
            }
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame == true && mounted) {
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
    try {
      await _controller.loadFlutterAsset('assets/web/app/index.html');
    } on Exception catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadError = error.toString();
        });
      }
    }
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
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_handleBack());
      },
      child: Scaffold(
        backgroundColor: const Color(0xfff6f7fb),
        body: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: [
              WebViewWidget(controller: _controller),
              if (_isLoading)
                const ColoredBox(
                  color: Color(0xfff6f7fb),
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xff4a56d2)),
                  ),
                ),
              if (_loadError case final error?)
                ColoredBox(
                  color: const Color(0xfff6f7fb),
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
      ),
    );
  }
}

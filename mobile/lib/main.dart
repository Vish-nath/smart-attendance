import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'api_service.dart';

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
  late ApiService _apiService;
  bool _isLoading = true;
  bool _isSyncing = false;
  bool _backendConnected = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
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
              _checkBackendStatus();
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

  Future<void> _checkBackendStatus() async {
    final connected = await _apiService.checkHealth();
    if (mounted) {
      setState(() {
        _backendConnected = connected;
      });
    }
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

  Future<void> _syncDataWithBackend() async {
    if (_isSyncing) return;
    setState(() {
      _isSyncing = true;
    });

    try {
      final isHealthy = await _apiService.checkHealth();
      if (!isHealthy) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cannot connect to Flask server at ${_apiService.baseUrl}'),
              backgroundColor: const Color(0xffb42332),
            ),
          );
        }
        return;
      }

      // Fetch latest data from Flask backend
      final remoteData = await _apiService.fetchSyncData();
      if (remoteData != null) {
        final jsonStr = jsonEncode(jsonEncode(remoteData));
        await _controller.runJavaScript('window.classmateImportBackup($jsonStr);');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data synced successfully with Flask backend!'),
              backgroundColor: Color(0xff22854b),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  Future<void> _showBackendSettingsDialog() async {
    final controller = TextEditingController(text: _apiService.baseUrl);
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Flask Backend Settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter the URL of your Flask backend server:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Backend Base URL',
                  hintText: 'http://10.0.2.2:5000 or http://192.168.1.100:5000',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '• Android Emulator: http://10.0.2.2:5000\n'
                '• iOS / macOS: http://127.0.0.1:5000\n'
                '• Real Device: http://<your-computer-ip>:5000',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final url = controller.text.trim();
                if (url.isNotEmpty) {
                  setState(() {
                    _apiService.baseUrl = url;
                  });
                  Navigator.pop(context);
                  await _checkBackendStatus();
                }
              },
              child: const Text('Save & Test'),
            ),
          ],
        );
      },
    );
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

          // Optionally push backup content to Flask backend
          final data = jsonDecode(content);
          if (data is Map<String, dynamic>) {
            await _apiService.pushSyncData(data);
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
          final data = jsonDecode(content);
          if (data is Map<String, dynamic>) {
            await _apiService.pushSyncData(data);
          }
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
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(42),
          child: Container(
            color: const Color(0xff4a56d2),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(Icons.school, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Classmate',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                Tooltip(
                  message: _backendConnected
                      ? 'Flask Backend Connected'
                      : 'Flask Backend Disconnected',
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _backendConnected ? Colors.green.shade700 : Colors.orange.shade800,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _backendConnected ? Icons.cloud_done : Icons.cloud_off,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _backendConnected ? 'Connected' : 'Offline',
                          style: const TextStyle(color: Colors.white, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: _isSyncing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.sync, color: Colors.white, size: 20),
                  onPressed: _syncDataWithBackend,
                  tooltip: 'Sync with Backend',
                ),
                IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white, size: 20),
                  onPressed: _showBackendSettingsDialog,
                  tooltip: 'Backend Settings',
                ),
              ],
            ),
          ),
        ),
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

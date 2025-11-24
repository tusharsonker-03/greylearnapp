import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WebViewScreen(
        url:
        "https://greylearnweb.blob.core.windows.net/greylearn-assets/Career_Plan_CRM_and_Marketing_Automation_Engineer_20250905_170358.pdf",
      ),
    );
  }
}

class WebViewScreen extends StatefulWidget {
  final String url;
  const WebViewScreen({super.key, required this.url});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.url));
  }

  Future<bool> _checkPermission() async {
    if (Platform.isAndroid) {
      // ✅ Pehle normal storage permission check karo
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }

      // ✅ Android 11+ ke liye Manage External Storage bhi maangna padta hai
      if (Platform.isAndroid && (await Permission.manageExternalStorage.isDenied)) {
        var manageStatus = await Permission.manageExternalStorage.request();
        return manageStatus.isGranted;
      }

      return status.isGranted;
    }
    return true;
  }

  Future<void> _downloadFile(String url) async {
    try {
      bool granted = await _checkPermission();
      if (!granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("⚠️ Please allow storage access")),
        );
        return;
      }

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final filename = url.split('/').last;

        // ✅ Downloads folder path
        Directory downloadsDir = Directory("/storage/emulated/0/Download");

        final filePath = "${downloadsDir.path}/$filename";
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("✅ Saved to Downloads:\n$filePath")),
          );
        }
      } else {
        throw Exception("Download failed");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Error: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("PDF WebView"),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _downloadFile(widget.url),
          )
        ],
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}











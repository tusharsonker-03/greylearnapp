import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import '../api/api_client.dart';
import 'package:academy_app/models/app_logo.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../constants.dart';

// ✅ Added imports
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:open_file/open_file.dart';

// ---------------- NOTIFICATION SETUP ----------------
final FlutterLocalNotificationsPlugin _notifications =
FlutterLocalNotificationsPlugin();

Future<void> initNotifications() async {
  const AndroidInitializationSettings initSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initSettings =
  InitializationSettings(android: initSettingsAndroid);
  await _notifications.initialize(initSettings,
      onDidReceiveNotificationResponse: (resp) {
        final payload = resp.payload;
        if (payload != null && payload.isNotEmpty) {
          OpenFile.open(payload); // ✅ open file on notification tap
        }
      });
}
// ----------------------------------------------------

class JobWebViewScreen extends StatefulWidget {
  static const routeName = '/webview';
  final String url;

  const JobWebViewScreen({super.key, required this.url});

  @override
  _WebViewScreenState createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<JobWebViewScreen> {
  late final WebViewController _controller;
  final _controllerTwo = StreamController<AppLogo>();

  // fetchMyLogo() async {
  //   var url = '$BASE_URL/api/app_logo';
  //   try {
  //     final response = await ApiClient().get(url);
  //     if (response.statusCode == 200) {
  //       var logo = AppLogo.fromJson(jsonDecode(response.body));
  //       _controllerTwo.add(logo);
  //     }
  //   } catch (error) {
  //     rethrow;
  //   }
  // }

  @override
  void initState() {
    super.initState();
    // fetchMyLogo();

    late final PlatformWebViewControllerCreationParams params;
    params = const PlatformWebViewControllerCreationParams();

    final WebViewController controller =
    WebViewController.fromPlatformCreationParams(params);

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFFFFFFF))
      ..enableZoom(false)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest req) {
            final url = req.url;
            if (url.startsWith('blob:')) {
              _requestBlobViaJS(url);
              return NavigationDecision.prevent;
            }
            if (_shouldOpenExternally(url)) {
              _openExternally(url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onPageFinished: (String url) async {
            await _injectDownloadCatcher();
          },
        ),
      )
      ..addJavaScriptChannel(
        'Downloader',
        onMessageReceived: (JavaScriptMessage message) async {
          final raw = message.message;
          try {
            final obj = jsonDecode(raw) as Map<String, dynamic>;
            final kind = (obj['kind'] ?? '').toString();
            if (kind == 'blob') {
              final name = (obj['name'] ?? 'file').toString();
              final mime =
              (obj['mime'] ?? 'application/octet-stream').toString();
              final b64 = (obj['data'] ?? '').toString();
              if (b64.isEmpty) return;
              final bytes = base64Decode(b64);
              final ext = _inferExtension(name, mime);

              final savedPath = await _saveFileCompat(
                name: _stripExt(name),
                bytes: bytes,
                ext: ext,
                mime: mime,
              );

              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(savedPath != null
                        ? 'Saved: $savedPath'
                        : 'Saved to Downloads')),
              );
            } else if (kind == 'url') {
              final url = (obj['url'] ?? '').toString();
              if (url.isNotEmpty) await _openExternally(url);
            }
          } catch (_) {
            final url = raw;
            if (url.startsWith('blob:')) {
              _requestBlobViaJS(url);
            } else if (url.isNotEmpty) {
              await _openExternally(url);
            }
          }
        },
      )
      ..loadRequest(Uri.parse(widget.url));

    _controller = controller;
  }

  // ✅ Decide if link should open externally
  bool _shouldOpenExternally(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    if (!['http', 'https'].contains(uri.scheme)) return true;

    final lower = url.toLowerCase();
    const exts = [
      '.pdf',
      '.doc',
      '.docx',
      '.xls',
      '.xlsx',
      '.csv',
      '.zip',
      '.rar',
      '.7z',
      '.apk',
      '.ppt',
      '.pptx'
    ];
    if (exts.any(lower.endsWith)) return true;
    if (lower.contains('download=')) return true;
    return false;
  }

  Future<void> _openExternally(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _requestBlobViaJS(String blobUrl, {String? name}) async {
    final safeUrl = blobUrl.replaceAll(r'\', r'\\').replaceAll("'", r"\'");
    final safeName =
    (name ?? 'file').replaceAll(r'\', r'\\').replaceAll("'", r"\'");
    final js =
        "window.__FlutterDownloadFromBlob && window.__FlutterDownloadFromBlob('$safeUrl', '$safeName');";
    try {
      await _controller.runJavaScript(js);
    } catch (_) {}
  }

  Future<void> _injectDownloadCatcher() async {
    const js = r'''
      (function(){
        if (window.__FLUTTER_DL_INSTALLED) return;
        window.__FLUTTER_DL_INSTALLED = true;
        function post(obj){ Downloader.postMessage(JSON.stringify(obj)); }
        window.__FlutterDownloadFromBlob = function(url, name){
          fetch(url).then(r=>r.blob()).then(b=>{
            var reader = new FileReader();
            reader.onloadend = function(){
              var dataUrl = reader.result || '';
              var m = /^data:(.*?);base64,(.*)$/.exec(dataUrl);
              var mime = (m && m[1]) || b.type || 'application/octet-stream';
              var base64 = (m && m[2]) || '';
              post({ kind:'blob', name: name||'file', mime: mime, data: base64 });
            };
            reader.readAsDataURL(b);
          });
        };
        document.addEventListener('click', function(e){
          var a = e.target && e.target.closest ? e.target.closest('a') : null;
          if(!a) return;
          var href = a.getAttribute('href') || '';
          var hasDownload = a.hasAttribute('download');
          if(!href) return;
          if (href.startsWith('blob:')) {
            e.preventDefault();
            var n = a.getAttribute('download') || 'file';
            window.__FlutterDownloadFromBlob(href, n);
          } else if (hasDownload) {
            e.preventDefault();
            var n2 = a.getAttribute('download') || 'file';
            post({ kind:'url', url: href, name: n2 });
          }
        }, true);
      })();
    ''';
    try {
      await _controller.runJavaScript(js);
    } catch (_) {}
  }

  String _stripExt(String name) {
    final i = name.lastIndexOf('.');
    if (i > 0 && i < name.length - 1) return name.substring(0, i);
    return name;
  }

  String _inferExtension(String name, String mime) {
    final n = name.toLowerCase();
    const known = [
      '.pdf',
      '.doc',
      '.docx',
      '.xls',
      '.xlsx',
      '.csv',
      '.zip',
      '.rar',
      '.7z',
      '.apk',
      '.ppt',
      '.pptx'
    ];
    for (final e in known) {
      if (n.endsWith(e)) return e.replaceFirst('.', '');
    }
    switch (mime) {
      case 'application/pdf':
        return 'pdf';
      case 'application/msword':
        return 'doc';
      case 'application/vnd.openxmlformats-officedocument.wordprocessingml.document':
        return 'docx';
      case 'application/vnd.ms-excel':
        return 'xls';
      case 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet':
        return 'xlsx';
      case 'text/csv':
        return 'csv';
      case 'application/zip':
        return 'zip';
      case 'application/vnd.android.package-archive':
        return 'apk';
      case 'application/vnd.ms-powerpoint':
        return 'ppt';
      case 'application/vnd.openxmlformats-officedocument.presentationml.presentation':
        return 'pptx';
      default:
        return 'bin';
    }
  }

  /// ✅ Save file to Downloads and show notification
  Future<String?> _saveFileCompat({
    required String name,
    required List<int> bytes,
    required String ext,
    required String mime,
  }) async {
    try {
      // ✅ Android me direct Downloads folder
      Directory dir = Directory("/storage/emulated/0/Download");
      if (!await dir.exists()) {
        dir = await getApplicationDocumentsDirectory(); // fallback
      }

      final filePath = "${dir.path}/$name.$ext";
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      // ✅ Notification setup
      const androidDetails = AndroidNotificationDetails(
        'downloads_channel',
        'Downloads',
        channelDescription: 'File downloads',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      );
      const platformDetails = NotificationDetails(android: androidDetails);

      await _notifications.show(
        0,
        'Download complete',
        '$name.$ext saved to Downloads',
        platformDetails,
        payload: filePath, // 👈 yeh wahi path hoga jo humne save kiya
      );
      print('👈Save File : ${filePath} ');
      return filePath;
    } catch (e) {
      debugPrint("❌ Save error: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // 🚫 hide default back button
        title: StreamBuilder<AppLogo>(
          stream: _controllerTwo.stream,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return CachedNetworkImage(
                imageUrl: snapshot.data!.darkLogo.toString(),
                height: 27,
              );
            }
            return const Text("Jobs", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF27AE60)),);
          },
        ),
        actions: <Widget>[NavigationControls(webViewController: _controller)],
        backgroundColor: kBackgroundColor,
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}

class NavigationControls extends StatelessWidget {
  const NavigationControls({super.key, required this.webViewController});

  final WebViewController webViewController;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        // IconButton(
        //   icon: const Icon(Icons.arrow_back_ios),
        //   onPressed: () async {
        //     if (await webViewController.canGoBack()) {
        //       await webViewController.goBack();
        //     }
        //   },
        // ),
        // IconButton(
        //   icon: const Icon(Icons.arrow_forward_ios),
        //   onPressed: () async {
        //     if (await webViewController.canGoForward()) {
        //       await webViewController.goForward();
        //     }
        //   },
        // ),
        IconButton(
            icon: const Icon(Icons.replay),
            // onPressed: () => webViewController.reload(),
            onPressed: () async {
              final currentUrl = await webViewController.currentUrl();
              if (currentUrl != null) {
                // Force clear and reload the current page
                await webViewController.loadRequest(Uri.parse('about:blank'));
                await Future.delayed(const Duration(milliseconds: 200));
                await webViewController.loadRequest(Uri.parse(currentUrl));
              }
            }),
      ],
    );
  }
}

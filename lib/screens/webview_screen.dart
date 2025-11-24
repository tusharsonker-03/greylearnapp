// // ignore_for_file: use_build_context_synchronously
//
// import 'dart:convert';
// import 'dart:typed_data';
// import 'dart:io';
//
// import 'package:cached_network_image/cached_network_image.dart';
// import '../api/api_client.dart';
// import 'package:academy_app/models/app_logo.dart';
// import 'package:flutter/material.dart';
// import 'dart:async';
// import 'package:webview_flutter/webview_flutter.dart';
// import '../constants.dart';
//
// import 'package:url_launcher/url_launcher.dart';
// import 'package:dio/dio.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:media_store_plus/media_store_plus.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
//
// class WebViewScreen extends StatefulWidget {
//   static const routeName = '/webview';
//   final String url;
//
//   const WebViewScreen({super.key, required this.url});
//
//   @override
//   _WebViewScreenState createState() => _WebViewScreenState();
// }
//
// class _WebViewScreenState extends State<WebViewScreen> {
//   late final WebViewController _controller;
//   final _controllerTwo = StreamController<AppLogo>();
//   String? _pageCookies;
//
//   // ---- Blob streaming state ----
//   final Map<String, _BlobSink> _blobSinks = {}; // key: blob name (safe)
//
//   // ---- Notifications ----
//   final FlutterLocalNotificationsPlugin _flnp = FlutterLocalNotificationsPlugin();
//   static const String _dlChannelId = 'downloads_channel';
//   int _notifSeq = 1000;
//   final Map<String, int> _notifIdByName = {}; // name -> notifId
//
//   Future<void> _initLocalNotifications() async {
//     const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
//     const init = InitializationSettings(android: androidInit);
//     await _flnp.initialize(
//       init,
//       onDidReceiveNotificationResponse: (NotificationResponse resp) async {
//         final payload = resp.payload;
//         if (payload == null || payload.isEmpty) return;
//
//         try {
//           Uri uri;
//           if (payload.startsWith("content://") || payload.startsWith("file://")) {
//             uri = Uri.parse(payload);
//           } else {
//             // agar sirf path mila hai to usko file:// banado
//             uri = Uri.file(payload);
//           }
//
//           // ✅ open with external app (PDF viewer, gallery, etc.)
//           await launchUrl(uri, mode: LaunchMode.externalApplication);
//         } catch (e) {
//           debugPrint("Error opening file: $e");
//         }
//       },
//     );
//
//
//     const channel = AndroidNotificationChannel(
//       _dlChannelId,
//       'Downloads',
//       description: 'File downloads',
//       importance: Importance.low,
//       playSound: false,
//       showBadge: false,
//     );
//     await _flnp
//         .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
//         ?.createNotificationChannel(channel);
//   }
//
//   Future<int> _notifyStart(String title) async {
//     final id = _notifSeq++;
//     const android = AndroidNotificationDetails(
//       _dlChannelId,
//       'Downloads',
//       channelDescription: 'File downloads',
//       importance: Importance.low,
//       priority: Priority.low,
//       onlyAlertOnce: true,
//       showProgress: true,
//       maxProgress: 100,
//       progress: 0,
//       ongoing: true,
//     );
//     await _flnp.show(
//       id,
//       'Downloading…',
//       title,
//       const NotificationDetails(android: android),
//     );
//     return id;
//   }
//
//   Future<void> _notifyProgress(int id, String title, int progress) async {
//     final android = AndroidNotificationDetails(
//       _dlChannelId,
//       'Downloads',
//       channelDescription: 'File downloads',
//       importance: Importance.low,
//       priority: Priority.low,
//       onlyAlertOnce: true,
//       showProgress: true,
//       maxProgress: 100,
//       progress: progress.clamp(0, 100),
//       ongoing: true,
//     );
//     await _flnp.show(
//       id,
//       'Downloading…',
//       '$title  ($progress%)',
//       NotificationDetails(android: android),
//     );
//   }
//
//   Future<void> _notifyComplete(int id, String title, String payloadUri) async {
//     final android = AndroidNotificationDetails(
//       _dlChannelId,
//       'Downloads',
//       channelDescription: 'File downloads',
//       importance: Importance.defaultImportance,
//       priority: Priority.defaultPriority,
//       autoCancel: true,
//       ongoing: false,
//     );
//     await _flnp.show(
//       id,
//       'Download complete',
//       title,
//       NotificationDetails(android: android),
//       payload: payloadUri, // 👈 exact path or uri
//     );
//   }
//
//   fetchMyLogo() async {
//     var url = '$BASE_URL/api/app_logo';
//     try {
//       final response = await ApiClient().get(url);
//       if (response.statusCode == 200) {
//         var logo = AppLogo.fromJson(jsonDecode(response.body));
//         _controllerTwo.add(logo);
//       }
//     } catch (error) {
//       rethrow;
//     }
//   }
//
//   @override
//   void initState() {
//     super.initState();
//     fetchMyLogo();
//     _initLocalNotifications();
//
//     late final PlatformWebViewControllerCreationParams params;
//     params = const PlatformWebViewControllerCreationParams();
//
//     final WebViewController controller =
//     WebViewController.fromPlatformCreationParams(params);
//
//     controller
//       ..setJavaScriptMode(JavaScriptMode.unrestricted)
//       ..setBackgroundColor(const Color(0xFFFFFFFF))
//       ..enableZoom(false)
//       ..setNavigationDelegate(
//         NavigationDelegate(
//           onNavigationRequest: (NavigationRequest req) {
//             final url = req.url;
//
//             if (url.startsWith('blob:')) {
//               _requestBlobViaJS(url);
//               return NavigationDecision.prevent;
//             }
//
//             final uri = Uri.tryParse(url);
//             if (uri == null || !['http', 'https'].contains(uri.scheme)) {
//               _openExternally(url);
//               return NavigationDecision.prevent;
//             }
//
//             if (_looksLikeFileUrl(url)) {
//               _downloadHttpToDownloads(url);
//               return NavigationDecision.prevent;
//             }
//
//             return NavigationDecision.navigate;
//           },
//           onProgress: (int progress) {
//             debugPrint('WebView progress : $progress%');
//           },
//           onPageStarted: (String url) {
//             debugPrint('Page started: $url');
//           },
//           onPageFinished: (String url) async {
//             debugPrint('Page finished: $url');
//
//             await _injectDownloadCatcher();
//
//             try {
//               final jsRes =
//               await _controller.runJavaScriptReturningResult('document.cookie');
//               _pageCookies = jsRes?.toString().replaceAll(RegExp(r'^"|"$'), '');
//             } catch (_) {}
//           },
//           onWebResourceError: (WebResourceError error) {
//             debugPrint('''
// Web error:
//   code: ${error.errorCode}
//   description: ${error.description}
//   type: ${error.errorType}
//   mainFrame: ${error.isForMainFrame}
// ''');
//           },
//         ),
//       )
//       ..addJavaScriptChannel(
//         'Toaster',
//         onMessageReceived: (JavaScriptMessage message) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text(message.message)),
//           );
//         },
//       )
//       ..addJavaScriptChannel(
//         'Downloader',
//         onMessageReceived: (JavaScriptMessage message) async {
//           final raw = message.message;
//
//           Map<String, dynamic>? obj;
//           try {
//             obj = jsonDecode(raw) as Map<String, dynamic>;
//           } catch (_) {
//             obj = null;
//           }
//
//           if (obj == null) {
//             final url = raw;
//             if (url.startsWith('blob:')) {
//               _requestBlobViaJS(url);
//             } else if (url.isNotEmpty) {
//               await _downloadHttpToDownloads(url);
//             }
//             return;
//           }
//
//           final kind = (obj['kind'] ?? '').toString();
//
//           if (kind == 'blob_start') {
//             final name = (obj['name'] ?? 'file').toString();
//             final mime = (obj['mime'] ?? 'application/octet-stream').toString();
//             final total = int.tryParse(obj['total'].toString()) ?? 0;
//             await _blobStart(name, mime, total);
//           } else if (kind == 'blob_chunk') {
//             final name = (obj['name'] ?? 'file').toString();
//             final index = int.tryParse(obj['index'].toString()) ?? 0;
//             final data = (obj['data'] ?? '').toString();
//             if (data.isNotEmpty) {
//               await _blobAppend(name, index, data);
//             }
//           } else if (kind == 'blob_done') {
//             final name = (obj['name'] ?? 'file').toString();
//             final mime = (obj['mime'] ?? 'application/octet-stream').toString();
//             await _blobFinish(name, mime);
//           } else if (kind == 'url') {
//             final url = (obj['url'] ?? '').toString();
//             if (url.isNotEmpty) {
//               await _downloadHttpToDownloads(url, suggestedName: obj['name']?.toString());
//             }
//           }
//         },
//       )
//       ..loadRequest(Uri.parse(widget.url));
//
//     _controller = controller;
//   }
//
//   // ---------- Helpers ----------
//
//   bool _looksLikeFileUrl(String url) {
//     final u = url.toLowerCase();
//     const exts = [
//       '.pdf', '.doc', '.docx', '.xls', '.xlsx', '.csv',
//       '.zip', '.rar', '.7z', '.apk', '.ppt', '.pptx'
//     ];
//     return exts.any(u.endsWith) || u.contains('download=');
//   }
//
//   Future<void> _openExternally(String url) async {
//     final uri = Uri.parse(url);
//     await launchUrl(uri, mode: LaunchMode.externalApplication);
//   }
//
//   // blob: URL -> JS chunked
//   Future<void> _requestBlobViaJS(String blobUrl, {String? name}) async {
//     final safeUrl = blobUrl.replaceAll(r'\', r'\\').replaceAll("'", r"\'");
//     final safeName = (name ?? 'file').replaceAll(r'\', r'\\').replaceAll("'", r"\'");
//     final js =
//         "window.__FlutterDownloadFromBlob && window.__FlutterDownloadFromBlob('$safeUrl', '$safeName');";
//     try {
//       await _controller.runJavaScript(js);
//     } catch (_) {}
//   }
//
//   // Inject JS (chunked)
//   Future<void> _injectDownloadCatcher() async {
//     const js = r'''
//       (function(){
//         if (window.__FLUTTER_DL_INSTALLED) return;
//         window.__FLUTTER_DL_INSTALLED = true;
//
//         const CHUNK_SIZE = 128 * 1024;
//
//         function post(obj){
//           try { Downloader.postMessage(JSON.stringify(obj)); } catch(e) {}
//         }
//
//         function sendBlobInChunks(blob, name) {
//           try {
//             const reader = new FileReader();
//             reader.onloadend = function(){
//               const dataUrl = reader.result || '';
//               const m = /^data:(.*?);base64,(.*)$/.exec(dataUrl);
//               const mime = (m && m[1]) || blob.type || 'application/octet-stream';
//               const b64  = (m && m[2]) || '';
//               const totalChunks = Math.ceil(b64.length / CHUNK_SIZE);
//
//               post({ kind:'blob_start', name: name || 'file', mime: mime, total: totalChunks });
//
//               for (let i = 0, idx = 0; i < b64.length; i += CHUNK_SIZE, idx++) {
//                 const part = b64.substring(i, i + CHUNK_SIZE);
//                 post({ kind:'blob_chunk', name: name || 'file', index: idx, data: part });
//               }
//
//               post({ kind:'blob_done', name: name || 'file', mime: mime });
//             };
//             reader.readAsDataURL(blob);
//           } catch (e) {
//             post({ kind:'error', message: String(e) });
//           }
//         }
//
//         window.__FlutterDownloadFromBlob = function(url, name){
//           try {
//             fetch(url).then(function(r){ return r.blob(); })
//               .then(function(b){ sendBlobInChunks(b, name); })
//               .catch(function(err){ post({ kind:'error', message: String(err) }); });
//           } catch (e) {
//             post({ kind:'error', message: String(e) });
//           }
//         };
//
//         document.addEventListener('click', function(e){
//           try{
//             var a = e.target && e.target.closest ? e.target.closest('a') : null;
//             if(!a) return;
//             var href = a.getAttribute('href') || '';
//             var hasDownload = a.hasAttribute('download');
//             if(!href) return;
//
//             if (href.startsWith('blob:')) {
//               e.preventDefault();
//               var n = a.getAttribute('download') || 'file';
//               window.__FlutterDownloadFromBlob(href, n);
//             } else if (hasDownload) {
//               e.preventDefault();
//               var n2 = a.getAttribute('download') || 'file';
//               post({ kind:'url', url: href, name: n2 });
//             }
//           }catch(_){}
//         }, true);
//       })();
//     ''';
//     try {
//       await _controller.runJavaScript(js);
//     } catch (_) {}
//   }
//
//   // ----------- BLOB streaming helpers -----------
//
//   Future<void> _blobStart(String name, String mime, int totalChunks) async {
//     final ext = _inferExtension(name, mime);
//     final baseName = _stripExt(name);
//     final tmpDir = await getTemporaryDirectory();
//     final tmpPath = '${tmpDir.path}/$baseName.$ext';
//
//     final raf = await File(tmpPath).open(mode: FileMode.write);
//     final sink = _BlobSink(
//       path: tmpPath,
//       raf: raf,
//       expectedChunks: totalChunks,
//       mime: mime,
//     );
//     _blobSinks[name] = sink;
//
//     final nid = await _notifyStart('$baseName.$ext');
//     _notifIdByName[name] = nid;
//
//     _toast('Starting download…');
//   }
//
//   Future<void> _blobAppend(String name, int index, String base64Part) async {
//     final sink = _blobSinks[name];
//     if (sink == null) return;
//     try {
//       final bytes = base64Decode(base64Part);
//       await sink.raf.writeFrom(bytes);
//       sink.receivedChunks++;
//
//       final nid = _notifIdByName[name];
//       if (nid != null && sink.expectedChunks > 0) {
//         if (sink.receivedChunks == sink.expectedChunks ||
//             sink.receivedChunks % 8 == 0) {
//           final pct = ((sink.receivedChunks * 100) / sink.expectedChunks).floor();
//           await _notifyProgress(nid, _basename(sink.path), pct);
//         }
//       }
//     } catch (e) {
//       debugPrint('blob append error: $e');
//     }
//   }
//
//   Future<void> _blobFinish(String name, String mime) async {
//     final sink = _blobSinks.remove(name);
//     if (sink == null) return;
//     await sink.raf.close();
//
//     // Move temp -> Downloads
//     final info = await _saveTempToDownloadsInfo(sink.path);
//
//     final msg = info == null ? 'Saved' : 'Saved to Downloads: ${info.name}';
//     final nid = _notifIdByName.remove(name);
//     if (nid != null) {
//       final payload = info?.uri.toString() ?? '';
//       await _notifyComplete(nid, _basename(sink.path), payload);
//     }
//
//     // ✅ temp delete baad me
//     try { await File(sink.path).delete(); } catch (_) {}
//
//     _toast(msg);
//   }
//
//   // ----------- HTTP(S) DOWNLOAD helpers -----------
//
//   Future<void> _downloadHttpToDownloads(String url, {String? suggestedName}) async {
//     final dio = Dio(BaseOptions(
//       followRedirects: true,
//       headers: _pageCookies != null && _pageCookies!.isNotEmpty
//           ? {'Cookie': _pageCookies!}
//           : null,
//     ));
//
//     final tentativeName = _filenameFromUrl(url) ?? suggestedName ?? 'file';
//     final extGuess = _inferExtension(tentativeName, 'application/octet-stream');
//     final notifTitle = tentativeName.endsWith('.$extGuess')
//         ? tentativeName
//         : '$tentativeName.$extGuess';
//     final nid = await _notifyStart(notifTitle);
//
//     // temp path
//     final tmp = await getTemporaryDirectory();
//     String tmpPath = '${tmp.path}/$notifTitle';
//
//     try {
//       int lastPct = -1;
//       await dio.download(
//         url,
//         tmpPath,
//         onReceiveProgress: (received, total) async {
//           if (total > 0) {
//             final pct = (received * 100 / total).floor();
//             if (pct != lastPct && (pct == 100 || pct % 2 == 0)) {
//               lastPct = pct;
//               await _notifyProgress(nid, notifTitle, pct);
//             }
//           }
//         },
//         options: Options(responseType: ResponseType.bytes),
//       );
//
//       // HEAD to detect final filename if provided
//       String finalName = notifTitle;
//       try {
//         final resp = await dio.head(url);
//         final headersMap = resp.headers.map;
//         final fn = _filenameFromHeaders(headersMap);
//         if (fn != null && fn.trim().isNotEmpty) {
//           final target = '${tmp.path}/$fn';
//           if (target != tmpPath) {
//             try {
//               await File(tmpPath).rename(target);
//               tmpPath = target;
//               finalName = fn;
//             } catch (_) {
//               // rename failed -> keep tmpPath
//             }
//           } else {
//             finalName = fn;
//           }
//         }
//       } catch (_) {
//         // ignore head failures
//       }
//
//       // save to Downloads
//       final info = await _saveTempToDownloadsInfo(tmpPath);
//
//       final payload = info?.uri?.toString() ?? '';
//       await _notifyComplete(nid, finalName, payload); // ✅ notify first
//
//       // ✅ delete baad me
//       try { await File(tmpPath).delete(); } catch (_) {}
//
//       _toast(info == null ? 'Saved' : 'Saved to Downloads: ${info.name}');
//
//
//     } catch (e) {
//       debugPrint('Download error: $e');
//       await _flnp.cancel(nid);
//       _toast('Download failed');
//       // fallback
//       try {
//         await _openExternally(url);
//       } catch (_) {}
//     }
//   }
//
//   // Move temp -> Downloads (root) via MediaStore, return SaveInfo (has uri & name)
//   Future<SaveInfo?> _saveTempToDownloadsInfo(String tempPath) async {
//     if (!Platform.isAndroid) {
//       // iOS ya others: (Downloads concept nahi hota) — yahan null return
//       return null;
//     }
//
//     await MediaStore.ensureInitialized(); // 👈 yaha call add karo
//
//     final ms = MediaStore();
//     final info = await ms.saveFile(
//       tempFilePath: tempPath,
//       dirType: DirType.download,
//       relativePath: "",
//       dirName: DirName.download, // root of Downloads
//     );
//     return info;
//   }
//
//
//   // ----------- small utils -----------
//
//   String _basename(String fullPath) {
//     final i = fullPath.replaceAll('\\', '/').lastIndexOf('/');
//     return i >= 0 ? fullPath.substring(i + 1) : fullPath;
//   }
//
//   String _stripExt(String name) {
//     final i = name.lastIndexOf('.');
//     if (i > 0 && i < name.length - 1) return name.substring(0, i);
//     return name;
//   }
//
//   String _inferExtension(String name, String mime) {
//     final n = name.toLowerCase();
//     const known = ['.pdf','.doc','.docx','.xls','.xlsx','.csv','.zip','.rar','.7z','.apk','.ppt','.pptx'];
//     for (final e in known) {
//       if (n.endsWith(e)) return e.replaceFirst('.', '');
//     }
//     switch (mime) {
//       case 'application/pdf': return 'pdf';
//       case 'application/vnd.openxmlformats-officedocument.wordprocessingml.document': return 'docx';
//       case 'application/msword': return 'doc';
//       case 'application/vnd.ms-excel': return 'xls';
//       case 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet': return 'xlsx';
//       case 'text/csv': return 'csv';
//       case 'application/zip': return 'zip';
//       case 'application/vnd.android.package-archive': return 'apk';
//       case 'application/vnd.ms-powerpoint': return 'ppt';
//       case 'application/vnd.openxmlformats-officedocument.presentationml.presentation': return 'pptx';
//       default: return 'bin';
//     }
//   }
//
//   String? _filenameFromUrl(String url) {
//     try {
//       final uri = Uri.parse(url);
//       final seg = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : null;
//       if (seg == null || seg.isEmpty) return null;
//       return Uri.decodeComponent(seg);
//     } catch (_) {
//       return null;
//     }
//   }
//
//   String? _filenameFromHeaders(Map<String, List<String>> headers) {
//     final values = headers['content-disposition'] ?? headers['Content-Disposition'];
//     if (values == null || values.isEmpty) return null;
//     final v = values.first;
//
//     final m1 = RegExp(
//       r'''filename\*\s*=\s*(?:UTF-8'')("?)([^";]+)\1''',
//       caseSensitive: false,
//     ).firstMatch(v);
//     if (m1 != null) return Uri.decodeFull(m1.group(2)!);
//
//     final m2 = RegExp(
//       r'''filename\s*=\s*"([^"]+)"''',
//       caseSensitive: false,
//     ).firstMatch(v);
//     if (m2 != null) return m2.group(1);
//
//     final m3 = RegExp(
//       r'''filename\s*=\s*([^;]+)''',
//       caseSensitive: false,
//     ).firstMatch(v);
//     if (m3 != null) return m3.group(1)!.trim();
//
//     return null;
//   }
//
//   void _toast(String msg) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
//   }
//
//   @override
//   void dispose() {
//     for (final s in _blobSinks.values) {
//       try { s.raf.closeSync(); } catch (_) {}
//       try { File(s.path).deleteSync(); } catch (_) {}
//     }
//     _blobSinks.clear();
//     _controllerTwo.close();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white, // ✅ white
//       appBar: AppBar(
//         elevation: 0.3,
//         iconTheme: const IconThemeData(
//           color: kSecondaryColor,
//         ),
//         title: StreamBuilder<AppLogo>(
//           stream: _controllerTwo.stream,
//           builder: (context, snapshot) {
//             if (snapshot.connectionState == ConnectionState.waiting) {
//               return const SizedBox.shrink();
//             } else {
//               if (snapshot.error != null || snapshot.data == null) {
//                 return const Text("Error Occurred");
//               } else {
//                 return CachedNetworkImage(
//                   imageUrl: snapshot.data!.darkLogo.toString(),
//                   fit: BoxFit.contain,
//                   height: 27,
//                 );
//               }
//             }
//           },
//         ),
//         actions: <Widget>[
//           NavigationControls(webViewController: _controller),
//         ],
//         backgroundColor: kBackgroundColor,
//       ),
//       body: WebViewWidget(
//         controller: _controller,
//       ),
//     );
//   }
// }
//
// class NavigationControls extends StatelessWidget {
//   const NavigationControls({super.key, required this.webViewController});
//
//   final WebViewController webViewController;
//
//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: <Widget>[
//         IconButton(
//           icon: const Icon(Icons.arrow_back_ios),
//           onPressed: () async {
//             if (await webViewController.canGoBack()) {
//               await webViewController.goBack();
//             } else {
//               if (context.mounted) {
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(content: Text('No back history item')),
//                 );
//               }
//             }
//           },
//         ),
//         IconButton(
//           icon: const Icon(Icons.arrow_forward_ios),
//           onPressed: () async {
//             if (await webViewController.canGoForward()) {
//               await webViewController.goForward();
//             } else {
//               if (context.mounted) {
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(content: Text('No forward history item')),
//                 );
//               }
//             }
//           },
//         ),
//         IconButton(
//           icon: const Icon(Icons.replay),
//           onPressed: () => webViewController.reload(),
//         ),
//       ],
//     );
//   }
// }
//
// // ---- internal: streaming sink for blob ----
// class _BlobSink {
//   _BlobSink({
//     required this.path,
//     required this.raf,
//     required this.expectedChunks,
//     required this.mime,
//   });
//
//   final String path;
//   final RandomAccessFile raf;
//   final int expectedChunks;
//   final String mime;
//   int receivedChunks = 0;
// }
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
// ignore_for_file: use_build_context_synchronously
//
// import 'dart:convert';
// import 'package:cached_network_image/cached_network_image.dart';
// import '../api/api_client.dart';
// import 'package:academy_app/models/app_logo.dart';
// import 'package:flutter/material.dart';
// import 'dart:async';
// import 'package:webview_flutter/webview_flutter.dart';
// import '../constants.dart';
//
// class WebViewScreen extends StatefulWidget {
//   static const routeName = '/webview';
//
//   final String url;
//
//   const WebViewScreen({super.key, required this.url});
//
//   @override
//   // ignore: library_private_types_in_public_api
//   _WebViewScreenState createState() => _WebViewScreenState();
// }
//
// class _WebViewScreenState extends State<WebViewScreen> {
//   late final WebViewController _controller;
//   final _controllerTwo = StreamController<AppLogo>();
//
//   fetchMyLogo() async {
//     var url = '$BASE_URL/api/app_logo';
//     try {
//       final response = await ApiClient().get(url);
//       // print(response.body);
//       if (response.statusCode == 200) {
//         var logo = AppLogo.fromJson(jsonDecode(response.body));
//         _controllerTwo.add(logo);
//       }
//     } catch (error) {
//       rethrow;
//     }
//   }
//
//   @override
//   void initState() {
//     super.initState();
//     fetchMyLogo();
//     // #docregion platform_features
//     late final PlatformWebViewControllerCreationParams params;
//     params = const PlatformWebViewControllerCreationParams();
//
//     final WebViewController controller =
//         WebViewController.fromPlatformCreationParams(params);
//     // #enddocregion platform_features
//
//     controller
//       ..setJavaScriptMode(JavaScriptMode.unrestricted)
//       ..setBackgroundColor(const Color(0xFFFFFFFF))
//       ..enableZoom(false) //  Zoom disable
//       ..setNavigationDelegate(
//         NavigationDelegate(
//           onProgress: (int progress) {
//             debugPrint('WebView is loading (progress : $progress%)');
//           },
//           onPageStarted: (String url) {
//             debugPrint('Page started loading: $url');
//           },
//           onPageFinished: (String url) {
//             debugPrint('Page finished loading: $url');
//           },
//           onWebResourceError: (WebResourceError error) {
//             debugPrint('''
// Page resource error:
//   code: ${error.errorCode}
//   description: ${error.description}
//   errorType: ${error.errorType}
//   isForMainFrame: ${error.isForMainFrame}
//           ''');
//           },
//         ),
//       )
//       ..addJavaScriptChannel(
//         'Toaster',
//         onMessageReceived: (JavaScriptMessage message) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text(message.message)),
//           );
//         },
//       )
//       ..loadRequest(Uri.parse(widget.url));
//     // #enddocregion platform_features
//
//     _controller = controller;
//   }
//
//
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.green,
//       appBar: AppBar(
//         elevation: 0.3,
//         iconTheme: const IconThemeData(
//           color: kSecondaryColor, //change your color here
//         ),
//         title: StreamBuilder<AppLogo>(
//           stream: _controllerTwo.stream,
//           builder: (context, snapshot) {
//             if (snapshot.connectionState == ConnectionState.waiting) {
//               return Container();
//             } else {
//               if (snapshot.error != null) {
//                 return const Text("Error Occured");
//               } else {
//                 return CachedNetworkImage(
//                   imageUrl: snapshot.data!.darkLogo.toString(),
//                   fit: BoxFit.contain,
//                   height: 27,
//                 );
//               }
//             }
//           },
//         ),
//         actions: <Widget>[
//           NavigationControls(webViewController: _controller),
//         ],
//         backgroundColor: kBackgroundColor,
//       ),
//       body: WebViewWidget(
//         controller: _controller,
//       ),
//     );
//   }
//
//   Widget favoriteButton() {
//     return FloatingActionButton(
//       onPressed: () async {
//         final String? url = await _controller.currentUrl();
//         if (context.mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text('Favorited $url')),
//           );
//         }
//       },
//       child: const Icon(Icons.favorite),
//     );
//   }
// }
//
// class NavigationControls extends StatelessWidget {
//   const NavigationControls({super.key, required this.webViewController});
//
//   final WebViewController webViewController;
//
//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: <Widget>[
//         IconButton(
//           icon: const Icon(Icons.arrow_back_ios), //arrow_back_ios
//           onPressed: () async {
//             if (await webViewController.canGoBack()) {
//               await webViewController.goBack();
//             } else {
//               if (context.mounted) {
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(content: Text('No back history item')),
//                 );
//               }
//             }
//           },
//         ),
//         IconButton(
//           icon: const Icon(Icons.arrow_forward_ios),
//           onPressed: () async {
//             if (await webViewController.canGoForward()) {
//               await webViewController.goForward();
//             } else {
//               if (context.mounted) {
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(content: Text('No forward history item')),
//                 );
//               }
//             }
//           },
//         ),
//         IconButton(
//           icon: const Icon(Icons.replay),
//           onPressed: () => webViewController.reload(),
//         ),
//       ],
//     );
//   }
// }
//
//

// ignore_for_file: use_build_context_synchronously



import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
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
import 'package:flutter_file_dialog/flutter_file_dialog.dart'; // ✅ NEW

// ---------------- NOTIFICATION SETUP ----------------
final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

Future<void> initNotifications() async {
  const AndroidInitializationSettings initSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initSettings =
  InitializationSettings(android: initSettingsAndroid);

  // Optional: background tap ke liye (plugin ≥ 12.x)
  @pragma('vm:entry-point')
  Future<void> _bgTap(NotificationResponse resp) async {
    debugPrint('🔔[BG TAP] payload(raw)= ${resp.payload}');
  }

  await _notifications.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (NotificationResponse resp) async {
      debugPrint('🔔[TAP] actionId=${resp.actionId}');
      debugPrint('🔔[TAP] payload(raw)= ${resp.payload}');

      final payload = resp.payload;
      if (payload == null || payload.isEmpty) {
        debugPrint('🔔[TAP] No payload, returning.');
        return;
      }

      // --- Try JSON first ---
      try {
        final obj = jsonDecode(payload);
        debugPrint('🔔[TAP] payload(json)= $obj');

        if (obj is Map) {
          final uriStr   = (obj['uri'] ?? '').toString();
          final path     = (obj['path'] ?? '').toString();      // temp/cache copy
          final docPath  = (obj['docPath'] ?? '').toString();   // ✅ persistent copy (new)
          final mime     = (obj['mime'] ?? '').toString();
          final name     = (obj['name'] ?? '').toString();
          debugPrint('🔔[TAP] uri="$uriStr" path="$path" docPath="$docPath" mime="$mime" name="$name"');

          // 1) Sirf valid content:// pe external open try karo
          if (uriStr.startsWith('content://')) {
            try {
              final ok = await launchUrl(Uri.parse(uriStr), mode: LaunchMode.externalApplication);
              debugPrint('🔔[TAP] launchUrl(content://) -> $ok');
              if (ok) return;
            } catch (e, st) {
              debugPrint('🔔[TAP] launchUrl(content://) failed: $e\n$st');
              // continue to file fallbacks
            }
          } else {
            debugPrint('🔔[TAP] uri not content:// (value="$uriStr") → skipping launchUrl');
          }

          // 2) Persistent documents copy preferred
          if (docPath.isNotEmpty && File(docPath).existsSync()) {
            final res = await OpenFile.open(docPath);
            debugPrint('🔔[TAP] OpenFile.open(docPath) -> type=${res.type} message=${res.message}');
            return;
          }

          // 3) Fallback: cache/temp copy
          if (path.isNotEmpty && File(path).existsSync()) {
            final res = await OpenFile.open(path);
            debugPrint('🔔[TAP] OpenFile.open(path) -> type=${res.type} message=${res.message}');
            return;
          }

          debugPrint('🔔[TAP] Nothing opened (uri invalid & files missing).');
        }
      } catch (e, st) {
        debugPrint('🔔[TAP] JSON parse failed: $e\n$st');
      }

      // --- Legacy fallbacks (non-JSON payloads only) ---
      try {
        if (payload.startsWith('content://')) {
          final ok = await launchUrl(Uri.parse(payload), mode: LaunchMode.externalApplication);
          debugPrint('🔔[TAP] legacy launchUrl(content://) -> $ok');
          return;
        }
        if (payload.startsWith('file://')) {
          final res = await OpenFile.open(payload);
          debugPrint('🔔[TAP] legacy OpenFile.open(file://) -> type=${res.type} message=${res.message}');
          return;
        }
        final exists = File(payload).existsSync();
        debugPrint('🔔[TAP] legacy local file exists? $exists @ $payload');
        if (exists) {
          final res = await OpenFile.open(payload);
          debugPrint('🔔[TAP] legacy OpenFile.open(path) -> type=${res.type} message=${res.message}');
          return;
        }
        // Agar yeh bhi nahi, to attempt parse as URL (may throw if not a URL)
        final ok = await launchUrl(Uri.parse(payload), mode: LaunchMode.externalApplication);
        debugPrint('🔔[TAP] legacy launchUrl(url) -> $ok');
      } catch (e, st) {
        debugPrint('🔔[TAP] legacy open failed: $e\n$st');
      }
    },
  );

}
// ----------------------------------------------------

class WebViewScreen extends StatefulWidget {
  static const routeName = '/webview';
  final String url;

  const WebViewScreen({super.key, required this.url});

  @override
  _WebViewScreenState createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  final _controllerTwo = StreamController<AppLogo>();
  static const _notify = MethodChannel('greylearn/notify');


  fetchMyLogo() async {
    var url = '$BASE_URL/api/app_logo';
    try {
      final response = await ApiClient().get(url);
      if (response.statusCode == 200) {
        var logo = AppLogo.fromJson(jsonDecode(response.body));
        _controllerTwo.add(logo);
      }
    } catch (error) {
      rethrow;
    }
  }

  @override
  void initState() {
    super.initState();
    fetchMyLogo();
    initNotifications(); // ✅ ensure notifications callback is wired

    late final PlatformWebViewControllerCreationParams params;
    params = const PlatformWebViewControllerCreationParams();

    final WebViewController controller = WebViewController.fromPlatformCreationParams(params);

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFFFFFFF))
      ..enableZoom(false)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest req) {
            final url = req.url;
            // // ✅ 1) GreyLearn App-Link ko pakdo aur OS ko handover karo
            if (_isGreyLearnAppLink(url)) {
              _openAppLink(url);                 // externalNonBrowserApplication
              return NavigationDecision.prevent; // WebView me mat kholna
            }
            
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
              final mime = (obj['mime'] ?? 'application/octet-stream').toString();
              final b64 = (obj['data'] ?? '').toString();
              if (b64.isEmpty) return;

              final bytes = base64Decode(b64);
              final ext = _inferExtension(name, mime);

              final saved = await _saveFileCompat(
                name: _stripExt(name),
                bytes: bytes,
                ext: ext,
                mime: mime,
              );

              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(saved != null ? 'Saved to Downloads' : 'Save cancelled')),
              );

            } else if (kind == 'url') {
              // ✅ Instead of opening externally, download and SAVE via dialog
              final url = (obj['url'] ?? '').toString();
              final suggested = (obj['name'] ?? 'file').toString();
              if (url.isNotEmpty) {
                await _downloadAndSaveByUrl(url, suggestedName: suggested);
              }
            }
          } catch (_) {
            // Fallback: old behavior
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
      '.pdf', '.doc', '.docx', '.xls', '.xlsx', '.csv',
      '.zip', '.rar', '.7z', '.apk', '.ppt', '.pptx'
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
    final safeName = (name ?? 'file').replaceAll(r'\', r'\\').replaceAll("'", r"\'");
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
      '.pdf','.doc','.docx','.xls','.xlsx','.csv',
      '.zip','.rar','.7z','.apk','.ppt','.pptx'
    ];
    for (final e in known) {
      if (n.endsWith(e)) return e.replaceFirst('.', '');
    }
    switch (mime) {
      case 'application/pdf': return 'pdf';
      case 'application/msword': return 'doc';
      case 'application/vnd.openxmlformats-officedocument.wordprocessingml.document': return 'docx';
      case 'application/vnd.ms-excel': return 'xls';
      case 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet': return 'xlsx';
      case 'text/csv': return 'csv';
      case 'application/zip': return 'zip';
      case 'application/vnd.android.package-archive': return 'apk';
      case 'application/vnd.ms-powerpoint': return 'ppt';
      case 'application/vnd.openxmlformats-officedocument.presentationml.presentation': return 'pptx';
      default: return 'bin';
    }
  }

  /// ✅ Download from direct URL and then save via dialog
  Future<void> _downloadAndSaveByUrl(String url, {String? suggestedName}) async {
    try {
      final resp = await http.get(Uri.parse(url));
      if (resp.statusCode != 200) {
        // fallback open externally
        await _openExternally(url);
        return;
      }

      final mime = resp.headers['content-type'] ?? 'application/octet-stream';
      final nameOnly = _stripExt((suggestedName ?? 'file').trim());
      final ext = _inferExtension(suggestedName ?? 'file', mime);

      final saved = await _saveFileCompat(
        name: nameOnly.isEmpty ? 'file' : nameOnly,
        bytes: resp.bodyBytes,
        ext: ext,
        mime: mime,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(saved != null ? 'Saved to Downloads' : 'Save cancelled')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download error: $e')),
      );
    }
  }

  /// ✅ Save file using SAF dialog (Android) / Documents (iOS)
  Future<String?> _saveFileCompat({
    required String name,
    required List<int> bytes,
    required String ext,
    required String mime,
  }) async {
    try {
      final fileName = '$name.$ext';

      if (Platform.isAndroid) {
        // Write to temp first
        final tmpDir = await getTemporaryDirectory();
        final tmpPath = '${tmpDir.path}/$fileName';
        final tmpFile = File(tmpPath);
        await tmpFile.writeAsBytes(bytes);


        // Show system Save dialog (defaults to Downloads)
        final savedUri = await FlutterFileDialog.saveFile(
          params: SaveFileDialogParams(
            sourceFilePath: tmpPath,
            fileName: fileName,
            mimeTypesFilter: [mime],
            localOnly: true,
          ),
        );

        if (savedUri == null) return null;
        // 3) ✅ Persistent app-docs copy for reliable open later
        final docsDir = await getApplicationDocumentsDirectory();
        final docPath = '${docsDir.path}/$fileName';
        await File(docPath).writeAsBytes(bytes);

// 4) (Optional) Cache copy you already had
        final cacheDir = await getTemporaryDirectory();
        final cachePath = '${cacheDir.path}/$fileName';
        await File(cachePath).writeAsBytes(bytes);

        // Ask native to show a notification that opens the file directly
        try {
          await _notify.invokeMethod('showFileOpenNotification', {
            'name': fileName,
            'path': cachePath,
            'mime': mime,
          });
        } catch (e) {
          debugPrint('❌ native notify error: $e');
        }

// JSON payload bhejo: uri (content://) + cache path
        final payloadMap = {
          'uri': savedUri ?? '',   // may be 'content://…' or '/document/…'
          'path': cachePath,       // temp/cache
          'docPath': docPath,      // ✅ persistent
          'mime': mime,
          'name': fileName,
        };
        final payload = jsonEncode(payloadMap);
        debugPrint('💾[SAVE] savedUri=$savedUri');
        debugPrint('💾[SAVE] cachePath=$cachePath');
        debugPrint('💾[SAVE] docPath=$docPath');
        debugPrint('💾[SAVE] payload(json)= $payload');
        // Notify (payload = URI so OpenFile can try to open)
        // const androidDetails = AndroidNotificationDetails(
        //   'downloads_channel',
        //   'Downloads',
        //   channelDescription: 'File downloads',
        //   importance: Importance.high,
        //   priority: Priority.high,
        //   showWhen: true,
        // );
        // const platformDetails = NotificationDetails(android: androidDetails);
        //
        // await _notifications.show(
        //   0,
        //   'Download complete',
        //   '$fileName saved',
        //   platformDetails,
        //   payload: payload, // content:// URI
        // );

        return savedUri ?? cachePath;
      } else {
        // iOS / others: app docs
        final docs = await getApplicationDocumentsDirectory();
        final out = File('${docs.path}/$fileName');
        await out.writeAsBytes(bytes);

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
          '$fileName saved',
          platformDetails,
          payload: out.path,
        );
        return out.path;
      }
    } catch (e) {
      debugPrint('❌ Save error: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<AppLogo>(
          stream: _controllerTwo.stream,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return CachedNetworkImage(
                imageUrl: snapshot.data!.darkLogo.toString(),
                height: 27,
              );
            }
            return const Text("");
          },
        ),
        actions: <Widget>[NavigationControls(webViewController: _controller)],
        backgroundColor: kBackgroundColor,
      ),
      body: WebViewWidget(controller: _controller),
    );
  }

  bool _isGreyLearnAppLink(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    if (!['http', 'https'].contains(uri.scheme)) return false;

    final host = uri.host.toLowerCase();
    if (host != 'learn.greylearn.com' && host != 'www.learn.greylearn.com') {
      return false;
    }

    final p = uri.path.toLowerCase();
    // ✅ DeepLinkService ke saare heads cover
    return p.startsWith('/go/smart-open') ||
        p.startsWith('/course') ||
        p.startsWith('/courses') ||
        p.startsWith('/my_course') ||
        p.startsWith('/account') ||
        p.startsWith('/edit_profile') ||
        p.startsWith('/job');
  }

  Future<void> _openAppLink(String url) async {
    // OS ko bolo: browser nahi, app khol (App Link resolve karega)
    await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalNonBrowserApplication,
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
          onPressed: () async {
            final currentUrl = await webViewController.currentUrl();
            if (currentUrl != null) {
              await webViewController.loadRequest(Uri.parse('about:blank'));
              await Future.delayed(const Duration(milliseconds: 200));
              await webViewController.loadRequest(Uri.parse(currentUrl));
            }
          },
        ),
      ],
    );
  }
}







































// import 'dart:convert';
// import 'dart:async';
// import 'dart:io';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter/services.dart';
// import '../api/api_client.dart';
// import 'package:academy_app/models/app_logo.dart';
// import 'package:flutter/material.dart';
// import 'package:webview_flutter/webview_flutter.dart';
// import '../constants.dart';
// // ✅ Added imports
// import 'package:url_launcher/url_launcher.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:open_file/open_file.dart';
//
// // ---------------- NOTIFICATION SETUP ----------------
// final FlutterLocalNotificationsPlugin _notifications =
// FlutterLocalNotificationsPlugin();
//
// const MethodChannel _files = MethodChannel('app.intent.files'); // ⬅️ add this
//
//
// Future<void> initNotifications() async {
//   const AndroidInitializationSettings initSettingsAndroid =
//   AndroidInitializationSettings('@mipmap/ic_launcher');
//   const InitializationSettings initSettings =
//   InitializationSettings(android: initSettingsAndroid);
//   await _notifications.initialize(initSettings,
//       onDidReceiveNotificationResponse: (resp) {
//         final payload = resp.payload;
//         if (payload != null && payload.isNotEmpty) {
//           OpenFile.open(payload); // ✅ open file on notification tap
//         }
//       });
// }
// // ----------------------------------------------------
//
// class WebViewScreen extends StatefulWidget {
//   static const routeName = '/webview';
//   final String url;
//
//   const WebViewScreen({super.key, required this.url});
//
//   @override
//   _WebViewScreenState createState() => _WebViewScreenState();
// }
//
// class _WebViewScreenState extends State<WebViewScreen> {
//   late final WebViewController _controller;
//   final _controllerTwo = StreamController<AppLogo>();
//
//   fetchMyLogo() async {
//     var url = '$BASE_URL/api/app_logo';
//     try {
//       final response = await ApiClient().get(url);
//       if (response.statusCode == 200) {
//         var logo = AppLogo.fromJson(jsonDecode(response.body));
//         _controllerTwo.add(logo);
//       }
//     } catch (error) {
//       rethrow;
//     }
//   }
//
//   @override
//   void initState() {
//     super.initState();
//     fetchMyLogo();
//
//     late final PlatformWebViewControllerCreationParams params;
//     params = const PlatformWebViewControllerCreationParams();
//
//     final WebViewController controller =
//     WebViewController.fromPlatformCreationParams(params);
//
//     controller
//       ..setJavaScriptMode(JavaScriptMode.unrestricted)
//       ..setBackgroundColor(const Color(0xFFFFFFFF))
//       ..enableZoom(false)
//       ..setNavigationDelegate(
//         NavigationDelegate(
//           onNavigationRequest: (NavigationRequest req) {
//             final url = req.url;
//             if (url.startsWith('blob:')) {
//               _requestBlobViaJS(url);
//               return NavigationDecision.prevent;
//             }
//             if (_shouldOpenExternally(url)) {
//               _openExternally(url);
//               return NavigationDecision.prevent;
//             }
//             return NavigationDecision.navigate;
//           },
//           onPageFinished: (String url) async {
//             await _injectDownloadCatcher();
//           },
//         ),
//       )
//       ..addJavaScriptChannel(
//         'Downloader',
//         onMessageReceived: (JavaScriptMessage message) async {
//           final raw = message.message;
//           try {
//             final obj = jsonDecode(raw) as Map<String, dynamic>;
//             final kind = (obj['kind'] ?? '').toString();
//             if (kind == 'blob') {
//               final name = (obj['name'] ?? 'file').toString();
//               final mime =
//               (obj['mime'] ?? 'application/octet-stream').toString();
//               final b64 = (obj['data'] ?? '').toString();
//               if (b64.isEmpty) return;
//               final bytes = base64Decode(b64);
//               final ext = _inferExtension(name, mime);
//
//               final savedPath = await _saveFileCompat(
//                 name: _stripExt(name),
//                 bytes: bytes,
//                 ext: ext,
//                 mime: mime,
//               );
//
//               if (!mounted) return;
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(
//                     content: Text(savedPath != null
//                         ? 'Saved: $savedPath'
//                         : 'Saved to Downloads')),
//               );
//             } else if (kind == 'url') {
//               final url = (obj['url'] ?? '').toString();
//               if (url.isNotEmpty) await _openExternally(url);
//             }
//           } catch (_) {
//             final url = raw;
//             if (url.startsWith('blob:')) {
//               _requestBlobViaJS(url);
//             } else if (url.isNotEmpty) {
//               await _openExternally(url);
//             }
//           }
//         },
//       )
//       ..loadRequest(Uri.parse(widget.url));
//
//     _controller = controller;
//   }
//
//   // ✅ Decide if link should open externally
//   bool _shouldOpenExternally(String url) {
//     final uri = Uri.tryParse(url);
//     if (uri == null) return false;
//     if (!['http', 'https'].contains(uri.scheme)) return true;
//
//     final lower = url.toLowerCase();
//     const exts = [
//       '.pdf',
//       '.doc',
//       '.docx',
//       '.xls',
//       '.xlsx',
//       '.csv',
//       '.zip',
//       '.rar',
//       '.7z',
//       '.apk',
//       '.ppt',
//       '.pptx'
//     ];
//     if (exts.any(lower.endsWith)) return true;
//     if (lower.contains('download=')) return true;
//     return false;
//   }
//
//   Future<void> _openExternally(String url) async {
//     final uri = Uri.parse(url);
//     await launchUrl(uri, mode: LaunchMode.externalApplication);
//   }
//
//   Future<void> _requestBlobViaJS(String blobUrl, {String? name}) async {
//     final safeUrl = blobUrl.replaceAll(r'\', r'\\').replaceAll("'", r"\'");
//     final safeName =
//     (name ?? 'file').replaceAll(r'\', r'\\').replaceAll("'", r"\'");
//     final js =
//         "window.__FlutterDownloadFromBlob && window.__FlutterDownloadFromBlob('$safeUrl', '$safeName');";
//     try {
//       await _controller.runJavaScript(js);
//     } catch (_) {}
//   }
//
//   Future<void> _injectDownloadCatcher() async {
//     const js = r'''
//       (function(){
//         if (window.__FLUTTER_DL_INSTALLED) return;
//         window.__FLUTTER_DL_INSTALLED = true;
//         function post(obj){ Downloader.postMessage(JSON.stringify(obj)); }
//         window.__FlutterDownloadFromBlob = function(url, name){
//           fetch(url).then(r=>r.blob()).then(b=>{
//             var reader = new FileReader();
//             reader.onloadend = function(){
//               var dataUrl = reader.result || '';
//               var m = /^data:(.*?);base64,(.*)$/.exec(dataUrl);
//               var mime = (m && m[1]) || b.type || 'application/octet-stream';
//               var base64 = (m && m[2]) || '';
//               post({ kind:'blob', name: name||'file', mime: mime, data: base64 });
//             };
//             reader.readAsDataURL(b);
//           });
//         };
//         document.addEventListener('click', function(e){
//           var a = e.target && e.target.closest ? e.target.closest('a') : null;
//           if(!a) return;
//           var href = a.getAttribute('href') || '';
//           var hasDownload = a.hasAttribute('download');
//           if(!href) return;
//           if (href.startsWith('blob:')) {
//             e.preventDefault();
//             var n = a.getAttribute('download') || 'file';
//             window.__FlutterDownloadFromBlob(href, n);
//           } else if (hasDownload) {
//             e.preventDefault();
//             var n2 = a.getAttribute('download') || 'file';
//             post({ kind:'url', url: href, name: n2 });
//           }
//         }, true);
//       })();
//     ''';
//     try {
//       await _controller.runJavaScript(js);
//     } catch (_) {}
//   }
//
//   String _stripExt(String name) {
//     final i = name.lastIndexOf('.');
//     if (i > 0 && i < name.length - 1) return name.substring(0, i);
//     return name;
//   }
//
//   String _inferExtension(String name, String mime) {
//     final n = name.toLowerCase();
//     const known = [
//       '.pdf',
//       '.doc',
//       '.docx',
//       '.xls',
//       '.xlsx',
//       '.csv',
//       '.zip',
//       '.rar',
//       '.7z',
//       '.apk',
//       '.ppt',
//       '.pptx'
//     ];
//     for (final e in known) {
//       if (n.endsWith(e)) return e.replaceFirst('.', '');
//     }
//     switch (mime) {
//       case 'application/pdf':
//         return 'pdf';
//       case 'application/msword':
//         return 'doc';
//       case 'application/vnd.openxmlformats-officedocument.wordprocessingml.document':
//         return 'docx';
//       case 'application/vnd.ms-excel':
//         return 'xls';
//       case 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet':
//         return 'xlsx';
//       case 'text/csv':
//         return 'csv';
//       case 'application/zip':
//         return 'zip';
//       case 'application/vnd.android.package-archive':
//         return 'apk';
//       case 'application/vnd.ms-powerpoint':
//         return 'ppt';
//       case 'application/vnd.openxmlformats-officedocument.presentationml.presentation':
//         return 'pptx';
//       default:
//         return 'bin';
//     }
//   }
//
//
//
//   /// ✅ Save file to Downloads and show notification
//   Future<String?> _saveFileCompat({
//     required String name,
//     required List<int> bytes,
//     required String ext,
//     required String mime,
//   }) async {
//     try {
//       // ✅ Android me direct Downloads folder
//       Directory dir = Directory("/storage/emulated/0/Download");
//       if (!await dir.exists()) {
//         dir = await getApplicationDocumentsDirectory(); // fallback
//       }
//
//       final filePath = "${dir.path}/$name.$ext";
//       final file = File(filePath);
//       await file.writeAsBytes(bytes);
// // // ⬇️ NEW: Android par parent folder (DocumentsUI) open kar do.
// // // Agar koi issue aaya to Downloads screen khol do.
// // // iOS par kuch mat karo.
// //       if (Platform.isAndroid) {
// //         try {
// //           await _files.invokeMethod('openFolderOrFile', {'path': filePath});
// //         } catch (_) {
// //           try {
// //             await _files.invokeMethod('openDownloads');
// //           } catch (__){}
// //         }
// //       }
//
//       // ✅ Notification setup
//       const androidDetails = AndroidNotificationDetails(
//         'downloads_channel',
//         'Downloads',
//         channelDescription: 'File downloads',
//         importance: Importance.high,
//         priority: Priority.high,
//         showWhen: true,
//       );
//       const platformDetails = NotificationDetails(android: androidDetails);
//
//       await _notifications.show(
//         0,
//         'Download complete',
//         '$name.$ext saved to Downloads',
//         platformDetails,
//         payload: filePath, // 👈 yeh wahi path hoga jo humne save kiya
//       );
//       print('👈Save File : ${filePath} ');
//       return filePath;
//     } catch (e) {
//       debugPrint("❌ Save error: $e");
//       return null;
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: StreamBuilder<AppLogo>(
//           stream: _controllerTwo.stream,
//           builder: (context, snapshot) {
//             if (snapshot.hasData) {
//               return CachedNetworkImage(
//                 imageUrl: snapshot.data!.darkLogo.toString(),
//                 height: 27,
//               );
//             }
//             return const Text("");
//           },
//         ),
//         actions: <Widget>[NavigationControls(webViewController: _controller)],
//         backgroundColor: kBackgroundColor,
//       ),
//       body: WebViewWidget(controller: _controller),
//     );
//   }
// }
//
// class NavigationControls extends StatelessWidget {
//   const NavigationControls({super.key, required this.webViewController});
//
//   final WebViewController webViewController;
//
//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: <Widget>[
//         IconButton(
//           icon: const Icon(Icons.arrow_back_ios),
//           onPressed: () async {
//             if (await webViewController.canGoBack()) {
//               await webViewController.goBack();
//             }
//           },
//         ),
//         IconButton(
//           icon: const Icon(Icons.arrow_forward_ios),
//           onPressed: () async {
//             if (await webViewController.canGoForward()) {
//               await webViewController.goForward();
//             }
//           },
//         ),
//         IconButton(
//             icon: const Icon(Icons.replay),
//             // onPressed: () => webViewController.reload(),
//             onPressed: () async {
//               final currentUrl = await webViewController.currentUrl();
//               if (currentUrl != null) {
//                 // Force clear and reload the current page
//                 await webViewController.loadRequest(Uri.parse('about:blank'));
//                 await Future.delayed(const Duration(milliseconds: 200));
//                 await webViewController.loadRequest(Uri.parse(currentUrl));
//               }
//             }),
//       ],
//     );
//   }
// }

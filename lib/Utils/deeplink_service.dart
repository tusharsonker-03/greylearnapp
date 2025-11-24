

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// Your app screens/routes
import 'package:academy_app/screens/courses_screen.dart';
import 'package:academy_app/screens/edit_profile_screen.dart';
import '../Utils/deeplink_gate.dart';

// ⚠️ Adjust the import below to your actual NavigationService path/name
import 'package:academy_app/Utils/navigation_service.dart';

import '../constants.dart';
import '../main.dart';
import '../providers/shared_pref_helper.dart';

// ✅ DL screen (the only target for course details)
import '../screens/coursedetailscreendeeiplink.dart';

import '../screens/newcoursedetail_landing_page.dart';
import '../screens/tabs_screen.dart';

class DeepLinkService {
  DeepLinkService(this._navKey);

  final GlobalKey<NavigatorState> _navKey;

  late final AppLinks _appLinks;
  StreamSubscription<Uri?>? _sub;
  Uri? _last;
  bool _navToCoursesBusy = false; // duplicate course nav ko roke
  DateTime? _lastHandledAt;
  static const Duration _dupWindow = Duration(seconds: 3);

  // Flags
  bool _fromInitial = false;

  void _d(String msg) {
    if (kDebugMode) {
      debugPrint('[DL] $msg');
      // rootScaffoldMessengerKey.currentState?.showSnackBar(
      //   SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
      // );
    }
  }

  Future<void> init() async {
    _d('init()');
    _appLinks = AppLinks();

    // Live links while app is running/resumed
    _sub = _appLinks.uriLinkStream.listen(
          (uri) {
        _d('STREAM got: $uri');
        // fire-and-forget; handle has internal gating
        // ignore: discarded_futures
        _handle(uri, source: 'STREAM');
      },
      onError: (e, st) => _d('STREAM error: $e\n$st'),
      onDone: () => _d('STREAM done'),
      cancelOnError: false,
    );

    // Cold start link (app killed state)
    final initial = await _appLinks.getInitialLink();
    _d('getInitialLink(): $initial');
    if (initial != null) {
      _fromInitial = true;
      await _handle(initial, source: 'INITIAL');
      _fromInitial = false;
    }
  }

  void dispose() {
    _d('dispose() → cancel stream sub');
    _sub?.cancel();
  }

  NavigatorState? get _nav => _navKey.currentState;

  Future<void> _handle(Uri? uri, {required String source}) async {
    if (uri == null) {
      _d('($source) null uri → return');
      return;
    }
    _d('Handling ($source): $uri');

    // INITIAL → wait navigator ready
    if (source == 'INITIAL') {
      await _waitForNavigatorReady();
    }

    // ✅ 3s window me same URI ko ignore karo (INITIAL + STREAM duplicate)
    final now = DateTime.now();
    if (_last != null &&
        _last.toString() == uri.toString() &&
        _lastHandledAt != null &&
        now.difference(_lastHandledAt!) < _dupWindow) {
      _d('($source) duplicate within $_dupWindow → ignored');
      return;
    }
    _last = uri;
    _lastHandledAt = now;

    // Lightweight busy gate
    if (_navToCoursesBusy) {
      _d('($source) busy gate active → skipping');
      return;
    }
    _navToCoursesBusy = true;
    Future.delayed(const Duration(seconds: 2), () {
      _navToCoursesBusy = false;
      _d('busy gate released');
    });

    final scheme = uri.scheme.toLowerCase(); // expect https
    final host = uri.host.toLowerCase();

    _d('Parsed → scheme=$scheme host=$host segs=${uri.pathSegments} query=${uri.queryParameters}');

    // -------------- HTTPS HANDLING --------------
    const allowedHosts = {'learn.greylearn.com', 'www.learn.greylearn.com'};
    if (scheme == 'https' && allowedHosts.contains(host)) {
      // ==== 1) Clean path: remove encoded/decoded {{...}} tokens ====
      String path = Uri.decodeFull(uri.path);

      // Remove %7B%7B...%7D%7D (case-insensitive)
      final RegExp encToken = RegExp(r'%7B%7B.*?%7D%7D', caseSensitive: false);
      path = path.replaceAll(encToken, '');

      // Remove {{...}}
      final RegExp decToken = RegExp(r'\{\{.*?\}\}');
      path = path.replaceAll(decToken, '');

      // Normalize slashes
      path = path.replaceAll(RegExp(r'/{2,}'), '/').trim();

      // Split to segments
      final List<String> cleanedRaw = path
          .split('/')
          .where((s) => s.isNotEmpty)
          .map((s) => s.trim())
          .toList();
      final List<String> low = cleanedRaw.map((s) => s.toLowerCase()).toList();

      _d('CLEANED path="$path", segs=$cleanedRaw');

      // ==== 2) Strip known prefixes like /go/smart-open/... ====
      bool _isPrefix(String s) =>
          s == 'go' ||
              s == 'smart-open' ||
              s == 'smart_open' ||
              s == 'smartopen' ||
              s == 'open' ||
              s == 'i';

      while (low.isNotEmpty && (_isPrefix(low.first) || low.first.isEmpty)) {
        cleanedRaw.removeAt(0);
        low.removeAt(0);
      }

      if (low.isEmpty) {
        _d('root (after strip) → home');
        await _safeNav((nav) => nav.pushNamed('/home'));
        return;
      }

      /* ---------- A) numeric head only (e.g. /.../{{1}}123 -> 123) ---------- */
      final String headRaw0 = cleanedRaw.first;
      final String headNoTpl0 =
      headRaw0.replaceAll(RegExp(r'\{\{.*?\}\}'), '').trim();
      if (RegExp(r'^\d+$').hasMatch(headNoTpl0)) {
        final int id = int.parse(headNoTpl0);
        _d('numeric head detected → goCourseById($id)');
        await _goCourseById(id);
        return;
      }

      /* ---------- B) glued forms like "courses1" or "course123" ---------- */
      final String glued = headNoTpl0; // e.g. "courses1"
      final gluedMatch = RegExp(r'^(courses?|course)(\d+)$', caseSensitive: false)
          .firstMatch(glued);
      if (gluedMatch != null) {
        final int id = int.parse(gluedMatch.group(2)!);
        _d('glued form "$glued" → id=$id');
        await _goCourseById(id);
        return;
      }

      final String head = low.first;
      _d('HTTPS head=$head (after strip), segs=$cleanedRaw');

      // ==== 4) Normal routing ====
      switch (head) {
        case 'my_course':
          _d('route: my_course');
          await _MyCourse();
          return;

        case 'job':
          _d('route: job');
          await _Myjob();
          return;

        case 'account':
          _d('route: account');
          _goAccount();
          return;

        case 'edit_profile':
          _d('route: edit_profile');
          await _goEditProfile();
          return;

        case 'course': {
          // /course/<slug>
          final slug = (cleanedRaw.length >= 2
              ? cleanedRaw[1]
              : (uri.queryParameters['slug'] ?? uri.queryParameters['id']))
              ?.trim();
          _d('route: course, slug=$slug');
          if (_isNotBlank(slug)) {
            await _goCourse(slug!); // → DL only
          } else {
            await _goCourseList();
          }
          return;
        }

        case 'courses': {
          // /courses/<id|slug>
          final sec = (cleanedRaw.length >= 2
              ? cleanedRaw[1]
              : (uri.queryParameters['id'] ?? uri.queryParameters['slug']))
              ?.trim();
          _d('route: courses, second=$sec');

          if (!_isNotBlank(sec)) {
            await _goCourseList();
            return;
          }

          final asInt = int.tryParse(sec!);
          if (asInt != null) {
            await _goCourseById(asInt); // → DL only
          } else {
            await _goCourse(sec); // → DL only (prefetch-by-slug)
          }
          return;
        }

        default:
          _d('route: default (no match) → ignore');
          return;
      }
    }

    _d('No route matched → return');
  }

  bool _isNotBlank(String? s) => s != null && s.trim().isNotEmpty;

  // -------- NAV HELPERS --------
  Future<void> _goCourseList() async {
    _d('_goCourseList() start');
    DeepLinkGate.markHandled();

    final args = <String, dynamic>{
      'category_id': null,
      'seacrh_query': null, // (same typo you use in LinkNavigator)
      'type': CoursesPageData.All,
    };

    await _safeNav((nav) {
      try {
        final ctx = nav.context;
        NavigationService()
            .navigationTo(ctx, CoursesScreen.routeName, arguments: args);
      } catch (_) {}
      return nav.push(
        MaterialPageRoute(
          settings:
          RouteSettings(name: CoursesScreen.routeName, arguments: args),
          builder: (_) => const CoursesScreen(),
        ),
      );
    });

    _d('_goCourseList() end');
  }

  Future<void> _goCourse(String slug) async {
    _d('_goCourse(slug=$slug)');
    DeepLinkGate.markHandled();

    // 1) Prefetch by slug (must exist to render DL instantly)
    final url = '$BASE_URL/api/course_details_by_slug?slug=$slug';
    Map<String, dynamic>? prefetch;
    int? id;

    try {
      final resp =
      await http.get(Uri.parse(url)).timeout(const Duration(seconds: 8));
      _d('GET $url → ${resp.statusCode}');
      if (resp.statusCode == 200) {
        final decoded = json.decode(resp.body);
        if (decoded is Map<String, dynamic>) {
          prefetch = decoded;
        } else if (decoded is List &&
            decoded.isNotEmpty &&
            decoded.first is Map) {
          prefetch = Map<String, dynamic>.from(decoded.first as Map);
        }
        id = (prefetch?['id'] as num?)?.toInt();
      }
    } catch (e, st) {
      _d('slug fetch error: $e\n$st');
    }

    if (prefetch == null || id == null) {
      _d('slug prefetch failed → no navigation (DL requires id+prefetch)');
      // If you want: fallback to list or toast
      // await _goCourseList();
      return;
    }

    // 2) Push DL screen with prefetch so it renders instantly
    // await _safeNav((nav) {
    //   return nav.push(
    //     MaterialPageRoute(
    //       settings: const RouteSettings(name: '/course-details-dl'),
    //       builder: (_) => CourseDetailScreenDL(
    //         courseId: id!,
    //         prefetch: prefetch!,
    //       ),
    //     ),
    //   );
    // }

    await _safeNav((nav) => nav.pushNamed(
      CourseLandingPage.routeName,
      arguments: id, // int resolved from slug prefetch
    )

    );
  }

  Future<void> _goEditProfile() async {
    _d('_goEditProfile()');
    DeepLinkGate.markHandled();

    await _safeNav((nav) async {
      try {
        final ctx = nav.context;
        NavigationService().navigationTo(ctx, EditProfileScreen.routeName);
      } catch (_) {}

      await Future.delayed(const Duration(milliseconds: 40));

      return nav.push(
        MaterialPageRoute(
          settings: const RouteSettings(name: EditProfileScreen.routeName),
          builder: (_) => const EditProfileScreen(),
        ),
      );
    });

    _d('_goEditProfile() end');
  }

  Future<void> _MyCourse() async {
    _d('_MyCourse()');
    DeepLinkGate.markHandled();

    await _safeNav((nav) {
      try {
        final ctx = nav.context;
        NavigationService().navigationTo(ctx, TabsScreen.routeName,
            arguments: {'index': 1});
      } catch (_) {}
      return nav.pushReplacement(
        MaterialPageRoute(
          settings: const RouteSettings(name: '/tabs_screen'),
          builder: (_) => TabsScreen(index: 1),
        ),
      );
    });
  }

  Future<void> _Myjob() async {
    _d('_Myjob()');
    DeepLinkGate.markHandled();

    await _safeNav((nav) {
      try {
        final ctx = nav.context;
        NavigationService().navigationTo(ctx, TabsScreen.routeName,
            arguments: {'index': 2});
      } catch (_) {}
      return nav.pushReplacement(
        MaterialPageRoute(
          settings: const RouteSettings(name: '/tabs_screen'),
          builder: (_) => TabsScreen(index: 2),
        ),
      );
    });
  }

  void _goAccount() async {
    _d('_goAccount()');
    DeepLinkGate.markHandled();

    await _safeNav((nav) {
      try {
        final ctx = nav.context;
        NavigationService().navigationTo(ctx, TabsScreen.routeName,
            arguments: {'index': 3});
      } catch (_) {}
      return nav.pushReplacement(
        MaterialPageRoute(
          settings: const RouteSettings(name: '/tabs_screen'),
          builder: (_) => TabsScreen(index: 3),
        ),
      );
    });
  }

  Future<void> _goCourseById(int courseId) async {
    _d('_goCourseById($courseId) start');
    DeepLinkGate.markHandled();

    // ---- 1) PUBLIC call first (no token) ----
    String urlPublic =
        '$BASE_URL/api/course_details_by_id?course_id=$courseId';
    String? authToken; // we’ll fetch only if needed
    Map<String, dynamic>? courseJson;

    Future<Map<String, dynamic>?> _fetch(String url) async {
      final resp =
      await http.get(Uri.parse(url)).timeout(const Duration(seconds: 8));
      _d('GET $url → status=${resp.statusCode} len=${resp.body.length}');
      if (resp.statusCode == 200) {
        final decoded = json.decode(resp.body);
        _d('decoded ok: type=${decoded.runtimeType}');
        if (decoded == null) return null;
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is List &&
            decoded.isNotEmpty &&
            decoded.first is Map<String, dynamic>) {
          return Map<String, dynamic>.from(decoded.first as Map);
        }
        return null;
      }
      // Return a small marker map with status so caller can decide
      return {'__status': resp.statusCode};
    }

    try {
      var first = await _fetch(urlPublic);

      // ---- 2) If unauthorized, try WITH token (lazy fetch & retry) ----
      if (first != null && first['__status'] is int) {
        final code = first['__status'] as int;
        if (code == 401 || code == 403) {
          try {
            authToken = await SharedPreferenceHelper().getAuthToken();
          } catch (_) {}
          if (authToken != null && authToken!.trim().isNotEmpty) {
            final urlAuth =
                '$BASE_URL/api/course_details_by_id?auth_token=$authToken&course_id=$courseId';
            first = await _fetch(urlAuth);
          }
        }
      }

      // Normalize result
      if (first != null && first['__status'] is int) {
        final code = first['__status'] as int;
        _d('error status=$code → goHome');
        _goHomeBypassGate();
        return;
      }

      courseJson = first;
    } catch (e, st) {
      _d('_goCourseById error: $e\n$st');
      _goHomeBypassGate();
      return;
    }

    // ---- 3) Prefetch sanity ----
    if (courseJson == null || courseJson!.isEmpty) {
      _d('prefetch empty → goHome');
      _goHomeBypassGate();
      return;
    }

    // ---- 4) Safe navigate + pass rich args (DL only) ----
    // await _safeNav((nav) {
    //   return nav.push(
    //     MaterialPageRoute(
    //       settings: RouteSettings(
    //         name: '/course-details-dl',
    //         arguments: {
    //           'id': courseId,
    //           'course_id': courseId,
    //           'prefetch': courseJson,
    //         },
    //       ),
    //       builder: (_) => CourseDetailScreenDL(
    //         courseId: courseId,
    //         prefetch: courseJson!, // non-null ensured above
    //       ),
    //     ),
    //   );
    // });
    await _safeNav((nav) => nav.pushNamed(
      CourseLandingPage.routeName,
      arguments: courseId, // just pass the int
    ));


    _d('_goCourseById($courseId) end');
  }

  // --- Force go home (DeepLinkGate bypass) ---
  void _goHomeBypassGate() {
    _d('_goHomeBypassGate()');
    _safeNav((nav) => nav.pushNamed('/home'));
  }

  // --- Navigator readiness helpers ---
  Future<void> _waitForNavigatorReady(
      {Duration timeout = const Duration(seconds: 3)}) async {
    final start = DateTime.now();
    while (_nav == null && DateTime.now().difference(start) < timeout) {
      await Future.delayed(const Duration(milliseconds: 16));
    }
    try {
      await WidgetsBinding.instance.endOfFrame;
    } catch (_) {
      await Future.delayed(const Duration(milliseconds: 16));
    }
  }

  Future<T?> _safeNav<T>(Future<T?> Function(NavigatorState nav) op) async {
    if (_fromInitial) {
      await _waitForNavigatorReady();
    }
    final nav = _nav;
    if (nav == null) return null;
    await Future<void>.delayed(Duration.zero);
    return op(nav);
  }
}










//
// import 'dart:async';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:app_links/app_links.dart';
// import 'dart:convert';
// import 'package:http/http.dart' as http;
//
// // Your app screens/routes
// import 'package:academy_app/screens/courses_screen.dart';
// import 'package:academy_app/screens/course_detail_screen.dart';
// import 'package:academy_app/screens/edit_profile_screen.dart';
// import '../Utils/deeplink_gate.dart';
//
// // ⚠️ Adjust the import below to your actual NavigationService path/name
// import 'package:academy_app/Utils/navigation_service.dart';
//
// import '../constants.dart';
// import '../main.dart';
// import '../providers/shared_pref_helper.dart';
// import '../screens/tabs_screen.dart';
//
// class DeepLinkService {
//   DeepLinkService(this._navKey);
//
//   final GlobalKey<NavigatorState> _navKey;
//
//   late final AppLinks _appLinks;
//   StreamSubscription<Uri?>? _sub;
//   Uri? _last;
//   bool _navToCoursesBusy = false; // duplicate course nav ko roke
//   DateTime? _lastHandledAt;
//   static const Duration _dupWindow = Duration(seconds: 3);
// // DeepLinkService fields:
//   bool _fromInitial = false;
//
//   void _d(String msg) {
//     if (kDebugMode) {
//       debugPrint('[DL] $msg');
//       rootScaffoldMessengerKey.currentState?.showSnackBar(
//         SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
//       );
//     }
//   }
//
//   Future<void> init() async {
//     _d('init()');
//     _appLinks = AppLinks();
//
//     // Live links while app is running/resumed
//     _sub = _appLinks.uriLinkStream.listen(
//           (uri) {
//         _d('STREAM got: $uri');
//         _handle(uri, source: 'STREAM');
//       },
//       onError: (e, st) => _d('STREAM error: $e\n$st'),
//       onDone: () => _d('STREAM done'),
//       cancelOnError: false,
//     );
//
//     // Cold start link (app killed state)
//     // init():
//     final initial = await _appLinks.getInitialLink();
//     _d('getInitialLink(): $initial');
//     if (initial != null) {
//       _fromInitial = true;                      // 👈 add
//       // navigator ready hone do
//       Future.microtask(() => _handle(initial, source: 'INITIAL'));
//     }
//   }
//
//   void dispose() {
//     _d('dispose() → cancel stream sub');
//     _sub?.cancel();
//   }
//
//   NavigatorState? get _nav => _navKey.currentState;
//
//   void _handle(Uri? uri, {required String source}) {
//     if (uri == null) {
//       _d('($source) null uri → return');
//       return;
//     }
//     _d('Handling ($source): $uri');
//
//     // ✅ 3s window me same URI ko ignore karo (INITIAL + STREAM duplicate)
//     final now = DateTime.now();
//     if (_last != null &&
//         _last.toString() == uri.toString() &&
//         _lastHandledAt != null &&
//         now.difference(_lastHandledAt!) < _dupWindow) {
//       _d('($source) duplicate within $_dupWindow → ignored');
//       return;
//     }
//     _last = uri;
//     _lastHandledAt = now;
//
//     // Lightweight busy gate
//     if (_navToCoursesBusy) {
//       _d('($source) busy gate active → skipping');
//       return;
//     }
//     _navToCoursesBusy = true;
//     Future.delayed(const Duration(seconds: 2), () {
//       _navToCoursesBusy = false;
//       _d('busy gate released');
//     });
//
//     final scheme = uri.scheme.toLowerCase(); // expect https
//     final host = uri.host.toLowerCase();
//     final rawSegs = uri.pathSegments; // keep case for ids/slugs
//     final segsLower = rawSegs.map((s) => s.toLowerCase()).toList();
//
//     _d('Parsed → scheme=$scheme host=$host segs=$rawSegs query=${uri.queryParameters}');
//
//     // -------------- HTTPS HANDLING (ONLY) --------------
//     // Allow both with/without www for safety
//     // -------------- HTTPS HANDLING (ONLY) --------------
//     // Allow both with/without www for safety
//
//     const allowedHosts = {'learn.greylearn.com', 'www.learn.greylearn.com'};
//     if (scheme == 'https' && allowedHosts.contains(host)) {
//       // ==== HARD PATCH: scrub templating tokens before anything ====
//       // 1) Raw path string (already decoded), but be extra-safe:
//       String path = Uri.decodeFull(uri.path);
//
//       // 2) Remove all %7B%7B...%7D%7D (encoded) tokens — case-insensitive
//       // final RegExp encToken = RegExp(r'%7B%7B.*?%7D%7D', caseSensitive: false);
//       // path = path.replaceAll(encToken, '');
//
//       // 3) Remove all {{...}} (decoded) tokens
//       final RegExp decToken = RegExp(r'\{\{.*?\}\}');
//       path = path.replaceAll(decToken, '');
//
//       // 4) Normalize repeated slashes and trim
//       path = path.replaceAll(RegExp(r'/{2,}'), '/').trim();
//
//       // 5) Rebuild segments from cleaned path
//       final List<String> cleanedRaw = path.split('/')
//           .where((s) => s.isNotEmpty)
//           .map((s) => s.trim())
//           .toList();
//       final List<String> low = cleanedRaw.map((s) => s.toLowerCase()).toList();
//
//       _d('CLEANED path="$path", segs=$cleanedRaw');
//
//       // ==== Strip known prefixes like /go/smart-open/... ====
//       bool _isPrefix(String s) =>
//           s == 'go' ||
//               s == 'smart-open' || s == 'smart_open' || s == 'smartopen' ||
//               s == 'open' || s == 'i';
//
//       while (low.isNotEmpty && (_isPrefix(low.first) || low.first.isEmpty)) {
//         cleanedRaw.removeAt(0);
//         low.removeAt(0);
//       }
//
//       if (low.isEmpty) {
//         _d('root (after strip) → home');
//         _goHome();
//         return;
//       }
//
//       final head = low.first; // effective route head
//       final headRaw = cleanedRaw.first;
//
//       // Remove any {{...}} placeholders from the head segment
//       final String headNoTpl = headRaw.replaceAll(RegExp(r'\{\{.*?\}\}'), '').trim();
//
//       // If head (after removing placeholders) is purely digits → treat as course ID
//       if (RegExp(r'^\d+$').hasMatch(headNoTpl)) {
//         final int id = int.parse(headNoTpl);
//         _d('numeric head detected → goCourseById($id)');
//         _goCourseById(id);
//         return;
//       }
//
//       _d('HTTPS head=$head (after strip), segs=$cleanedRaw');
//
//       switch (head) {
//         case 'my_course':
//           _d('route: my_course');
//           _MyCourse();
//           return;
//
//         case 'job':
//           _d('route: job');
//           _Myjob();
//           return;
//
//         case 'account':
//           _d('route: account');
//           _goAccount();
//           return;
//
//         case 'edit_profile':
//           _d('route: edit_profile');
//           _goEditProfile();
//           return;
//
//         // case 'course': {
//         //   // /course/<slug>
//         //   final slug = (cleanedRaw.length >= 2
//         //       ? cleanedRaw[1]
//         //       : (uri.queryParameters['slug'] ?? uri.queryParameters['id']))
//         //       ?.trim();
//         //   _d('route: course, slug=$slug');
//         //   if (_isNotBlank(slug)) {
//         //     _goCourse(slug!);
//         //   } else {
//         //     _goCourseList();
//         //   }
//         //   return;
//         // }
//         //
//         // case 'courses': {
//         //   // /courses/<id>
//         //   final idStr = (cleanedRaw.length >= 2 ? cleanedRaw[1] : uri.queryParameters['id'])?.trim();
//         //   _d('route: courses, idStr=$idStr');
//         //   final id = (idStr != null) ? int.tryParse(idStr) : null;
//         //   if (id == null) {
//         //     _d('invalid id → goHome');
//         //     _goHomeBypassGate();
//         //   } else {
//         //     _goCourseById(id);
//         //   }
//         //   return;
//         // }
//
//
//       // case 'courses': {
//         //   // /courses/<id>
//         //   final idStr = (cleanedRaw.length >= 2
//         //       ? cleanedRaw[1]
//         //       : uri.queryParameters['id'])
//         //       ?.trim();
//         //   _d('route: courses, idStr=$idStr');
//         //   if (_isNotBlank(idStr) && int.tryParse(idStr!) != null) {
//         //     _goCourseById(int.parse(idStr));
//         //   } else {
//         //     _goCourseList();
//         //   }
//         //   return;
//         // }
//
//         default:
//           _d('route: default (no match) → ignore');
//           return;
//       }
//     }
//
//
//     _d('No route matched → return');
//   }
//
//   bool _isNotBlank(String? s) => s != null && s.trim().isNotEmpty;
//
//   // -------- NAV HELPERS (unchanged) --------
//   void _goHome() {
//     _d('_goHome()');
//     if (DeepLinkGate.tookControl.value) {
//       _d('_goHome() blocked by DeepLinkGate');
//       return;
//     }
//     final ok = _nav?.pushNamed('/home');
//     _d('_goHome() pushNamed result: $ok');
//   }
//
//   Future<void> _goCourseList() async {
//     _d('_goCourseList() start');
//     DeepLinkGate.markHandled(); // FIRST LINE
//
//     final nav = _nav;
//     if (nav == null) {
//       _d('_goCourseList(): nav null');
//       return;
//     }
//
//     final ctx = nav.context;
//     final args = <String, dynamic>{
//       'category_id': null,
//       'seacrh_query': null, // (same typo you use in LinkNavigator)
//       'type': CoursesPageData.All,
//     };
//
//     try {
//       final cur = ModalRoute.of(ctx)?.settings.name ?? '(unknown)';
//       _d('_goCourseList() current route: $cur');
//     } catch (_) {}
//
//     // 1) Try NavigationService first
//     try {
//       if (ctx != null) {
//         _d('NavigationService().navigationTo → ${CoursesScreen.routeName}, args=$args');
//         NavigationService().navigationTo(
//           ctx,
//           CoursesScreen.routeName,
//           arguments: args,
//         );
//       }
//     } catch (e, st) {
//       _d('NavigationService navigation error: $e\n$st');
//     }
//
//     await Future.delayed(const Duration(milliseconds: 80));
//
//     // 2) Fallback: pushNamed
//     try {
//       _d('nav.pushNamed(${CoursesScreen.routeName})');
//       await nav.pushNamed(CoursesScreen.routeName, arguments: args);
//     } catch (e, st) {
//       _d('pushNamed error: $e\n$st');
//     }
//
//     await Future.delayed(const Duration(milliseconds: 120));
//
//     // 3) Last resort: force push
//     try {
//       _d('nav.push(MaterialPageRoute → ${CoursesScreen.routeName})');
//       await nav.push(
//         MaterialPageRoute(
//           settings: RouteSettings(name: CoursesScreen.routeName, arguments: args),
//           builder: (_) => const CoursesScreen(),
//         ),
//       );
//     } catch (e, st) {
//       _d('MaterialPageRoute push error: $e\n$st');
//     }
//
//     _d('_goCourseList() end');
//   }
//
//   void _goCourse(String slug) {
//     _d('_goCourse(slug=$slug)');
//     DeepLinkGate.markHandled(); // FIRST LINE
//
//     final ok = _nav?.pushNamed(
//       CourseDetailScreen.routeName,
//       arguments: {'slug': slug},
//     );
//     _d('_goCourse pushNamed result: $ok');
//   }
//
//   Future<void> _goEditProfile() async {
//     _d('_goEditProfile()');
//     DeepLinkGate.markHandled(); // FIRST LINE
//
//     final nav = _nav;
//     if (nav == null) {
//       _d('_goEditProfile(): nav null');
//       return;
//     }
//
//     final ctx = nav.context;
//
//     try {
//       final cur = ModalRoute.of(ctx)?.settings.name ?? '(unknown)';
//       _d('_goEditProfile() current route: $cur');
//     } catch (_) {}
//
//     // 1) Try NavigationService first
//     try {
//       if (ctx != null) {
//         _d('NavigationService().navigationTo → ${EditProfileScreen.routeName}');
//         NavigationService().navigationTo(ctx, EditProfileScreen.routeName);
//       }
//     } catch (e, st) {
//       _d('NavigationService navigation error: $e\n$st');
//     }
//
//     await Future.delayed(const Duration(milliseconds: 50));
//
//     // Did route change?
//     bool atEdit = false;
//     try {
//       final now = ModalRoute.of(ctx)?.settings.name;
//       atEdit = (now == EditProfileScreen.routeName);
//       _d('after NavigationService, atEdit=$atEdit');
//     } catch (_) {}
//
//     // 2) Fallback: pushNamed
//     if (!atEdit) {
//       try {
//         _d('nav.pushNamed(${EditProfileScreen.routeName})');
//         await nav.pushNamed(EditProfileScreen.routeName);
//       } catch (e, st) {
//         _d('pushNamed error: $e\n$st');
//       }
//     }
//
//     await Future.delayed(const Duration(milliseconds: 120));
//
//     // 3) Last resort
//     if (!atEdit) {
//       try {
//         _d('nav.push(MaterialPageRoute → ${EditProfileScreen.routeName})');
//         await nav.push(
//           MaterialPageRoute(
//             settings: const RouteSettings(name: EditProfileScreen.routeName),
//             builder: (_) => const EditProfileScreen(),
//           ),
//         );
//       } catch (e, st) {
//         _d('MaterialPageRoute push error: $e\n$st');
//       }
//     }
//
//     _d('_goEditProfile() end');
//   }
//
//   Future<void> _MyCourse() async {
//     _d('_MyCourse()');
//     DeepLinkGate.markHandled(); // FIRST LINE
//
//     final nav = _nav;
//     if (nav == null) {
//       _d('_MyCourse(): nav null');
//       return;
//     }
//
//     final ctx = nav.context;
//
//     try {
//       if (ctx != null) {
//         _d('NavigationService().navigationTo → ${TabsScreen.routeName} index=1');
//         NavigationService().navigationTo(
//           ctx,
//           TabsScreen.routeName,
//           arguments: {'index': 1},
//         );
//       }
//     } catch (e, st) {
//       _d('NavigationService navigation error: $e\n$st');
//     }
//
//     await Future.delayed(const Duration(milliseconds: 50));
//
//     try {
//       _d('nav.pushReplacement(TabsScreen index=1)');
//       nav.pushReplacement(
//         MaterialPageRoute(
//           settings: const RouteSettings(name: '/tabs_screen'),
//           builder: (_) => TabsScreen(index: 1),
//         ),
//       );
//     } catch (e, st) {
//       _d('pushReplacement error: $e\n$st');
//     }
//   }
//
//   Future<void> _Myjob() async {
//     _d('_Myjob()');
//     DeepLinkGate.markHandled(); // FIRST LINE
//
//     final nav = _nav;
//     if (nav == null) {
//       _d('_Myjob(): nav null');
//       return;
//     }
//
//     final ctx = nav.context;
//
//     try {
//       if (ctx != null) {
//         _d('NavigationService().navigationTo → ${TabsScreen.routeName} index=2');
//         NavigationService().navigationTo(
//           ctx,
//           TabsScreen.routeName,
//           arguments: {'index': 2},
//         );
//       }
//     } catch (e, st) {
//       _d('NavigationService navigation error: $e\n$st');
//     }
//
//     await Future.delayed(const Duration(milliseconds: 50));
//
//     try {
//       _d('nav.pushReplacement(TabsScreen index=2)');
//       nav.pushReplacement(
//         MaterialPageRoute(
//           settings: const RouteSettings(name: '/tabs_screen'),
//           builder: (_) => TabsScreen(index: 2),
//         ),
//       );
//     } catch (e, st) {
//       _d('pushReplacement error: $e\n$st');
//     }
//   }
//
//   void _goAccount() async {
//     _d('_goAccount()');
//     DeepLinkGate.markHandled(); // FIRST LINE
//
//     final nav = _nav;
//     if (nav == null) {
//       _d('_goAccount(): nav null');
//       return;
//     }
//
//     final ctx = nav.context;
//
//     try {
//       if (ctx != null) {
//         _d('NavigationService().navigationTo → ${TabsScreen.routeName} index=3');
//         NavigationService().navigationTo(
//           ctx,
//           TabsScreen.routeName,
//           arguments: {'index': 3},
//         );
//       }
//     } catch (e, st) {
//       _d('NavigationService navigation error: $e\n$st');
//     }
//
//     await Future.delayed(const Duration(milliseconds: 50));
//
//     try {
//       _d('nav.pushReplacement(TabsScreen index=3)');
//       nav.pushReplacement(
//         MaterialPageRoute(
//           settings: const RouteSettings(name: '/tabs_screen'),
//           builder: (_) => TabsScreen(index: 3),
//         ),
//       );
//     } catch (e, st) {
//       _d('pushReplacement error: $e\n$st');
//     }
//   }
//
//
//
//   Future<void> _goCourseById(int courseId) async {
//     _d('_goCourseById($courseId) start');
//     DeepLinkGate.markHandled(); // FIRST LINE
//
//     final nav = _nav;
//     if (nav == null) {
//       _d('_goCourseById(): nav null');
//       return;
//     }
//
//     final ctx = nav.context;
//
//     try {
//       // Verify if the course exists (via API)
//       var authToken = await SharedPreferenceHelper().getAuthToken();
//       var url = '$BASE_URL/api/course_details_by_id?course_id=$courseId';
//       if (authToken != null) {
//         url = '$BASE_URL/api/course_details_by_id?auth_token=$authToken&course_id=$courseId';
//       }
//
//       _d('GET $url');
//       final response = await http.get(Uri.parse(url));
//       _d('→ status=${response.statusCode} len=${response.body.length}');
//
//       // if (response.statusCode != 200) {
//       //   _d('non-200 → return');
//       //   return;
//       // }
//
//       if (response.statusCode != 200) {
//         _d('non-200 → goHome');
//         _goHomeBypassGate();
//         return;
//       }
//
//       final extractedData = json.decode(response.body);
//       _d('decoded ok: type=${extractedData.runtimeType}');
//       if (extractedData == null ||
//           (extractedData is List && extractedData.isEmpty)) {
//         _d('empty data → goHome');
//         _goHomeBypassGate();
//         return;
//       }
//
//       if (ctx != null) {
//         _d('NavigationService().navigationTo → CourseDetailScreen by ID');
//         NavigationService().navigationTo(
//           ctx,
//           CourseDetailScreen.routeName,
//           arguments: courseId,
//         );
//       } else {
//         _d('nav.push(MaterialPageRoute → CourseDetailScreen by ID)');
//         await nav.push(
//           MaterialPageRoute(
//             settings: RouteSettings(
//               name: CourseDetailScreen.routeName,
//               arguments: courseId,
//             ),
//             builder: (_) => const CourseDetailScreen(),
//           ),
//         );
//       }
//     } catch (e, st) {
//       _d('_goCourseById error: $e\n$st');
//       _goHomeBypassGate(); // error → go home
//     }
//
//     _d('_goCourseById($courseId) end');
//   }
//
// // --- Force go home (DeepLinkGate bypass) ---
//   void _goHomeBypassGate() {
//     _d('_goHomeBypassGate()');
//     final nav = _nav;
//     if (nav == null) return;
//     // Simple push (ya use pushNamedAndRemoveUntil if you want to clear stack)
//     nav.pushNamed('/home');
//     // OR: nav.pushNamedAndRemoveUntil('/home', (r) => false);
//   }
// }
//

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:academy_app/Utils/subscription_popup.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/api_client.dart';
import '../constants.dart';
import '../models/config_data.dart';
import '../providers/courses.dart';
import '../providers/my_courses.dart';
import '../providers/shared_pref_helper.dart';
import '../screens/course_detail_screen.dart';
import '../screens/coursedetailscreendeeiplink.dart';
import '../screens/courses_screen.dart';
import '../screens/edit_profile_screen.dart';
import '../screens/login_screen_new.dart';
import '../screens/my_course_detail_screen.dart';
import '../screens/my_courses_screen.dart';
import '../screens/newcoursedetail_landing_page.dart';
import '../screens/notification_screen.dart';
import '../screens/tabs_screen.dart';
import 'androidrating.dart';
import 'navigation_service.dart';

/// A singleton service to handle dynamic navigation for any named link field.
class LinkNavigator {
  // Private constructor
  LinkNavigator._();

  // Single instance
  static final LinkNavigator instance = LinkNavigator._();

  /// Navigates based on [keyName] and its corresponding link type.
  ///
  /// Example keys: 'banner1', 'hotsticker', etc.
  /// URL property: keyName (String)

  void navigate(
      BuildContext context,
      String link,
      String linkType,
      int inAppArgument,
      bool authenticate,
      String token,
      String routeName
      ) {
    if (linkType == 'inapp') {
      NavigationService().navigationTo(context,routeName, arguments: inAppArgument);
    } else if (linkType == 'external') {
      if(authenticate){
        if(token != null && token.isNotEmpty){
          final url = '$link/$token';
          debugPrint(url);
          NavigationService().navigationToWebView(context,url);
        }else{
          Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const LoginScreenNew()));
        }
      }else{
        NavigationService().navigationToWebView(context,link);
      }
    } else if(linkType == 'certificate') {
      final url = '$BASE_URL/api/download_certificate_mobile_web_view/$link/$token';
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      // NavigationService().navigationToWebView(context,url);
    }else{
      debugPrint('Unknown link type for "\$link": \$linkType');
    }
  }




  void navigateFromNotification(
      BuildContext context,
      String redirectType,
      String redirectSection,
      String redirectIdOrUrl,
      String authentication,
      String token,
      ) async {
    // normalize
    final type = redirectType.trim().toLowerCase();
    final section = redirectSection.trim().toLowerCase();
    final idOrUrl = redirectIdOrUrl.trim();
    final needAuth = authentication.trim().toLowerCase() == 'true' ||
        authentication.trim() == '1';

    debugPrint('🧭 [LN] type=$type section=$section id/url="$idOrUrl" needAuth=$needAuth tokenPresent=${token.isNotEmpty}');


    // auth guard (for both in-app & web when required)
    if (needAuth && (token.isEmpty)) {
      debugPrint('🧭 [LN] auth needed but no token -> LoginScreenNew');

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreenNew()),
      );
      return;
    }

// 🚩 Only go to NotificationScreen if BOTH section & URL are empty
    if (section.isEmpty && idOrUrl.isEmpty) {
      debugPrint('🧭 [LN] empty section & empty url -> NotificationScreen');
      Navigator.of(context).pushNamed(NotificationScreen.routeName);
      return;
    }

    // =========================
// ✅ If section is purely numeric → fetch full JSON & open DL screen
// =========================
    final numericCourseId = int.tryParse(redirectSection.trim());
    if (numericCourseId != null) {
      try {
        // ---- build API URL with/without auth_token ----
        final authToken = await SharedPreferenceHelper().getAuthToken();
        String url = '$BASE_URL/api/course_details_by_id?course_id=$numericCourseId';
        if (authToken != null && authToken.isNotEmpty) {
          url =
          '$BASE_URL/api/course_details_by_id?auth_token=$authToken&course_id=$numericCourseId';
        }

        // ---- call API & decode raw JSON list ----
        final resp = await ApiClient().get(url);
        final List<dynamic> raw = json.decode(resp.body) as List<dynamic>;

        // ❗ guard-1: empty response ⇒ Home
        if (raw.isEmpty || raw.first is! Map) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            TabsScreen.routeName,
                (route) => false,
            arguments: {'index': 0},
          );
          return;
        }

        final Map<String, dynamic> courseJson =
        Map<String, dynamic>.from(raw.first as Map);

        // ❗ guard-2: ID mismatch ⇒ Home
        final apiIdStr = (courseJson['id'] ?? courseJson['course_id'])?.toString();
        final apiId = int.tryParse(apiIdStr ?? '');
        if (apiId == null || apiId != numericCourseId) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            TabsScreen.routeName,
                (route) => false,
            arguments: {'index': 0},
          );
          return;
        }

        // (optional) warm-up provider — non-blocking
        unawaited(
          Provider.of<Courses>(context, listen: false)
              .fetchCourseDetailById(numericCourseId),
        );

        // ---- navigate with full JSON prefetch (DL screen) ----
        Navigator.of(context).pushNamed(
          CourseLandingPage.routeName,
          arguments: numericCourseId, // just the int id
        );

      } catch (e) {
        debugPrint('❌ [LN] prefetch course JSON failed: $e');

        // Fallback: API error पर भी Home
        Navigator.of(context).pushNamedAndRemoveUntil(
          TabsScreen.routeName,
              (route) => false,
          arguments: {'index': 0},
        );
      }
      return; // important
    }


// // =========================
//     final numericCourseId = int.tryParse(redirectSection.trim());
//     if (numericCourseId != null) {
//       try {
//         // ---- build API URL with/without auth_token ----
//         final authToken = await SharedPreferenceHelper().getAuthToken();
//         String url = '$BASE_URL/api/course_details_by_id?course_id=$numericCourseId';
//           url =
//           '$BASE_URL/api/course_details_by_id?auth_token=$authToken&course_id=$numericCourseId';
//
//
//         // ---- call API & decode raw JSON list ----
//         final resp = await ApiClient().get(url);
//         final List<dynamic> raw = json.decode(resp.body) as List<dynamic>;
//
//         // if API returns empty list, still open screen with empty prefetch
//         final Map<String, dynamic> courseJson =
//         (raw.isNotEmpty && raw.first is Map)
//             ? Map<String, dynamic>.from(raw.first as Map)
//             : <String, dynamic>{};
//
//         // (optional) warm-up provider too — non-blocking
//         unawaited(
//           Provider.of<Courses>(context, listen: false)
//               .fetchCourseDetailById(numericCourseId),
//         );
//
//         // ---- navigate with full JSON prefetch ----
//         Navigator.of(context).push(
//           MaterialPageRoute(
//             settings: RouteSettings(
//               name: '/course-details-dl',
//               arguments: {
//                 'id': numericCourseId,
//                 'course_id': numericCourseId,
//                 'prefetch': courseJson,
//               },
//             ),
//             builder: (_) => CourseDetailScreenDL(
//               courseId: numericCourseId,
//               prefetch: courseJson, // full JSON prefetch
//             ),
//           ),
//         );
//       } catch (e) {
//         debugPrint('❌ [LN] prefetch course JSON failed: $e');
//
//         // Fallback: still open DL screen (it will self-refresh via provider)
//         Navigator.of(context).push(
//           MaterialPageRoute(
//             settings: RouteSettings(
//               name: '/course-details-dl',
//               arguments: {
//                 'id': numericCourseId,
//                 'course_id': numericCourseId,
//                 'prefetch': const <String, dynamic>{},
//               },
//             ),
//             builder: (_) => CourseDetailScreenDL(
//               courseId: numericCourseId,
//               prefetch: const <String, dynamic>{},
//             ),
//           ),
//         );
//       }
//       return; // important
//     }





    if (type == 'in-app') {
      // ✅ handle known sections
      if (section == 'course') {
        debugPrint('🧭 [LN] OPEN -> CoursesScreen');

        NavigationService().navigationTo(
          context,
          CoursesScreen.routeName,
          arguments: {
            'category_id': null,
            'seacrh_query': null,
            'type': CoursesPageData.All,
          },
        );
        return;
      }

      if (section == 'edit_profile') {
        debugPrint('🧭 [LN] OPEN -> EditProfileScreen (arg="$idOrUrl")');

        NavigationService().navigationTo(context, EditProfileScreen.routeName,
            arguments: idOrUrl);
        return;
      }

      if (section == 'my_course') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => TabsScreen(index: 1)),
        );
        return;
      }

      if (section == 'job') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => TabsScreen(index: 2)),
        );
        return;
      }

      if (section == 'subscriptionbundlepopup') {
        if (Platform.isIOS) {
          debugPrint('🍎 iOS detected → subscription popup disabled');
          return;
        }

        try {
          final rawConfig = await SharedPreferenceHelper().getConfigData();
          if (rawConfig == null || rawConfig.isEmpty) {
            debugPrint('[LinkNavigator] No cached config found for subscription popup');
            return;
          }

          final parsed = jsonDecode(rawConfig);
          final configData = ConfigData.fromJson(parsed);
          final subscription = configData.subscription;

          if (subscription == null) {
            debugPrint('[LinkNavigator] Subscription config missing; cannot show popup');
            return;
          }

          SubscriptionDialog.show(context, subscription);
        } catch (e) {
          debugPrint('[LinkNavigator] Failed to open subscription popup: $e');
        }
        return;
      }


      if (section == 'account') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => TabsScreen(index: 3)),
        );
        return;
      }


      if (section == 'androidratingpopup') {
        debugPrint('🧭 [LN] OPEN -> Android App Rating Popup');
        AndroidRatingPopup.show(context);   // Dialog open karega
        return;
      }



      // Fallback:
      debugPrint('[LinkNavigator] Unknown in-app section: $section');
      Navigator.of(context).pushNamedAndRemoveUntil(
        TabsScreen.routeName,
            (route) => false,
        arguments: {'index': 0},
      );
      return;
    }

    if (type == 'web') {
      String url = idOrUrl;

      // 1) relative path? -> BASE_URL prepend
      if (url.startsWith('/')) {
        url = '$BASE_URL$url';
      }

      // 2) scheme-less? -> https:// prepend
      final uriTry = Uri.tryParse(url);
      if (uriTry == null || !(uriTry.hasScheme)) {
        url = 'https://$url';
      }

      // 3) auth token ko query param me bhejo (zyada common pattern)
      if (needAuth) {
        final hasQuery = url.contains('?');
        final joiner = hasQuery ? '&' : '?';
        url = '$url${joiner}auth_token=$token';
      }

      debugPrint('🌐 [LN] WEB open -> $url');

      // 4) final safety: valid URL?
      final ok = Uri.tryParse(url);
      if (ok == null || !(ok.hasScheme)) {
        debugPrint('🛑 [LN] Invalid final URL -> $url');
        // graceful fallback: Notification screen
        Navigator.of(context).pushNamed(NotificationScreen.routeName);
        return;
      }

      NavigationService().navigationToWebView(context, url);
      return;
    }


    // if (type == 'web') {
    //   final url = needAuth ? '$idOrUrl/$token' : idOrUrl;
    //   NavigationService().navigationToWebView(context, url);
    //   return;
    // }

    // optional: certificate type via notification
    if (type == 'certificate') {
      final url = '$BASE_URL/api/download_certificate_mobile_web_view/$idOrUrl/$token';
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      return;
    }

    debugPrint('[LinkNavigator] Unknown redirectType: $redirectType');
    Navigator.of(context).pushNamedAndRemoveUntil(
      TabsScreen.routeName,
          (route) => false,
      arguments: {'index': 0},
    );
  }

// void navigateFromNotification(
//     BuildContext context,
//     String redirectType,
//     String redirectSection,
//     String redirectIdOrUrl,
//     String authentication,
//     String token,
//     ) {
//   if (redirectType == 'in-app') {
//     if(redirectSection == 'course'){
//       NavigationService().navigationTo(context,CoursesScreen.routeName,
//           arguments: {
//         'category_id': null,
//         'seacrh_query': null,
//         'type': CoursesPageData.All,
//       });
//     }else if(redirectSection == 'edit_profile'){
//       NavigationService().navigationTo(context,EditProfileScreen.routeName, arguments: redirectIdOrUrl);
//     }else if(redirectSection == 'my_course'){
//       Navigator.of(context).pushReplacement(
//           MaterialPageRoute(builder: (context) => TabsScreen(index: 1,)));
//     }else if(redirectSection == 'job'){
//       Navigator.of(context).pushReplacement(
//           MaterialPageRoute(builder: (context) => TabsScreen(index: 2,)));
//     }else if(redirectSection == 'account'){
//       Navigator.of(context).pushReplacement(
//           MaterialPageRoute(builder: (context) => TabsScreen(index: 3,)));
//     }else {
//       // NavigationService().navigationTo(context,routeName, arguments: redirectIdOrUrl);
//     }
//   } else if (redirectType == 'web') {
//     if(authentication.contains('true')){
//       if(token != null && token.isNotEmpty){
//         final url = '$redirectIdOrUrl/$token';
//         debugPrint(url);
//         NavigationService().navigationToWebView(context,url);
//       }else{
//         Navigator.of(context).pushReplacement(
//             MaterialPageRoute(builder: (context) => const LoginScreenNew()));
//       }
//     }else{
//       NavigationService().navigationToWebView(context,redirectIdOrUrl);
//     }
//   }else{
//     debugPrint('Unknown link type for "\$link": \$linkType');
//   }
// }
}

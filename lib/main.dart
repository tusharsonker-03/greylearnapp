import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:academy_app/providers/course_detail_landing_provider.dart';
import 'package:academy_app/providers/shared_pref_helper.dart';
import 'package:academy_app/screens/forcelogout_page.dart';
import 'package:academy_app/screens/login_screen.dart';
import 'package:academy_app/screens/newcoursedetail_landing_page.dart';
import 'package:academy_app/screens/webview_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:academy_app/api/api_client.dart';
import 'package:academy_app/models/config_data.dart';
import 'package:academy_app/providers/bundles.dart';
import 'package:academy_app/providers/config.dart';
import 'package:academy_app/providers/countries.dart';
import 'package:academy_app/providers/course_forum.dart';
import 'package:academy_app/providers/notification_counter.dart';
import 'package:academy_app/providers/user_profile.dart';
import 'package:academy_app/screens/account_remove_screen.dart';
import 'package:academy_app/screens/auth_screen_private.dart';
import 'package:academy_app/screens/downloaded_course_list.dart';
import 'package:academy_app/screens/edit_password_screen.dart';
import 'package:academy_app/screens/edit_profile_screen.dart';
import 'package:academy_app/screens/full_screen_popup.dart';
import 'package:academy_app/screens/notification_screen.dart';
import 'package:academy_app/screens/sub_category_screen.dart';
import 'package:academy_app/screens/verification_screen.dart';
import 'package:clarity_flutter/clarity_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logging/logging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'Utils/base_url_global_helper.dart';
import 'Utils/deeplink_service.dart';
import 'Utils/link_navigator.dart';
import 'Utils/notification_service.dart';
import 'providers/auth.dart';
import 'providers/courses.dart';
import 'providers/http_overrides.dart';
import 'providers/misc_provider.dart';
import 'providers/my_bundles.dart';
import 'providers/my_courses.dart';
import 'screens/bundle_details_screen.dart';
import 'screens/bundle_list_screen.dart';
import 'screens/courses_screen.dart';
import 'screens/device_verifcation.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/my_bundle_courses_list_screen.dart';
import 'screens/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'constants.dart';
import 'providers/categories.dart';
import 'screens/auth_screen.dart';
import 'screens/course_detail_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/tabs_screen.dart';

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
GlobalKey<ScaffoldMessengerState>();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final DeepLinkService deepLinks = DeepLinkService(navigatorKey);
/// A notification action which triggers a App navigation event
const String navigationActionId = 'id_3';
const String darwinNotificationCategoryPlain = 'plainCategory';
const String darwinNotificationCategoryText = 'textCategory';
final List<DarwinNotificationCategory> darwinNotificationCategories =
<DarwinNotificationCategory>[
  DarwinNotificationCategory(
    darwinNotificationCategoryText,
    actions: <DarwinNotificationAction>[
      DarwinNotificationAction.text(
        'text_1',
        'Action 1',
        buttonTitle: 'Send',
        placeholder: 'Placeholder',
      ),
    ],
  ),
  DarwinNotificationCategory(
    darwinNotificationCategoryPlain,
    actions: <DarwinNotificationAction>[
      DarwinNotificationAction.plain('id_1', 'Action 1'),
      DarwinNotificationAction.plain(
        'id_2',
        'Action 2 (destructive)',
        options: <DarwinNotificationActionOption>{
          DarwinNotificationActionOption.destructive,
        },
      ),
      DarwinNotificationAction.plain(
        navigationActionId,
        'Action 3 (foreground)',
        options: <DarwinNotificationActionOption>{
          DarwinNotificationActionOption.foreground,
        },
      ),
      DarwinNotificationAction.plain(
        'id_4',
        'Action 4 (auth required)',
        options: <DarwinNotificationActionOption>{
          DarwinNotificationActionOption.authenticationRequired,
        },
      ),
    ],
    options: <DarwinNotificationCategoryOption>{
      DarwinNotificationCategoryOption.hiddenPreviewShowTitle,
    },
  )
];


// Firebase + Local Notifications glue
final FlutterLocalNotificationsPlugin _flnp = FlutterLocalNotificationsPlugin();

Future<void> initNotifications() async {
  final DarwinInitializationSettings initializationSettingsDarwin =
  DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
    notificationCategories: darwinNotificationCategories,
  );

  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  final initSettings = InitializationSettings(android: androidInit,iOS: initializationSettingsDarwin);

  await _flnp.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (NotificationResponse resp) async {
      debugPrint('👆 [LOCAL TAP] actionId=${resp.actionId} payload=${resp.payload}');

      // payload me hum JSON store karenge (message.data)
      final payload = resp.payload;
      if (payload == null || payload.isEmpty) return;
      try {
        final data = jsonDecode(payload) as Map<String, dynamic>;
        routeFromNotificationData(navigatorKey.currentContext, data);
      } catch (e) {
        debugPrint('notif payload parse error: $e');
      }
    },
  );

  // Android channel ensure
  await _flnp
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(_notifChannel);
}


const AndroidNotificationChannel _notifChannel = AndroidNotificationChannel(
  'default_high_importance',
  'General Notifications',
  description: 'Default channel for app notifications',
  importance: Importance.high,
);


Future<void> routeFromNotificationData(BuildContext? ctx, Map<String, dynamic> data) async {
  if (ctx == null) {
    debugPrint('⚠️ [ROUTE] context=null, will retry in 300ms');
    Future.delayed(const Duration(milliseconds: 300), () {
      routeFromNotificationData(navigatorKey.currentContext, data);
    });
    return;
  }

  debugPrint('➡️ [ROUTE] raw data: $data');

  // normalize
  final redirectType    = (data['redirect_type'] ?? '').toString().trim().toLowerCase();
  final redirectSection = (data['redirect_section'] ?? '').toString().trim(); // keep original case for LinkNavigator
  final redirectIdOrUrl = (data['redirect_id_or_url'] ?? '').toString().trim();
  final authentication  = (data['authentication'] ?? '').toString().trim();

  debugPrint('🔎 [ROUTE] type="$redirectType" section="$redirectSection" id/url="$redirectIdOrUrl" auth="$authentication"');

  // auth
  final token = await SharedPreferenceHelper().getAuthToken() ?? '';
  final needAuth = authentication.toLowerCase() == 'true' || authentication == '1';
  debugPrint('🔐 [ROUTE] needAuth=$needAuth tokenPresent=${token.isNotEmpty}');

  if (needAuth && token.isEmpty) {
    debugPrint('🚫 [ROUTE] auth needed but no token -> LoginScreen');
    Navigator.of(ctx).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
    return;
  }

  // ✅ NEW: sirf jab section bhi empty ho AUR url/id bhi empty ho, tab NotificationScreen
  final isSectionEmpty = redirectSection.isEmpty;
  final isIdOrUrlEmpty = redirectIdOrUrl.isEmpty;

  if (isSectionEmpty && isIdOrUrlEmpty) {
    debugPrint('⚠️ [ROUTE] both section & id/url empty -> NotificationScreen');
    Navigator.of(ctx).pushNamed(NotificationScreen.routeName);
    return;
  }

  debugPrint('🚀 [ROUTE] forwarding to LinkNavigator…');

  // proceed (web case me section empty ho sakta hai but id/url present)
  LinkNavigator.instance.navigateFromNotification(
    ctx,
    redirectType,
    redirectSection,
    redirectIdOrUrl,
    authentication,
    token,
  );
}


// Future<void> routeFromNotificationData(BuildContext? ctx, Map<String, dynamic> data) async {
//   if (ctx == null) {
//     debugPrint('⚠️ [ROUTE] context=null, will retry in 300ms');
//     Future.delayed(const Duration(milliseconds: 300), () {
//       routeFromNotificationData(navigatorKey.currentContext, data);
//     });
//     return;
//   }
//   debugPrint('➡️ [ROUTE] raw data: $data');
//   // FCM data may come as String values; normalize
//   String redirectType      = (data['redirect_type'] ?? '').toString();
//   String redirectSection   = (data['redirect_section'] ?? '').toString();
//   String redirectIdOrUrl   = (data['redirect_id_or_url'] ?? '').toString();
//   String authentication    = (data['authentication'] ?? '').toString();
//
//   debugPrint('🔎 [ROUTE] type="$redirectType" section="$redirectSection" id/url="$redirectIdOrUrl" auth="$authentication"');
//
//
//   // auth token (if needed)
//   final token = await SharedPreferenceHelper().getAuthToken() ?? '';
//
//   // in-app + auth required but no token => login
//   final needAuth = authentication.trim().toLowerCase() == 'true' || authentication.trim() == '1';
//   debugPrint('🔐 [ROUTE] needAuth=$needAuth tokenPresent=${token.isNotEmpty}');
//
//   if (needAuth && token.isEmpty) {
//     debugPrint('🚫 [ROUTE] auth needed but no token -> LoginScreen');
//
//     Navigator.of(ctx).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
//     return;
//   }
//
//
//   // ✅ NEW: sirf jab section bhi empty ho AUR url/id bhi empty ho, tab NotificationScreen
//   final isSectionEmpty = redirectSection.isEmpty;
//   final isIdOrUrlEmpty = redirectIdOrUrl.isEmpty;
//
//   if (isSectionEmpty && isIdOrUrlEmpty) {
//     debugPrint('⚠️ [ROUTE] both section & id/url empty -> NotificationScreen');
//     Navigator.of(ctx).pushNamed(NotificationScreen.routeName);
//     return;
//   }
//
//   debugPrint('🚀 [ROUTE] forwarding to LinkNavigator…');
//
//   // delegate to LinkNavigator (central place)
//   LinkNavigator.instance.navigateFromNotification(
//     ctx,
//     redirectType,
//     redirectSection,
//     redirectIdOrUrl,
//     authentication,
//     token,
//   );
// }


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await initNotifications(); // 👈 initialize notifications


  // ✅ Android storage permission check
  if (Platform.isAndroid) {
    await _requestStoragePermission();
  }



  await NotificationService().init();// custom service we'll define below
  final config = ClarityConfig(
    projectId: "sdx2knmynv", // actual project ID from the Clarity dashboard
    logLevel: LogLevel.Verbose, // Use LogLevel.Verbose for development, switch to LogLevel.None in production
  );
  Logger.root.onRecord.listen((LogRecord rec) {
    debugPrint(
        '${rec.loggerName}>${rec.level.name}: ${rec.time}: ${rec.message}');
  });
  HttpOverrides.global = PostHttpOverrides();
  runApp(
    ClarityWidget(
      app: MyApp(),
      clarityConfig: config,
    ),
  );
}

/// Function to request storage permission
Future<void> _requestStoragePermission() async {
  var status = await Permission.storage.status;

  if (!status.isGranted) {
    status = await Permission.storage.request();
  }

  // Android 11+ ke liye
  if (await Permission.manageExternalStorage.isDenied) {
    await Permission.manageExternalStorage.request();
  }
}

class MyApp extends StatefulWidget {
  // Alice alice = Alice();
  MyApp({super.key});
  // This widget is the root of your application.
  @override
  State<MyApp> createState() => _MyAppState();
}


class _MyAppState extends State<MyApp> {
  Timer? _sessionTimer;


  @override
  void initState() {
    super.initState();
    // 🔑 Deep links ko app boot ke turant baad start karo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      deepLinks.init(); // <-- yahin par; kahin aur mat call karo
    });

    // ✅ Foreground message
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint('🔔 [FG] title=${message.notification?.title} body=${message.notification?.body}');
      debugPrint('🧾 [FG] data=${message.data}');
      // ⚡ Bas log kar, show mat kar — NotificationService already handle karega
    });

    // FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    //   debugPrint('🔔 [FG] title=${message.notification?.title} body=${message.notification?.body}');
    //   debugPrint('🧾 [FG] data=${message.data}');
    //
    //   // local notification दिखाते समय पूरा data payload पास करें
    //   final payload = jsonEncode(message.data);
    //   await _flnp.show(
    //     DateTime.now().millisecondsSinceEpoch ~/ 1000,
    //     message.notification?.title ?? 'Notification',
    //     message.notification?.body  ?? '',
    //     NotificationDetails(
    //       android: AndroidNotificationDetails(
    //         _notifChannel.id, _notifChannel.name,
    //         channelDescription: _notifChannel.description,
    //         importance: Importance.high, priority: Priority.high,
    //       ),
    //     ),
    //     payload: payload,
    //   );
    // });


    // ✅ Background click se handle karo
    // FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    //   print("Background Notification Clicked: ${message.notification?.title}");
    //   _handleMessageClick(message);
    // });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      debugPrint('👆 [BG TAP] title=${message.notification?.title}');
      debugPrint('🧾 [BG TAP] data=${message.data}');
      // make sure a context exists
      WidgetsBinding.instance.addPostFrameCallback((_) {
        routeFromNotificationData(navigatorKey.currentContext, message.data);

      });
    });

    // ✅ Terminated state ke liye
    checkForInitialMessage();
  }

  Future<void> checkForInitialMessage() async {
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      debugPrint('👆 [TERMINATED TAP] title=${initialMessage.notification?.title}');
      debugPrint('🧾 [TERMINATED TAP] data=${initialMessage.data}');

      // Wait until first frame of the app is built
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        // Add a small delay to ensure MaterialApp + routes are ready
        await Future.delayed(const Duration(milliseconds: 600));

        final ctx = navigatorKey.currentContext;
        if (ctx != null) {
          routeFromNotificationData(ctx, initialMessage.data);
        } else {
          debugPrint('❌ [ROUTE] context still null after delay');
        }
      });
    }

  }

  /// ✅ Common function to handle message clicks
  void _handleMessageClick(RemoteMessage message) {
    final route = message.data['route']; // FCM ke data payload me 'route' key bhejna

    if (route != null) {
      if (route == CoursesScreen.routeName) {
        // Agar /courses bheja gaya hai
        navigatorKey.currentState?.pushNamed(
          CoursesScreen.routeName,
          arguments: {
            'type': CoursesPageData.All, // ✅ required argument
          },
        );
      } else if (route == NotificationScreen.routeName) {
        navigatorKey.currentState?.pushNamed(NotificationScreen.routeName);
      } else {
        // Default case - unknown route
        navigatorKey.currentState?.pushNamed(NotificationScreen.routeName);
      }
    } else {
      // Agar route nahi bheja gaya ho
      navigatorKey.currentState?.pushNamed(NotificationScreen.routeName);
    }
  }


  // @override
  // void initState() {
  //   super.initState();
  //
  //   // Foreground notification listener
  //   FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  //     print("Foreground Notification: ${message.notification?.title}");
  //
  //
  //     // Direct Notification Screen par bhejna
  //     // navigatorKey.currentState?.pushNamed(NotificationScreen.routeName);
  //   });
  //
  //   // Jab notification background me click ho
  //   FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
  //     print("Background Notification Clicked: ${message.notification?.title}");
  //
  //     navigatorKey.currentState?.pushNamed(NotificationScreen.routeName);
  //   });
  //
  //   // App terminated state se notification click
  //   checkForInitialMessage();
  // }

  // /// Yeh function terminated state ke liye hai
  // Future<void> checkForInitialMessage() async {
  //   RemoteMessage? initialMessage =
  //   await FirebaseMessaging.instance.getInitialMessage();
  //
  //   if (initialMessage != null) {
  //     print("Terminated Notification: ${initialMessage.notification?.title}");
  //
  //     navigatorKey.currentState?.pushNamed(NotificationScreen.routeName);
  //   }
  // }
  //



  @override
  void dispose() {
    _sessionTimer?.cancel();
    deepLinks.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //alice =Alice(navigatorKey: alice.getNavigatorKey());
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (ctx) => NotificationCounter(),
        ),
        ChangeNotifierProvider(
          create: (ctx) => Auth(),
        ),
        ChangeNotifierProvider(
          create: (ctx) => Countries(),
        ),
        ChangeNotifierProvider(
          create: (ctx) => Categories(),
        ),
        ChangeNotifierProxyProvider<Auth, Courses>(
          create: (ctx) => Courses([], [], []),
          update: (ctx, auth, prevoiusCourses) => Courses(
            prevoiusCourses == null ? [] : prevoiusCourses.items,
            prevoiusCourses == null ? [] : prevoiusCourses.cCourseItems,
            prevoiusCourses == null ? [] : prevoiusCourses.jCourseItems,
          ),
        ),
        ChangeNotifierProxyProvider<Auth, MyCourses>(
          create: (ctx) => MyCourses([], []),
          update: (ctx, auth, previousMyCourses) => MyCourses(
            previousMyCourses == null ? [] : previousMyCourses.items,
            previousMyCourses == null ? [] : previousMyCourses.sectionItems,
          ),
        ),
        ChangeNotifierProvider(
          create: (ctx) => Languages(),
        ),
        ChangeNotifierProvider(
          create: (ctx) => Bundles(),
        ),
        ChangeNotifierProvider(
          create: (ctx) => MyBundles(),
        ),
        ChangeNotifierProvider(
          create: (ctx) => CourseForum(),
        ),
        ChangeNotifierProvider(
          create: (ctx) => Config(),
        ),
        ChangeNotifierProvider(
          create: (ctx) => UserProfile(),
        ),
      ],
      child: Consumer<Auth>(
        builder: (ctx, auth, _) => MaterialApp(
          // scaffoldMessengerKey: rootScaffoldMessengerKey,
          navigatorKey: navigatorKey,
          title: 'GreyLearn App',
          theme: ThemeData(
            fontFamily: 'google_sans',
            colorScheme: const ColorScheme.light(primary: kBackgroundColor),
            textSelectionTheme: const TextSelectionThemeData(
              cursorColor: Colors.black54, // Change the cursor color. Change red to blue or as per your requirement
              selectionHandleColor: Colors.black54, // Change the selection handle color
              selectionColor: Colors.black54, // Change the text selection color
            ),
            // colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.deepPurple)
            //     .copyWith(secondary: kDarkButtonBg),
          ),
          debugShowCheckedModeBanner: false,
          home: const SplashScreen(),
          routes: {
            '/home': (ctx) =>  TabsScreen(index: 0,),
            AuthScreen.routeName: (ctx) => const AuthScreen(),
            AuthScreenPrivate.routeName: (ctx) => const AuthScreenPrivate(),
            SignUpScreen.routeName: (ctx) => const SignUpScreen(),
            ForgotPassword.routeName: (ctx) => const ForgotPassword(),
            CoursesScreen.routeName: (ctx) => const CoursesScreen(),
            // CourseDetailScreen.routeName: (ctx) => const CourseDetailScreen(),
            CourseLandingPage.routeName: (ctx) => const _CourseLandingBridge(), // 👈 same style
            EditPasswordScreen.routeName: (ctx) => const EditPasswordScreen(),
            EditProfileScreen.routeName: (ctx) => const EditProfileScreen(),
            VerificationScreen.routeName: (ctx) => const VerificationScreen(),
            // FullScreenPopup.routeName: (context) =>
            //     FullScreenPopup(ModalRoute.of(context)?.settings.arguments as Subscription),
            AccountRemoveScreen.routeName: (ctx) => const AccountRemoveScreen(),
            DownloadedCourseList.routeName: (ctx) =>
            const DownloadedCourseList(),
            SubCategoryScreen.routeName: (ctx) => const SubCategoryScreen(),
            BundleListScreen.routeName: (ctx) => const BundleListScreen(),
            BundleDetailsScreen.routeName: (ctx) => const BundleDetailsScreen(),
            MyBundleCoursesListScreen.routeName: (ctx) =>
            const MyBundleCoursesListScreen(),
            DeviceVerificationScreen.routeName: (context) => const DeviceVerificationScreen(),
            NotificationScreen.routeName: (ctx) => const NotificationScreen(),
            '/forceLogout': (ctx) =>  AuthScreen(),

          },
        ),
      ),
    );

  }

}

class _CourseLandingBridge extends StatelessWidget {
  const _CourseLandingBridge({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final int courseId = (args is int) ? args : int.tryParse('$args') ?? 0;

    if (courseId <= 0) {
      return const Scaffold(
        body: Center(child: Text('Invalid course id for CourseLandingPage')),
      );
    }

    return ChangeNotifierProvider(
      create: (_) => LandingVM()..loadCourseById(courseId),
      child: CourseLandingPage(courseId: courseId),
    );
  }
}

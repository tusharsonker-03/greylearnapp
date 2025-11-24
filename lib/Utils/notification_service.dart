import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../providers/notification_counter.dart';
import '../providers/shared_pref_helper.dart';
import 'navigation_service.dart'; // Optional, for navigating on tap

@pragma('vm:entry-point') // VERY IMPORTANT for background execution
void notificationTapBackgroundHandler(NotificationResponse response) {
  final payload = response.payload;
  debugPrint("payload-->");
  debugPrint(payload);
  // You can handle the background tap here or log it
  // Optionally: use Isolate or save to SharedPreferences
  NotificationService().handleMessageTap(payload);
}

@pragma('vm:entry-point') // VERY IMPORTANT for background execution
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();
  String plainTextBody="";
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  Future<void> init() async {
    await _firebaseMessaging.requestPermission();

    // Get FCM token
    String? token;
    try{
      token = await _firebaseMessaging.getToken();
    }catch(e){
      token = "";
    }
    print('FCM Token: $token');
    await SharedPreferenceHelper().setFCMToken(token ?? "");
    // Initialize local notifications
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@drawable/ic_launcher_notification');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    final InitializationSettings initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload;
        print('Handling onDidReceiveNotificationResponse: ${response.toString()} , $payload');
        handleMessageTap(payload);
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackgroundHandler,
    );


    // Listen to foreground messages
    FirebaseMessaging.onMessage.listen(_showLocalNotification);

    // When app is opened from background (tap on notification)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Handling onMessageOpenedApp: ${message.data.toString()}');
      handleMessageTap(message.data['payload']);

    });

    // Handle background messages (Android only)
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }




  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    await Firebase.initializeApp();
    print('Handling a background message: ${message.data.toString()}');
  }

  void _showLocalNotification(RemoteMessage message) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      Provider.of<NotificationCounter>(context, listen: false).increment();// this updates your UI
    }else{
      print('context not found');
    }
    print("_showLocalNotification");
    print(message.toMap().toString());
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;
    var htmlBody = "<b>Bold text</b><br>New line<br><a href='...'>Link</a>";
     plainTextBody = htmlBody
        .replaceAll(RegExp(r'<[^>]*>'), '\n') // crude HTML to plain text
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&');

    if (notification != null && android != null) {
      _flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'default_channel',
            'Default',
            importance: Importance.max,
            priority: Priority.high,
            styleInformation: BigTextStyleInformation('',htmlFormatContent: true),
          ),
        ),
        payload: message.data['payload'], // Can be JSON string or ID
      );
    }
  }

  void handleMessageTap(String? payload) {
    debugPrint(payload);
    if (payload != null) {
      // Example payload: courseId, route, or deep link
      NavigationService().navigateTo('/courseDetail', arguments: {'id': payload});
    }
  }
}

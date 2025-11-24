import 'package:flutter/material.dart';

import '../screens/webview_screen.dart';

class NavigationService {
  // Singleton setup
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  Future<dynamic>? navigateTo(String routeName, {Object? arguments}) {
    return navigatorKey.currentState?.pushNamed(routeName, arguments: arguments);
  }

  Future<dynamic>? navigateToWebView(String gotoUrl) {
    return  navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => WebViewScreen(url: gotoUrl),
      ),
    );
  }

  Future<dynamic>? navigationTo(BuildContext context,String routeName,{Object? arguments}) {
    return Navigator.pushNamed(context,routeName, arguments: arguments);
  }

  Future<dynamic>? navigationToWebView(BuildContext context,String gotoUrl) {
    debugPrint(gotoUrl);
    return  Navigator.push(context,
      MaterialPageRoute(
        builder: (context) => WebViewScreen(url: gotoUrl),
      ),
    );
  }

  void goBack() {
    navigatorKey.currentState?.pop();
  }

  bool canPop() {
    return navigatorKey.currentState?.canPop() ?? false;
  }

  void popUntilFirst() {
    navigatorKey.currentState?.popUntil((route) => route.isFirst);
  }
}

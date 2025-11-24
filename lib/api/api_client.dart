import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';

class ApiClient {
  Future<http.Response> get(String requestUrl) async {
    debugPrint('Request url--> ${requestUrl.toString()}');
    var url = requestUrl;
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
          'Expires': '0',
        },
      );
      debugPrint('Response --> ${jsonDecode(response.body)}');
      // 🔴 Agar backend bole unauthorized (dusre device se login)
      if (response.statusCode == 401) {
        _handleUnauthorized();
      }
      return response;
    } catch (error) {
      rethrow;
    }
  }

  Future<http.Response> post(String requestUrl) async {
    debugPrint('Request url--> ${requestUrl.toString()}');
    var url = requestUrl;
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
          'Expires': '0',
        },
      );
      debugPrint('Response --> ${response.toString()}');

      // 🔴 Agar backend bole unauthorized (dusre device se login)
      if (response.statusCode == 401) {
        _handleUnauthorized();
      }
      return response;
    } catch (error) {
      rethrow;
    }
  }

  Future<void> _handleUnauthorized() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // token hata do

    print("🚪 Logging out user...");

    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/forceLogout',
      (Route<dynamic> route) => false,
    );
  }
}

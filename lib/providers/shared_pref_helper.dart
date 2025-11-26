// ignore_for_file: constant_identifier_names, camel_case_types
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferenceHelper {
  Future<bool> setAuthToken(String token) async {
    final pref = await SharedPreferences.getInstance();
    final ok = await pref.setString(userPref.AuthToken.toString(), token);
    print(
        '💾 [Prefs] setAuthToken -> ${token.isEmpty ? "(empty)" : token.substring(0, 30) + "..."} (ok=$ok)');

    return pref.setString(userPref.AuthToken.toString(), token);
  }

  Future<String?> getAuthToken() async {
    final pref = await SharedPreferences.getInstance();
    String? t = pref.getString(userPref.AuthToken.toString());
    print('📦 [Prefs] getAuthToken -> ${_mask(t)} (ok=$t)');
    return pref.getString(userPref.AuthToken.toString());
  }

  // // ====== DV TOKEN (separate key) ======
  // Future<bool> setDVToken(String token) async {
  //   final pref = await SharedPreferences.getInstance();
  //   final ok = await pref.setString(userPref.DVToken.toString(), token);
  //   // debug prints
  //   print('💾 [Prefs] setDVToken -> ${_mask(token)} (ok=$ok)');
  //   // read-back echo
  //   final echo = await pref.getString(userPref.DVToken.toString());
  //   print('🔎 [Prefs] getDVToken (echo) -> ${_mask(echo)}');
  //   return ok;
  // }
  //
  // Future<String?> getDVToken() async {
  //   final pref = await SharedPreferences.getInstance();
  //   final t = pref.getString(userPref.DVToken.toString());
  //   print('📦 [Prefs] getDVToken -> ${_mask(t)}');
  //   return t;
  // }

// (private) small masker for safe logging
  String _mask(String? t) {
    if (t == null || t.isEmpty) return '(empty)';
    if (t.length <= 10)
      return '${t.substring(0, 2)}***${t.substring(t.length - 2)}';
    return '${t.substring(0, 6)}***${t.substring(t.length - 4)}';
  }

  Future<bool> setFCMToken(String token) async {
    final pref = await SharedPreferences.getInstance();
    return pref.setString(userPref.FCMToken.toString(), token);
  }

  Future<String?> getFCMToken() async {
    final pref = await SharedPreferences.getInstance();
    return pref.getString(userPref.FCMToken.toString());
  }

  // 👇 NEW: user id store / read
  Future<void> setUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', userId);
  }

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  // Future<bool> setUserData(String userData) async {
  //   final pref = await SharedPreferences.getInstance();
  //   return pref.setString(userPref.UserData.toString(), userData);
  // }
  //
  // Future<String?> getUserData() async {
  //   final pref = await SharedPreferences.getInstance();
  //   return pref.getString(userPref.UserData.toString());
  // }
  Future<bool> setConfigData(String configData) async {
    final pref = await SharedPreferences.getInstance();
    return pref.setString(userPref.ConfigData.toString(), configData);
  }

  Future<String?> getConfigData() async {
    final pref = await SharedPreferences.getInstance();
    return pref.getString(userPref.ConfigData.toString());
  }

  Future<bool> setUserImage(String image) async {
    final pref = await SharedPreferences.getInstance();
    return pref.setString(userPref.Image.toString(), image);
  }

  Future<String?> getUserImage() async {
    final pref = await SharedPreferences.getInstance();
    return pref.getString(userPref.Image.toString());
  }

  Future<bool> setAppVersion(String version) async {
    final pref = await SharedPreferences.getInstance();
    return pref.setString('app_version', version);
  }

  Future<String?> getAppVersion() async {
    final pref = await SharedPreferences.getInstance();
    return pref.getString('app_version');
  }

  Future<void> clearAuthPreserveConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedConfig = prefs.getString(userPref.ConfigData.toString());

    await prefs.clear();

    if (cachedConfig != null) {
      await prefs.setString(userPref.ConfigData.toString(), cachedConfig);
    }
  }
}

// (optional) clear on logout
Future<void> clearAll() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('auth_token');
  await prefs.remove('user_id');
  await prefs.remove('userData'); // if you use it
}

enum userPref {
  AuthToken,
  Image,
  ConfigData,
  FCMToken,
  // DVToken,
}

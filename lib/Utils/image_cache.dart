import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Super simple SharedPreferences image cache.
/// - Stores base64 bytes under a key
/// - Also stores small metadata: last url + timestamp
/// - If url changes OR cache expired => re-download
class SPImageCache {
  static const _dataPrefix = 'img_b64_';
  static const _metaPrefix = 'img_meta_';

  /// Load an ImageProvider from cache or fetch & cache it.
  /// [cacheKey] must be unique per display spot (e.g. "home_banner1").
  static Future<ImageProvider> loadProvider(
      String cacheKey,
      String imageUrl, {
        Duration maxAge = const Duration(days: 7), // change if you want
      }) async {
    final prefs = await SharedPreferences.getInstance();

    // read meta
    final metaStr = prefs.getString('$_metaPrefix$cacheKey');
    String? cachedUrl;
    int? cachedTs;
    if (metaStr != null && metaStr.isNotEmpty) {
      try {
        final m = json.decode(metaStr) as Map<String, dynamic>;
        cachedUrl = m['url'] as String?;
        cachedTs = m['ts'] as int?;
      } catch (_) {}
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final expired = cachedTs == null || (now - cachedTs > maxAge.inMilliseconds);
    final urlChanged = cachedUrl == null || cachedUrl != imageUrl;

    // use cache if valid
    if (!expired && !urlChanged) {
      final b64 = prefs.getString('$_dataPrefix$cacheKey');
      if (b64 != null && b64.isNotEmpty) {
        return MemoryImage(base64Decode(b64));
      }
    }

    // else fetch fresh
    try {
      final res = await http.get(Uri.parse(imageUrl));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final bytes = res.bodyBytes;
        await prefs.setString('$_dataPrefix$cacheKey', base64Encode(bytes));
        await prefs.setString(
          '$_metaPrefix$cacheKey',
          json.encode({'url': imageUrl, 'ts': now}),
        );
        return MemoryImage(bytes);
      }
    } catch (_) {
      // ignore; fallback below
    }

    // fallback to old cache even if expired
    final old = prefs.getString('$_dataPrefix$cacheKey');
    if (old != null && old.isNotEmpty) {
      return MemoryImage(base64Decode(old));
    }

    // last fallback: network
    return NetworkImage(imageUrl);
  }

  /// Force refresh a single key (optional utility)
  static Future<void> refresh(String cacheKey, String imageUrl) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_dataPrefix$cacheKey');
    await prefs.remove('$_metaPrefix$cacheKey');
    await loadProvider(cacheKey, imageUrl);
  }

  /// Clear a specific key
  static Future<void> clear(String cacheKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_dataPrefix$cacheKey');
    await prefs.remove('$_metaPrefix$cacheKey');
  }
}

import 'package:shared_preferences/shared_preferences.dart';

/// Caches Generative UI structured JSON responses for high performance and offline rendering.
class GenUiCacheService {
  static final Map<String, String> _memoryCache = {};
  static const String _prefix = 'genui_cache_';

  /// Cache response text for a given prompt key and patient ID.
  static Future<void> cacheResponse(String key, String response) async {
    final cacheKey = '$_prefix${key.toLowerCase().trim()}';
    _memoryCache[cacheKey] = response;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(cacheKey, response);
    } catch (_) {
      // SharedPreferences failure fallback to memory cache gracefully
    }
  }

  /// Get cached response if available.
  static Future<String?> getCachedResponse(String key) async {
    final cacheKey = '$_prefix${key.toLowerCase().trim()}';
    if (_memoryCache.containsKey(cacheKey)) {
      return _memoryCache[cacheKey];
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(cacheKey);
      if (stored != null) {
        _memoryCache[cacheKey] = stored;
        return stored;
      }
    } catch (_) {}

    return null;
  }

  /// Clear all cached GenUI structures.
  static Future<void> clearCache() async {
    _memoryCache.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith(_prefix));
      for (final k in keys) {
        await prefs.remove(k);
      }
    } catch (_) {}
  }
}

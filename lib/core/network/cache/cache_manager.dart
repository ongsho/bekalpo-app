// lib/core/network/cache/cache_manager.dart
/// Simple in-memory cache manager for API responses
/// Provides caching with TTL (time-to-live) support
class CacheManager {
  static CacheManager? _instance;
  final Map<String, _CacheEntry> _cache = {};

  CacheManager._internal();

  factory CacheManager() {
    _instance ??= CacheManager._internal();
    return _instance!;
  }

  /// Store data in cache with optional TTL (default 5 minutes)
  void set<T>(String key, T data, {Duration? ttl}) {
    final entry = _CacheEntry(
      data: data,
      expiry: ttl != null ? DateTime.now().add(ttl) : null,
    );
    _cache[key] = entry;
  }

  /// Retrieve data from cache
  /// Returns null if key doesn't exist or data has expired
  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null) return null;

    // Check if entry has expired
    if (entry.expiry != null && DateTime.now().isAfter(entry.expiry!)) {
      _cache.remove(key);
      return null;
    }

    return entry.data as T?;
  }

  /// Check if key exists in cache and is not expired
  bool has(String key) {
    final entry = _cache[key];
    if (entry == null) return false;

    // Check if entry has expired
    if (entry.expiry != null && DateTime.now().isAfter(entry.expiry!)) {
      _cache.remove(key);
      return false;
    }

    return true;
  }

  /// Remove specific key from cache
  void remove(String key) {
    _cache.remove(key);
  }

  /// Clear all cache entries
  void clear() {
    _cache.clear();
  }

  /// Clear expired entries only
  void clearExpired() {
    final now = DateTime.now();
    _cache.removeWhere((key, entry) {
      return entry.expiry != null && now.isAfter(entry.expiry!);
    });
  }

  /// Get cache size (number of entries)
  int get size => _cache.length;

  /// Get all cache keys
  List<String> get keys => _cache.keys.toList();
}

/// Internal cache entry with expiry support
class _CacheEntry {
  final dynamic data;
  final DateTime? expiry;

  _CacheEntry({required this.data, this.expiry});
}

/// Cache key builder utility
class CacheKeyBuilder {
  /// Build cache key for list endpoints
  static String list(String endpoint, Map<String, dynamic>? params) {
    if (params == null || params.isEmpty) {
      return endpoint;
    }
    final queryString = params.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');
    return '$endpoint?$queryString';
  }

  /// Build cache key for single object endpoints
  static String single(String endpoint, int id) {
    return '$endpoint/$id';
  }

  /// Build custom cache key
  static String custom(String prefix, Map<String, dynamic> params) {
    final queryString = params.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');
    return '$prefix?$queryString';
  }
}

/// Cache configuration constants
class CacheConfig {
  /// Default TTL for cache entries (5 minutes)
  static const Duration defaultTTL = Duration(minutes: 5);

  /// Short TTL for frequently changing data (1 minute)
  static const Duration shortTTL = Duration(minutes: 1);

  /// Long TTL for rarely changing data (1 hour)
  static const Duration longTTL = Duration(hours: 1);

  /// Very long TTL for static data (24 hours)
  static const Duration veryLongTTL = Duration(hours: 24);

  /// No TTL (cache until manually cleared)
  static const Duration noTTL = Duration(days: 365 * 100);
}

// lib/core/providers/category_provider.dart
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category.dart';
import '../repositories/category_repository.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository();
});

const _kCategoryCacheKey = 'cache_categories_v1';
const _kCategoryCacheTimeKey = 'cache_categories_v1_time';
const Duration _kCategoryCacheTTL = Duration(hours: 24);

Future<List<Category>?> _readCategoryCache({bool ignoreExpiry = false}) async {
  final prefs = await SharedPreferences.getInstance();
  final cachedAtMillis = prefs.getInt(_kCategoryCacheTimeKey);
  final cachedJson = prefs.getString(_kCategoryCacheKey);
  if (cachedAtMillis == null || cachedJson == null) return null;

  if (!ignoreExpiry) {
    final cachedAt = DateTime.fromMillisecondsSinceEpoch(cachedAtMillis);
    if (DateTime.now().difference(cachedAt) > _kCategoryCacheTTL) return null;
  }

  try {
    final decoded = jsonDecode(cachedJson) as List;
    return decoded
        .map((e) => Category.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return null;
  }
}

Future<void> _writeCategoryCache(List<Category> categories) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    _kCategoryCacheKey,
    jsonEncode(categories.map((c) => c.toJson()).toList()),
  );
  await prefs.setInt(
    _kCategoryCacheTimeKey,
    DateTime.now().millisecondsSinceEpoch,
  );
}

// ── Notifier ────────────────────────────────────────────────────────────────
class CategoriesNotifier extends AsyncNotifier<List<Category>> {
  @override
  Future<List<Category>> build() async {
    // Always show cache immediately if available (ignoring expiry)
    final stale = await _readCategoryCache(ignoreExpiry: true);
    if (stale != null) {
      // Check if actually stale — if so, refresh silently in background
      final fresh = await _readCategoryCache(ignoreExpiry: false);
      if (fresh == null) {
        // Cache exists but expired — return stale and refresh behind the scenes
        _refreshInBackground();
      }
      return stale;
    }
    // No cache at all — genuine first load, must fetch
    return _fetchAndCache();
  }

  Future<List<Category>> _fetchAndCache() async {
    final repo = ref.read(categoryRepositoryProvider);
    final fresh = await repo.getCategories();
    await _writeCategoryCache(fresh);
    return fresh;
  }

  void _refreshInBackground() {
    Future.microtask(() async {
      try {
        final fresh = await _fetchAndCache();
        // Only update state if notifier is still alive
        state = AsyncData(fresh);
      } catch (_) {
        // Silent failure — stale cache already showing, that's fine
      }
    });
  }

  /// Pull-to-refresh: try fresh fetch; fall back to cache on failure
  Future<void> refresh() async {
    try {
      final fresh = await _fetchAndCache();
      state = AsyncData(fresh);
    } catch (e, st) {
      final cached = await _readCategoryCache(ignoreExpiry: true);
      if (cached != null) {
        state = AsyncData(cached); // keep showing stale — no error screen
      } else {
        state = AsyncError(e, st);
      }
    }
  }
}

final categoriesProvider =
    AsyncNotifierProvider<CategoriesNotifier, List<Category>>(
      CategoriesNotifier.new,
    );

final categoryProvider = FutureProvider.family<Category?, int>((ref, id) async {
  final repository = ref.watch(categoryRepositoryProvider);
  return repository.getCategoryById(id);
});

// lib/core/providers/search_history_provider.dart
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/search_history.dart';

class SearchHistoryNotifier extends StateNotifier<List<SearchHistoryItem>> {
  static const String _storageKey = 'search_history';
  static const int _maxHistoryItems = 10;

  SearchHistoryNotifier() : super([]) {
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_storageKey);
      
      if (historyJson != null) {
        final List<dynamic> decoded = json.decode(historyJson);
        final history = decoded
            .map((item) => SearchHistoryItem.fromJson(item as Map<String, dynamic>))
            .toList();
        state = history;
      }
    } catch (e) {
      state = [];
    }
  }

  Future<void> addSearchQuery(String query) async {
    if (query.trim().isEmpty) return;
    
    final trimmedQuery = query.trim();
    
    // Remove if already exists to move it to top
    final existingIndex = state.indexWhere((item) => item.query == trimmedQuery);
    List<SearchHistoryItem> newHistory;
    
    if (existingIndex != -1) {
      newHistory = [...state];
      newHistory.removeAt(existingIndex);
    } else {
      newHistory = [...state];
    }
    
    // Add new item at the beginning
    newHistory.insert(0, SearchHistoryItem(
      query: trimmedQuery,
      timestamp: DateTime.now(),
    ));
    
    // Keep only the most recent searches
    if (newHistory.length > _maxHistoryItems) {
      newHistory = newHistory.sublist(0, _maxHistoryItems);
    }
    
    state = newHistory;
    await _saveHistory();
  }

  Future<void> removeSearchQuery(String query) async {
    final newHistory = state.where((item) => item.query != query).toList();
    state = newHistory;
    await _saveHistory();
  }

  Future<void> clearHistory() async {
    state = [];
    await _saveHistory();
  }

  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = json.encode(
        state.map((item) => item.toJson()).toList(),
      );
      await prefs.setString(_storageKey, historyJson);
    } catch (e) {
      // Handle error silently
    }
  }
}

final searchHistoryProvider =
    StateNotifierProvider<SearchHistoryNotifier, List<SearchHistoryItem>>((ref) {
  return SearchHistoryNotifier();
});

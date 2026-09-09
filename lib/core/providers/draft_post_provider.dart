import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/draft_post.dart';
import '../network/api_client.dart';
import 'api_client_provider.dart';

class DraftPostState {
  final DraftPost? currentDraft;
  final bool isLoading;
  final String? error;

  const DraftPostState({this.currentDraft, this.isLoading = false, this.error});

  DraftPostState copyWith({
    DraftPost? currentDraft,
    bool? isLoading,
    String? error,
  }) {
    return DraftPostState(
      currentDraft: currentDraft ?? this.currentDraft,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class DraftPostNotifier extends StateNotifier<DraftPostState> {
  final ApiClient _apiClient;
  static const String _draftKey = 'current_draft_post';
  static int _instanceCount = 0;
  final int _instanceId;

  DraftPostNotifier(this._apiClient)
    : _instanceId = ++_instanceCount,
      super(const DraftPostState()) {
    print('DraftPost: Instance #$_instanceId created');
  }

  Future<String> initializeDraft() async {
    print('DraftPost: initializeDraft called on instance #$_instanceId');

    // If we already have a current draft, return its ID immediately
    if (state.currentDraft != null) {
      print(
        'DraftPost: Instance #$_instanceId - Returning existing draft ID: ${state.currentDraft!.postId}',
      );
      return state.currentDraft!.postId;
    }

    print(
      'DraftPost: Instance #$_instanceId - No current draft, proceeding with init',
    );
    state = state.copyWith(isLoading: true, error: null);

    try {
      // First check if existing draft exists in local storage
      final existingDraft = await _loadLocalDraft();

      if (existingDraft != null) {
        print(
          'DraftPost: Instance #$_instanceId - Found existing draft with ID: ${existingDraft.postId}',
        );
        state = state.copyWith(currentDraft: existingDraft, isLoading: false);
        return existingDraft.postId;
      }

      // No existing draft, create new post ID via API
      print(
        'DraftPost: Instance #$_instanceId - No existing draft, creating new post ID via API',
      );
      final response = await _apiClient.post('posts/init');

      if (response.statusCode == 200 && response.data != null) {
        // API returns nested structure: {status: true, data: {id: 984, ...}}
        final postId = response.data['data']['id'].toString();

        // Create new draft and save to local storage
        final newDraft = DraftPost(
          postId: postId,
          formData: {},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          status: 'draft',
        );

        await _saveLocalDraft(newDraft);

        state = state.copyWith(currentDraft: newDraft, isLoading: false);

        print(
          'DraftPost: Instance #$_instanceId - Created new draft with ID: $postId',
        );
        return postId;
      } else {
        throw Exception('Failed to create post ID');
      }
    } catch (e) {
      print('DraftPost: Instance #$_instanceId - Error initializing draft: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to initialize draft: $e',
      );
      rethrow;
    }
  }

  Future<void> updateDraft(Map<String, dynamic> data) async {
    final currentDraft = state.currentDraft;
    if (currentDraft == null) {
      print('DraftPost: No current draft to update');
      return;
    }

    try {
      // Merge new data with existing form data
      final updatedFormData = Map<String, dynamic>.from(currentDraft.formData);
      updatedFormData.addAll(data);

      final updatedDraft = currentDraft.copyWith(
        formData: updatedFormData,
        updatedAt: DateTime.now(),
        status: 'partial',
      );

      // Save to local storage
      await _saveLocalDraft(updatedDraft);

      state = state.copyWith(currentDraft: updatedDraft);
      print('DraftPost: Updated draft with data: ${data.keys}');
    } catch (e) {
      print('DraftPost: Error updating draft: $e');
      state = state.copyWith(error: 'Failed to update draft: $e');
    }
  }

  Future<void> updateDraftOnBackend(
    String postId,
    Map<String, dynamic> data,
  ) async {
    try {
      print('DraftPost: Updating draft on backend with ID: $postId');

      final response = await _apiClient.put('posts/$postId', data: data);

      if (response.statusCode == 200) {
        print('DraftPost: Draft updated successfully on backend');
      } else {
        throw Exception('Failed to update draft on backend');
      }
    } catch (e) {
      print('DraftPost: Error updating draft on backend: $e');
      state = state.copyWith(error: 'Failed to update draft on backend: $e');
      rethrow;
    }
  }

  Future<void> completeDraft() async {
    final currentDraft = state.currentDraft;
    if (currentDraft == null) {
      print('DraftPost: No current draft to complete');
      return;
    }

    try {
      // Submit the post to server
      // Note: This will be implemented in the next task (post submission)
      // For now, we'll just clear the local draft

      await _clearLocalDraft();

      state = const DraftPostState();
      print('DraftPost: Draft completed and cleared');
    } catch (e) {
      print('DraftPost: Error completing draft: $e');
      state = state.copyWith(error: 'Failed to complete draft: $e');
    }
  }

  Future<void> clearDraft() async {
    try {
      await _clearLocalDraft();
      state = const DraftPostState();
      print('DraftPost: Draft cleared manually');
    } catch (e) {
      print('DraftPost: Error clearing draft: $e');
    }
  }

  Future<DraftPost?> _loadLocalDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draftJson = prefs.getString(_draftKey);

      if (draftJson != null) {
        // Parse the JSON string back to Map
        // Note: SharedPreferences stores strings, so we need to handle JSON parsing
        // For simplicity, we'll store individual fields instead of full JSON
        final postId = prefs.getString('${_draftKey}_id');
        final formDataJson = prefs.getString('${_draftKey}_data');
        final createdAtStr = prefs.getString('${_draftKey}_created');
        final updatedAtStr = prefs.getString('${_draftKey}_updated');
        final status = prefs.getString('${_draftKey}_status') ?? 'draft';

        if (postId != null &&
            formDataJson != null &&
            createdAtStr != null &&
            updatedAtStr != null) {
          return DraftPost(
            postId: postId,
            formData: _parseFormData(formDataJson),
            createdAt: DateTime.parse(createdAtStr),
            updatedAt: DateTime.parse(updatedAtStr),
            status: status,
          );
        }
      }

      return null;
    } catch (e) {
      print('DraftPost: Error loading local draft: $e');
      return null;
    }
  }

  Future<void> _saveLocalDraft(DraftPost draft) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Store draft data as individual fields
      await prefs.setString('${_draftKey}_id', draft.postId);
      await prefs.setString(
        '${_draftKey}_data',
        _stringifyFormData(draft.formData),
      );
      await prefs.setString(
        '${_draftKey}_created',
        draft.createdAt.toIso8601String(),
      );
      await prefs.setString(
        '${_draftKey}_updated',
        draft.updatedAt.toIso8601String(),
      );
      await prefs.setString('${_draftKey}_status', draft.status);

      print('DraftPost: Saved draft to local storage');
    } catch (e) {
      print('DraftPost: Error saving local draft: $e');
      rethrow;
    }
  }

  Future<void> _clearLocalDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove('${_draftKey}_id');
      await prefs.remove('${_draftKey}_data');
      await prefs.remove('${_draftKey}_created');
      await prefs.remove('${_draftKey}_updated');
      await prefs.remove('${_draftKey}_status');

      print('DraftPost: Cleared draft from local storage');
    } catch (e) {
      print('DraftPost: Error clearing local draft: $e');
      rethrow;
    }
  }

  String _stringifyFormData(Map<String, dynamic> data) {
    return jsonEncode(data);
  }

  Map<String, dynamic> _parseFormData(String dataString) {
    try {
      return jsonDecode(dataString) as Map<String, dynamic>;
    } catch (e) {
      print('DraftPost: Error parsing form data: $e');
      return {};
    }
  }
}

final draftPostProvider =
    StateNotifierProvider<DraftPostNotifier, DraftPostState>((ref) {
      final apiClient = ref.watch(apiClientProvider);
      return DraftPostNotifier(apiClient);
    });

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/post_field.dart';
import '../network/api_client.dart';
import 'api_client_provider.dart';

class PostFieldsState {
  final List<PostField> fields;
  final bool isLoading;
  final String? error;

  const PostFieldsState({
    this.fields = const [],
    this.isLoading = false,
    this.error,
  });

  PostFieldsState copyWith({
    List<PostField>? fields,
    bool? isLoading,
    String? error,
  }) {
    return PostFieldsState(
      fields: fields ?? this.fields,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class PostFieldsNotifier extends StateNotifier<PostFieldsState> {
  final ApiClient _apiClient;

  PostFieldsNotifier(this._apiClient) : super(const PostFieldsState());

  Future<void> fetchFields(int categoryId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiClient.post(
        'posts/fields',
        data: {'category_id': categoryId},
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> fieldsData = response.data;
        final fields = fieldsData
            .map((json) => PostField.fromJson(json as Map<String, dynamic>))
            .toList();

        // Sort by serial_no
        fields.sort((a, b) => a.pivot.serialNo.compareTo(b.pivot.serialNo));

        state = state.copyWith(fields: fields, isLoading: false);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to load fields',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error loading fields: $e',
      );
    }
  }

  void clearFields() {
    state = const PostFieldsState();
  }
}

final postFieldsProvider =
    StateNotifierProvider<PostFieldsNotifier, PostFieldsState>((ref) {
      final apiClient = ref.watch(apiClientProvider);
      return PostFieldsNotifier(apiClient);
    });

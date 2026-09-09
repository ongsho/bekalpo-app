import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/model.dart';
import '../network/api_client.dart';
import 'api_client_provider.dart';

class ModelState {
  final List<ProductModel> models;
  final bool isLoading;
  final String? error;

  const ModelState({
    this.models = const [],
    this.isLoading = false,
    this.error,
  });

  ModelState copyWith({
    List<ProductModel>? models,
    bool? isLoading,
    String? error,
  }) {
    return ModelState(
      models: models ?? this.models,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class ModelNotifier extends StateNotifier<ModelState> {
  final ApiClient _apiClient;

  ModelNotifier(this._apiClient) : super(const ModelState());

  Future<void> fetchModels(int? brandId) async {
    if (brandId == null) return;

    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiClient.get(
        'models',
        queryParameters: {'brand_id': brandId.toString()},
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> modelsData = response.data as List;
        final models = modelsData
            .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
            .toList();

        state = state.copyWith(models: models, isLoading: false);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to load models',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error loading models: $e',
      );
    }
  }

  void clearModels() {
    state = const ModelState();
  }
}

final modelProvider = StateNotifierProvider<ModelNotifier, ModelState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ModelNotifier(apiClient);
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/brand.dart';
import '../network/api_client.dart';
import 'api_client_provider.dart';

class BrandState {
  final List<Brand> brands;
  final bool isLoading;
  final String? error;

  const BrandState({
    this.brands = const [],
    this.isLoading = false,
    this.error,
  });

  BrandState copyWith({List<Brand>? brands, bool? isLoading, String? error}) {
    return BrandState(
      brands: brands ?? this.brands,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class BrandNotifier extends StateNotifier<BrandState> {
  final ApiClient _apiClient;

  BrandNotifier(this._apiClient) : super(const BrandState());

  Future<void> fetchBrands(int? categoryId) async {
    if (categoryId == null) return;

    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiClient.get(
        'brands',
        queryParameters: {'category_id': categoryId.toString()},
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> brandsData = response.data as List;
        final brands = brandsData
            .map((json) => Brand.fromJson(json as Map<String, dynamic>))
            .toList();

        state = state.copyWith(brands: brands, isLoading: false);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to load brands',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error loading brands: $e',
      );
    }
  }

  void clearBrands() {
    state = const BrandState();
  }
}

final brandProvider = StateNotifierProvider<BrandNotifier, BrandState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return BrandNotifier(apiClient);
});

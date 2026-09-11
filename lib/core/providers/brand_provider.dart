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

    print('BrandProvider: Fetching brands for category_id: $categoryId');
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiClient.get(
        'brands',
        queryParameters: {'category_id': categoryId.toString()},
      );

      print('BrandProvider: Response status: ${response.statusCode}');
      print('BrandProvider: Response data type: ${response.data.runtimeType}');
      print('BrandProvider: Response data: ${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> brandsData = response.data as List;
        print('BrandProvider: Brands data type: ${brandsData.runtimeType}');
        print('BrandProvider: Brands data length: ${brandsData.length}');
        
        final brands = brandsData
            .map((json) => Brand.fromJson(json as Map<String, dynamic>))
            .toList();

        print('BrandProvider: Loaded ${brands.length} brands');
        print('BrandProvider: Brand names: ${brands.map((b) => b.nameEn).toList()}');
        state = state.copyWith(brands: brands, isLoading: false);
      } else {
        print('BrandProvider: Failed to load brands - status: ${response.statusCode}');
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to load brands',
        );
      }
    } catch (e) {
      print('BrandProvider: Error loading brands: $e');
      print('BrandProvider: Error type: ${e.runtimeType}');
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

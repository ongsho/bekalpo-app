import '../models/category.dart';
import '../network/api_service.dart';

class CategoryRepository {
  Future<List<Category>> getCategories() async {
    try {
      final response = await ApiService.get('categories');

      if (response is List) {
        return response.map((json) => Category.fromJson(json)).toList();
      } else if (response is Map && response.containsKey('data')) {
        final data = response['data'];
        if (data is List) {
          return data.map((json) => Category.fromJson(json)).toList();
        }
      }

      return [];
    } catch (e) {
      throw Exception('Failed to load categories: $e');
    }
  }

  Future<Category?> getCategoryById(int id) async {
    try {
      final response = await ApiService.get('categories/$id');

      if (response is Map) {
        return Category.fromJson(Map<String, dynamic>.from(response));
      }

      return null;
    } catch (e) {
      throw Exception('Failed to load category: $e');
    }
  }
}

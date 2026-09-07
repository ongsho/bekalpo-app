import '../models/division.dart';
import '../network/api_service.dart';

class LocationRepository {
  Future<List<Division>> getLocations() async {
    try {
      final response = await ApiService.get('locations');

      if (response is List) {
        return response.map((json) => Division.fromJson(json)).toList();
      } else if (response is Map && response.containsKey('data')) {
        final data = response['data'];
        if (data is List) {
          return data.map((json) => Division.fromJson(json)).toList();
        }
      }

      return [];
    } catch (e) {
      throw Exception('Failed to load locations: $e');
    }
  }
}

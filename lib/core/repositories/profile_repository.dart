import 'dart:io';
import '../models/profile.dart';
import '../network/api_service.dart';
import '../network/api_client.dart';

class ProfileRepository {
  Future<Profile> getProfile() async {
    try {
      final response = await ApiService.get('profile');

      if (response is Map && response.containsKey('data')) {
        final data = response['data'];
        if (data is Map) {
          return Profile.fromJson(Map<String, dynamic>.from(data));
        }
      }

      throw Exception('Invalid profile response format');
    } catch (e) {
      throw Exception('Failed to load profile: $e');
    }
  }

  Future<Profile> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await ApiService.post('profile', data: data);

      if (response is Map && response.containsKey('user')) {
        final userData = response['user'];
        if (userData is Map) {
          return Profile.fromJson(Map<String, dynamic>.from(userData));
        }
      }

      throw Exception('Invalid profile update response format');
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  Future<Profile> uploadAvatar(File file) async {
    try {
      final client = ApiClient();
      final response = await client.uploadFile('profile/picture', file: file);

      if (response.data is Map && response.data.containsKey('user')) {
        final userData = response.data['user'];
        if (userData is Map) {
          return Profile.fromJson(Map<String, dynamic>.from(userData));
        }
      }

      throw Exception('Invalid avatar upload response format');
    } catch (e) {
      throw Exception('Failed to upload avatar: $e');
    }
  }
}

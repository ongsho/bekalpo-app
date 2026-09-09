import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/contact.dart';
import '../network/api_client.dart';
import 'api_client_provider.dart';

class AuthState {
  final bool isLoggedIn;
  final String? userName;
  final String? userEmail;
  final String? userPhone;
  final String? token;
  final String? avatar;
  final bool isLoading;
  final List<dynamic>? userContacts; // Add contacts support

  AuthState({
    required this.isLoggedIn,
    this.userName,
    this.userEmail,
    this.userPhone,
    this.token,
    this.avatar,
    this.isLoading = false,
    this.userContacts,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    String? userName,
    String? userEmail,
    String? userPhone,
    String? token,
    String? avatar,
    bool? isLoading,
    List<dynamic>? userContacts,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      userPhone: userPhone ?? this.userPhone,
      token: token ?? this.token,
      avatar: avatar ?? this.avatar,
      isLoading: isLoading ?? this.isLoading,
      userContacts: userContacts ?? this.userContacts,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _apiClient;

  AuthNotifier(this._apiClient)
    : super(AuthState(isLoggedIn: false, isLoading: true)) {
    _loadAuthState();
  }

  Future<void> _loadAuthState() async {
    print('AuthNotifier: Loading auth state...');
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final userName = prefs.getString('user_name');
      final userEmail = prefs.getString('user_email');
      final userPhone = prefs.getString('user_phone');
      final avatar = prefs.getString('user_avatar');
      final contactsJson = prefs.getString('user_contacts');

      print('AuthNotifier: Token exists: ${token != null}');
      print('AuthNotifier: User name: $userName');
      print('AuthNotifier: User email: $userEmail');
      print('AuthNotifier: User phone: $userPhone');

      List<dynamic>? contacts;
      if (contactsJson != null) {
        final List<dynamic> decoded = jsonDecode(contactsJson);
        contacts = decoded
            .map((json) => Contact.fromJson(json as Map<String, dynamic>))
            .toList();
        print('AuthNotifier: Loaded ${contacts.length} user contacts');
      }

      if (token != null && userName != null) {
        print('AuthNotifier: Restoring auth state');
        state = AuthState(
          isLoggedIn: true,
          userName: userName,
          userEmail: userEmail,
          userPhone: userPhone,
          token: token,
          avatar: avatar,
          isLoading: false,
          userContacts: contacts,
        );
      } else {
        print('AuthNotifier: No valid auth data found');
        state = AuthState(isLoggedIn: false, isLoading: false);
      }
    } catch (e) {
      print('AuthNotifier: Error loading auth state: $e');
      state = AuthState(isLoggedIn: false, isLoading: false);
    }
  }

  void login({
    required String userName,
    String? userEmail,
    String? userPhone,
    String? token,
    String? avatar,
  }) async {
    print('AuthNotifier: Login called for user: $userName');

    // Save auth data to shared preferences
    try {
      final prefs = await SharedPreferences.getInstance();
      if (token != null) {
        await prefs.setString('auth_token', token);
        print('AuthNotifier: Token saved to SharedPreferences');
      }
      await prefs.setString('user_name', userName);
      if (userEmail != null) {
        await prefs.setString('user_email', userEmail);
      }
      if (userPhone != null) {
        await prefs.setString('user_phone', userPhone);
        print('AuthNotifier: Phone saved to SharedPreferences');
      }
      if (avatar != null) {
        await prefs.setString('user_avatar', avatar);
        print('AuthNotifier: Avatar saved to SharedPreferences');
      }
      print('AuthNotifier: All auth data saved successfully');
    } catch (e) {
      print('AuthNotifier: Error saving auth data: $e');
    }

    state = state.copyWith(
      isLoggedIn: true,
      userName: userName,
      userEmail: userEmail,
      userPhone: userPhone,
      token: token,
      avatar: avatar,
    );

    print('AuthNotifier: Auth state updated: isLoggedIn=true');
  }

  Future<void> logout() async {
    print('AuthNotifier: Logout called');

    // Clear auth data from shared preferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_name');
      await prefs.remove('user_email');
      await prefs.remove('user_phone');
      await prefs.remove('user_avatar');
      print('AuthNotifier: All auth data cleared from SharedPreferences');
    } catch (e) {
      print('AuthNotifier: Error clearing auth data: $e');
    }

    state = state.copyWith(
      isLoggedIn: false,
      userName: null,
      userEmail: null,
      userPhone: null,
      token: null,
      avatar: null,
    );

    print('AuthNotifier: Auth state reset: isLoggedIn=false');
  }

  void updateProfile({String? userName, String? avatar}) async {
    print('AuthNotifier: Update profile called');

    // Update profile data in shared preferences (without touching token)
    try {
      final prefs = await SharedPreferences.getInstance();
      if (userName != null) {
        await prefs.setString('user_name', userName);
        print('AuthNotifier: User name updated in SharedPreferences');
      }
      if (avatar != null) {
        await prefs.setString('user_avatar', avatar);
        print('AuthNotifier: Avatar updated in SharedPreferences');
      }
      print('AuthNotifier: Profile data updated successfully');
    } catch (e) {
      print('AuthNotifier: Error updating profile data: $e');
    }

    state = state.copyWith(
      userName: userName ?? state.userName,
      avatar: avatar ?? state.avatar,
    );

    print('AuthNotifier: Auth state profile updated');
  }

  void updateUserContacts(List<Contact> contacts) async {
    print('AuthNotifier: Update user contacts called');

    // Convert contacts to JSON for storage
    final contactsJson = contacts.map((c) => c.toJson()).toList();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_contacts', jsonEncode(contactsJson));
      print('AuthNotifier: User contacts saved to SharedPreferences');
    } catch (e) {
      print('AuthNotifier: Error saving user contacts: $e');
    }

    state = state.copyWith(userContacts: contactsJson);

    print('AuthNotifier: User contacts updated');
  }

  Future<void> loadUserContacts() async {
    print('AuthNotifier: Loading user contacts...');

    try {
      final prefs = await SharedPreferences.getInstance();
      final contactsJson = prefs.getString('user_contacts');

      if (contactsJson != null) {
        final List<dynamic> decoded = jsonDecode(contactsJson);
        final contacts = decoded
            .map((json) => Contact.fromJson(json as Map<String, dynamic>))
            .toList();

        state = state.copyWith(userContacts: contacts);
        print('AuthNotifier: Loaded ${contacts.length} user contacts');
      }
    } catch (e) {
      print('AuthNotifier: Error loading user contacts: $e');
    }
  }

  Future<void> refreshUser() async {
    print('AuthNotifier: Refreshing user data from backend...');

    try {
      // Use /api/posts?my_posts=true which returns user data with contacts
      final response = await _apiClient.get(
        'posts',
        queryParameters: {'my_posts': 'true', 'page': '1', 'per_page': '1'},
      );

      print('AuthNotifier: User data refresh response: ${response.statusCode}');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] as List;
        if (data.isNotEmpty) {
          final userData = data[0]['user'] as Map<String, dynamic>;

          // Update user data from backend response
          final userName = userData['name'] as String?;
          final userEmail = userData['email'] as String?;
          final userPhone = userData['phone'] as String?;
          final avatar = userData['avatar'] as String?;

          // Update contacts if available
          List<dynamic>? contacts;
          try {
            final phonesResponse = await _apiClient.get('phones');
            if (phonesResponse.statusCode == 200 &&
                phonesResponse.data != null) {
              final phonesData = phonesResponse.data['data'] as List;
              contacts = phonesData
                  .map((json) => Contact.fromJson(json as Map<String, dynamic>))
                  .toList();
              print(
                'AuthNotifier: Loaded ${contacts.length} contacts from /api/phones',
              );

              // Save contacts to local storage
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString(
                'user_contacts',
                jsonEncode(contacts.map((c) => c.toJson()).toList()),
              );
            }
          } catch (e) {
            print('AuthNotifier: Error fetching contacts: $e');
          }

          // Update auth state
          state = state.copyWith(
            userName: userName,
            userEmail: userEmail,
            userPhone: userPhone,
            avatar: avatar,
            userContacts: contacts,
          );

          print('AuthNotifier: User data refreshed successfully');
          print('AuthNotifier: User phone: $userPhone');
          print('AuthNotifier: Contacts count: ${contacts?.length ?? 0}');
        }
      }
    } catch (e) {
      print('AuthNotifier: Error refreshing user data: $e');
      // Fallback to local storage if backend fails
      await _loadAuthState();
      await loadUserContacts();
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthNotifier(apiClient);
});

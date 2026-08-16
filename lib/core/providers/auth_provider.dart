import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthState {
  final bool isLoggedIn;
  final String? userName;
  final String? userEmail;
  final String? token;
  final String? avatar;
  final bool isLoading;

  AuthState({
    required this.isLoggedIn,
    this.userName,
    this.userEmail,
    this.token,
    this.avatar,
    this.isLoading = false,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    String? userName,
    String? userEmail,
    String? token,
    String? avatar,
    bool? isLoading,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      token: token ?? this.token,
      avatar: avatar ?? this.avatar,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState(isLoggedIn: false, isLoading: true)) {
    _loadAuthState();
  }

  Future<void> _loadAuthState() async {
    print('AuthNotifier: Loading auth state...');
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final userName = prefs.getString('user_name');
      final userEmail = prefs.getString('user_email');
      final avatar = prefs.getString('user_avatar');

      print('AuthNotifier: Token exists: ${token != null}');
      print('AuthNotifier: User name: $userName');
      print('AuthNotifier: User email: $userEmail');

      if (token != null && userName != null && userEmail != null) {
        print('AuthNotifier: Restoring auth state');
        state = AuthState(
          isLoggedIn: true,
          userName: userName,
          userEmail: userEmail,
          token: token,
          avatar: avatar,
          isLoading: false,
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
    required String userEmail,
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
      await prefs.setString('user_email', userEmail);
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
      await prefs.remove('user_avatar');
      print('AuthNotifier: All auth data cleared from SharedPreferences');
    } catch (e) {
      print('AuthNotifier: Error clearing auth data: $e');
    }

    state = state.copyWith(
      isLoggedIn: false,
      userName: null,
      userEmail: null,
      token: null,
      avatar: null,
    );

    print('AuthNotifier: Auth state reset: isLoggedIn=false');
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthState {
  final bool isLoggedIn;
  final String? userName;
  final String? userEmail;

  AuthState({
    required this.isLoggedIn,
    this.userName,
    this.userEmail,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    String? userName,
    String? userEmail,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState(isLoggedIn: false));

  void login({required String userName, required String userEmail}) {
    state = state.copyWith(
      isLoggedIn: true,
      userName: userName,
      userEmail: userEmail,
    );
  }

  void logout() {
    state = state.copyWith(
      isLoggedIn: false,
      userName: null,
      userEmail: null,
    );
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

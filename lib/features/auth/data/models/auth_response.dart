class AuthResponse {
  final bool status;
  final String? message;
  final String? action;
  final Map<String, dynamic>? errors;

  AuthResponse({required this.status, this.message, this.action, this.errors});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      status: json['status'] ?? false,
      message: json['message'],
      action: json['action'],
      errors: json['errors'] != null
          ? Map<String, dynamic>.from(json['errors'])
          : null,
    );
  }

  bool get requiresSignup => !status && action == null; // Email doesn't exist
  bool get requiresSignin =>
      status && action == 'signin'; // User exists with password
  bool get requiresSetPassword =>
      status && action == 'set_password'; // Google user without password
}

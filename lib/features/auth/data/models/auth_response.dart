class AuthResponse {
  final dynamic status; // Can be bool or string
  final String? message;
  final String? action;
  final Map<String, dynamic>? errors;

  AuthResponse({required this.status, this.message, this.action, this.errors});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      status: json['status'] ?? false,
      message: json['message'],
      action: json['action'],
      errors: (json['error'] ?? json['errors']) != null
          ? Map<String, dynamic>.from(json['error'] ?? json['errors'])
          : null,
    );
  }

  // Helper to check if status is successful (can be bool true or string "success")
  bool get isSuccess {
    if (status is bool) return status as bool;
    if (status is String) return status == 'success';
    return false;
  }

  // Email check response logic
  bool get requiresSignup =>
      !isSuccess && action == null; // Email doesn't exist
  bool get requiresSignin =>
      isSuccess && action == 'signin'; // User exists with password
  bool get requiresSetPassword =>
      isSuccess && action == 'set_password'; // Google user without password

  // Phone check response logic
  bool get requiresPhoneSignup =>
      !isSuccess && action == null; // Phone doesn't exist -> go to signup
  bool get requiresPhoneVerify =>
      !isSuccess &&
      action == 'verifyPhone'; // Phone exists but not verified -> go to OTP
  bool get requiresPhoneSignin =>
      isSuccess; // Phone exists and verified -> go to signin
}

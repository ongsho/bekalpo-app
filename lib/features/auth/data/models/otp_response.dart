class OtpResponse {
  final dynamic status;
  final String? message;
  final Map<String, dynamic>? errors;

  OtpResponse({required this.status, this.message, this.errors});

  factory OtpResponse.fromJson(Map<String, dynamic> json) {
    return OtpResponse(
      status: json['status'] ?? false,
      message: json['message'],
      errors: (json['error'] ?? json['errors']) != null
          ? Map<String, dynamic>.from(json['error'] ?? json['errors'])
          : null,
    );
  }

  bool get isSuccess {
    if (status is bool) return status as bool;
    if (status is String) return status == 'success';
    return false;
  }
}

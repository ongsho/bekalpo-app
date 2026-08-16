class EmailAuthRequest {
  final String email;

  EmailAuthRequest({required this.email});

  Map<String, dynamic> toJson() {
    return {
      'email': email,
    };
  }
}

class PhoneAuthRequest {
  final String phone;

  PhoneAuthRequest({required this.phone});

  Map<String, dynamic> toJson() {
    return {
      'phone': phone,
    };
  }
}

class GoogleAuthRequest {
  final String idToken;

  GoogleAuthRequest({required this.idToken});

  Map<String, dynamic> toJson() {
    return {
      'id_token': idToken,
    };
  }
}
class SigninResponse {
  final String status;
  final String token;
  final UserData user;

  SigninResponse({
    required this.status,
    required this.token,
    required this.user,
  });

  factory SigninResponse.fromJson(Map<String, dynamic> json) {
    return SigninResponse(
      status: json['status'] ?? '',
      token: json['token'] ?? '',
      user: UserData.fromJson(json['user'] ?? {}),
    );
  }

  bool get isSuccess => status == 'success';
}

class UserData {
  final int id;
  final String name;
  final String email;
  final String? emailVerifiedAt;
  final String? phone;
  final String? phoneVerifiedAt;
  final String? googleId;
  final String? avatar;
  final String? facebookId;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String username;
  final UserDetail? userDetail;

  UserData({
    required this.id,
    required this.name,
    required this.email,
    this.emailVerifiedAt,
    this.phone,
    this.phoneVerifiedAt,
    this.googleId,
    this.avatar,
    this.facebookId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.username,
    this.userDetail,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      emailVerifiedAt: json['email_verified_at'],
      phone: json['phone'],
      phoneVerifiedAt: json['phone_verified_at'],
      googleId: json['google_id']?.toString(),
      avatar: json['avatar'],
      facebookId: json['facebook_id']?.toString(),
      status: json['status'] ?? '',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
      username: json['username'] ?? '',
      userDetail: json['user_detail'] != null 
          ? UserDetail.fromJson(json['user_detail']) 
          : null,
    );
  }
}

class UserDetail {
  final int id;
  final int userId;
  final String? dateOfBirth;
  final String? gender;
  final String? bio;
  final int? thanaId;
  final String? postalCode;
  final String? streetAddress;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserDetail({
    required this.id,
    required this.userId,
    this.dateOfBirth,
    this.gender,
    this.bio,
    this.thanaId,
    this.postalCode,
    this.streetAddress,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserDetail.fromJson(Map<String, dynamic> json) {
    return UserDetail(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      dateOfBirth: json['date_of_birth'],
      gender: json['gender'],
      bio: json['bio'],
      thanaId: json['thana_id'],
      postalCode: json['postal_code'],
      streetAddress: json['street_address'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }
}
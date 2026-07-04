import 'package:bekalpo/core/models/contact.dart';

class User {
  final int? id;
  final String? name;
  final String? email;
  final DateTime? emailVerifiedAt;
  final String? phone;
  final DateTime? phoneVerifiedAt;
  final String? googleId;
  final String? avatar;
  final String? facebookId;
  final String? status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? username;
  final int? postsCount;
  final List<Contact>? contacts;

  User({
    this.id,
    this.name,
    this.email,
    this.emailVerifiedAt,
    this.phone,
    this.phoneVerifiedAt,
    this.googleId,
    this.avatar,
    this.facebookId,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.username,
    this.postsCount,
    this.contacts,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int?,
      name: json['name'] as String?,
      email: json['email'] as String?,
      emailVerifiedAt: json['email_verified_at'] != null
          ? DateTime.parse(json['email_verified_at'] as String)
          : null,
      phone: json['phone'] as String?,
      phoneVerifiedAt: json['phone_verified_at'] != null
          ? DateTime.parse(json['phone_verified_at'] as String)
          : null,
      googleId: json['google_id'] as String?,
      avatar: json['avatar'] as String?,
      facebookId: json['facebook_id'] as String?,
      status: json['status'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      username: json['username'] as String?,
      postsCount: json['posts_count'] as int?,
      contacts: json['contacts'] != null
          ? (json['contacts'] as List).map((e) => Contact.fromJson(e)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'email_verified_at': emailVerifiedAt?.toIso8601String(),
      'phone': phone,
      'phone_verified_at': phoneVerifiedAt?.toIso8601String(),
      'google_id': googleId,
      'avatar': avatar,
      'facebook_id': facebookId,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'username': username,
      'posts_count': postsCount,
      'contacts': contacts?.map((e) => e.toJson()).toList(),
    };
  }
}

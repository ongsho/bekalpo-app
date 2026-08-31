class Profile {
  final String name;
  final String? username;
  final String? dateOfBirth;
  final String? gender;
  final String? bio;
  final String? avatar;

  Profile({
    required this.name,
    this.username,
    this.dateOfBirth,
    this.gender,
    this.bio,
    this.avatar,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    String? avatarUrl = json['avatar'] as String?;
    // Fix malformed avatar URL that starts with /storage/
    if (avatarUrl != null && avatarUrl.startsWith('/storage/https://')) {
      avatarUrl = avatarUrl.replaceFirst('/storage/', '');
    }

    return Profile(
      name: json['name'] as String? ?? '',
      username: json['username'] as String?,
      dateOfBirth: json['date_of_birth'] as String?,
      gender: json['gender'] as String?,
      bio: json['bio'] as String?,
      avatar: avatarUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'username': username,
      'date_of_birth': dateOfBirth,
      'gender': gender,
      'bio': bio,
      'avatar': avatar,
    };
  }

  Profile copyWith({
    String? name,
    String? username,
    String? dateOfBirth,
    String? gender,
    String? bio,
    String? avatar,
  }) {
    return Profile(
      name: name ?? this.name,
      username: username ?? this.username,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      bio: bio ?? this.bio,
      avatar: avatar ?? this.avatar,
    );
  }
}

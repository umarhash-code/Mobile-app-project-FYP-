class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final String? bio;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? lastLoginAt;
  final bool isActive;

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    this.bio,
    this.photoUrl,
    required this.createdAt,
    this.updatedAt,
    this.lastLoginAt,
    this.isActive = true,
  });

  // Convert UserModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'bio': bio,
      'photoUrl': photoUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'isActive': isActive,
    };
  }

  // Create UserModel from Firestore Map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? '',
      bio: map['bio'],
      photoUrl: map['photoUrl'],
      createdAt: map['createdAt'] != null
          ? _parseDateTime(map['createdAt'])
          : DateTime.now(),
      updatedAt:
          map['updatedAt'] != null ? _parseDateTime(map['updatedAt']) : null,
      lastLoginAt: map['lastLoginAt'] != null
          ? _parseDateTime(map['lastLoginAt'])
          : null,
      isActive: map['isActive'] ?? true,
    );
  }

  // Helper method to parse DateTime from various formats
  static DateTime _parseDateTime(dynamic value) {
    if (value is String) {
      return DateTime.parse(value);
    } else if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    } else {
      return DateTime.now();
    }
  }

  // Create a copy with updated fields
  UserModel copyWith({
    String? uid,
    String? email,
    String? fullName,
    String? bio,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
    bool? isActive,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      bio: bio ?? this.bio,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isActive: isActive ?? this.isActive,
    );
  }

  // Get user initials for avatar
  String get initials {
    List<String> names = fullName.split(' ');
    String initials = '';

    for (int i = 0; i < names.length && i < 2; i++) {
      if (names[i].isNotEmpty) {
        initials += names[i][0].toUpperCase();
      }
    }

    return initials.isEmpty ? 'U' : initials;
  }

  // Get first name only
  String get firstName {
    List<String> names = fullName.split(' ');
    return names.isNotEmpty ? names[0] : fullName;
  }

  // Check if user has completed profile
  bool get hasCompletedProfile {
    return fullName.isNotEmpty && bio != null && bio!.isNotEmpty;
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, fullName: $fullName, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserModel &&
        other.uid == uid &&
        other.email == email &&
        other.fullName == fullName;
  }

  @override
  int get hashCode {
    return uid.hashCode ^ email.hashCode ^ fullName.hashCode;
  }
}

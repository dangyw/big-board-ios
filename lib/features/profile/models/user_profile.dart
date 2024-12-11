class UserProfile {
  final String id;
  final String userId;
  final String displayName;
  final String? username;
  final String? email;
  final String? photoURL;
  final String? avatarUrl;
  final double unitValue;
  final double bankroll;
  final int parlayCount;
  final DateTime createdAt;
  final DateTime joinedAt;
  final List<String>? parlayIds;

  UserProfile({
    required this.id,
    required this.userId,
    required this.displayName,
    this.username,
    this.email,
    this.photoURL,
    this.avatarUrl,
    required this.unitValue,
    this.bankroll = 0.0,
    this.parlayCount = 0,
    required this.createdAt,
    required this.joinedAt,
    this.parlayIds,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map, String userId) {
    return UserProfile(
      id: map['id'],
      userId: userId,
      displayName: map['display_name'] ?? '',
      email: map['email'],
      photoURL: map['photo_url'],
      avatarUrl: map['avatar_url'],
      unitValue: (map['unit_value'] ?? 10.0).toDouble(),
      bankroll: (map['bankroll'] ?? 0.0).toDouble(),
      parlayCount: map['parlay_count'] ?? 0,
      createdAt: DateTime.parse(map['created_at']),
      joinedAt: DateTime.parse(map['joined_at']),
      parlayIds: map['parlay_ids'] as List<String>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'display_name': displayName,
      'email': email,
      'photo_url': photoURL,
      'avatar_url': avatarUrl,
      'unit_value': unitValue,
      'bankroll': bankroll,
      'parlay_count': parlayCount,
      'created_at': createdAt.toIso8601String(),
      'joined_at': joinedAt.toIso8601String(),
      'parlay_ids': parlayIds,
    };
  }

  UserProfile copyWith({
    String? displayName,
    String? email,
    String? photoURL,
    String? avatarUrl,
    double? unitValue,
    double? bankroll,
    int? parlayCount,
    List<String>? parlayIds,
  }) {
    return UserProfile(
      id: this.id,
      userId: this.userId,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoURL: photoURL ?? this.photoURL,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      unitValue: unitValue ?? this.unitValue,
      bankroll: bankroll ?? this.bankroll,
      parlayCount: parlayCount ?? this.parlayCount,
      createdAt: this.createdAt,
      joinedAt: this.joinedAt,
      parlayIds: parlayIds ?? this.parlayIds,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      displayName: json['display_name'] ?? '',
      username: json['username'] as String?,
      email: json['email'],
      photoURL: json['photo_url'],
      avatarUrl: json['avatar_url'],
      unitValue: json['unit_value']?.toDouble() ?? 10.0,
      bankroll: json['bankroll']?.toDouble() ?? 1000.0,
      parlayCount: json['parlay_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      joinedAt: DateTime.parse(json['joined_at']),
      parlayIds: json['parlay_ids'] as List<String>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'display_name': displayName,
      'username': username,
      'email': email,
      'photo_url': photoURL,
      'avatar_url': avatarUrl,
      'unit_value': unitValue,
      'bankroll': bankroll,
      'parlay_count': parlayCount,
      'created_at': createdAt.toIso8601String(),
      'joined_at': joinedAt.toIso8601String(),
      'parlay_ids': parlayIds,
    };
  }
} 
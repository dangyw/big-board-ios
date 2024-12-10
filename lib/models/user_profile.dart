class UserProfile {
  final String userId;
  final String displayName;
  final String? email;
  final String? photoURL;
  final double unitValue;
  final double bankroll;
  final int parlayCount;
  final DateTime createdAt;
  final DateTime joinedAt;

  UserProfile({
    required this.userId,
    required this.displayName,
    this.email,
    this.photoURL,
    required this.unitValue,
    this.bankroll = 0.0,
    this.parlayCount = 0,
    required this.createdAt,
    required this.joinedAt,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map, String userId) {
    return UserProfile(
      userId: userId,
      displayName: map['display_name'] ?? '',
      email: map['email'],
      photoURL: map['photo_url'],
      unitValue: (map['unit_value'] ?? 10.0).toDouble(),
      bankroll: (map['bankroll'] ?? 0.0).toDouble(),
      parlayCount: map['parlay_count'] ?? 0,
      createdAt: DateTime.parse(map['created_at']),
      joinedAt: DateTime.parse(map['joined_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'display_name': displayName,
      'email': email,
      'photo_url': photoURL,
      'unit_value': unitValue,
      'bankroll': bankroll,
      'parlay_count': parlayCount,
      'created_at': createdAt.toIso8601String(),
      'joined_at': joinedAt.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? displayName,
    String? email,
    String? photoURL,
    double? unitValue,
    double? bankroll,
    int? parlayCount,
  }) {
    return UserProfile(
      userId: this.userId,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoURL: photoURL ?? this.photoURL,
      unitValue: unitValue ?? this.unitValue,
      bankroll: bankroll ?? this.bankroll,
      parlayCount: parlayCount ?? this.parlayCount,
      createdAt: this.createdAt,
      joinedAt: this.joinedAt,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['user_id'],
      displayName: json['display_name'],
      email: json['email'],
      photoURL: json['photo_url'],
      unitValue: json['unit_value']?.toDouble() ?? 10.0,
      bankroll: json['bankroll']?.toDouble() ?? 1000.0,
      parlayCount: json['parlay_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      joinedAt: DateTime.parse(json['joined_at']),
    );
  }
} 
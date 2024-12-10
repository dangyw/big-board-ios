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
    this.unitValue = 10.0,
    this.bankroll = 1000.0,
    this.parlayCount = 0,
    required this.createdAt,
    DateTime? joinedAt,
  }) : joinedAt = joinedAt ?? createdAt;

  factory UserProfile.fromMap(Map<String, dynamic> map, String id) {
    return UserProfile(
      userId: id,
      displayName: map['displayName'],
      email: map['email'],
      photoURL: map['photoURL'],
      unitValue: (map['unitValue'] ?? 0.0).toDouble(),
      bankroll: (map['bankroll'] ?? 0.0).toDouble(),
      parlayCount: map['parlayCount'] ?? 0,
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      joinedAt: map['joinedAt']?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'displayName': displayName,
      'email': email,
      'photoURL': photoURL,
      'unitValue': unitValue,
      'bankroll': bankroll,
      'parlayCount': parlayCount,
      'createdAt': createdAt,
      'joinedAt': joinedAt,
    };
  }
} 
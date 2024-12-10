class UserModel {
  final String uid;
  final String? email;
  final String? displayName;
  final List<String>? parlayIds;

  UserModel({
    required this.uid,
    this.email,
    this.displayName,
    this.parlayIds,
  });

  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'],
      email: data['email'],
      displayName: data['displayName'],
      parlayIds: List<String>.from(data['parlayIds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'parlayIds': parlayIds,
    };
  }
} 
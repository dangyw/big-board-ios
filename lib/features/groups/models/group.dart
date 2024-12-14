import 'package:big_board/features/profile/models/user_profile.dart';

class Group {
  final String id;
  final String name;
  final String ownerId;
  final DateTime createdAt;
  final String? description;
  final String? avatarUrl;
  final List<GroupMember> members;

  Group({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.createdAt,
    this.description,
    this.avatarUrl,
    this.members = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'owner_id': ownerId,
    'created_at': createdAt.toIso8601String(),
    'description': description,
    'avatar_url': avatarUrl,
  };

  factory Group.fromJson(Map<String, dynamic> json) {
    var groupMembers = <GroupMember>[];
    if (json['group_members'] != null) {
      groupMembers = (json['group_members'] as List)
          .map((member) => GroupMember.fromJson(member))
          .toList();
    }

    return Group(
      id: json['id'],
      name: json['name'],
      ownerId: json['owner_id'],
      createdAt: DateTime.parse(json['created_at']),
      description: json['description'],
      avatarUrl: json['avatar_url'],
      members: groupMembers,
    );
  }

  List<String> get memberIds => members.map((m) => m.userId).toList();

  @override
  String toString() {
    return 'Group(name: $name, id: $id, memberCount: ${members.length})';
  }
}

class GroupMember {
  final String id;
  final String groupId;
  final String userId;
  final DateTime createdAt;
  final UserProfile? profile;

  GroupMember({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.createdAt,
    this.profile,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) => GroupMember(
    id: json['id'],
    groupId: json['group_id'] ?? '',
    userId: json['user_id'],
    createdAt: DateTime.parse(json['created_at']),
    profile: json['user_profiles'] != null
        ? UserProfile.fromJson(json['user_profiles'])
        : null,
  );

  String get name => profile?.displayName ?? 'Unknown User';
} 
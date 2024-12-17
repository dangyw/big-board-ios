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
    'group_members': members.map((m) => m.toJson()).toList(),
  };

  factory Group.fromJson(Map<String, dynamic> json) {
    print('Parsing group JSON: $json');
    var groupMembers = <GroupMember>[];
    if (json['group_members'] != null) {
      print('Parsing ${json['group_members'].length} members');
      groupMembers = (json['group_members'] as List)
          .map((member) {
            print('Parsing member: $member');
            return GroupMember.fromJson(member);
          })
          .toList();
    }

    final group = Group(
      id: json['id'],
      name: json['name'],
      ownerId: json['owner_id'],
      createdAt: DateTime.parse(json['created_at']),
      description: json['description'],
      avatarUrl: json['avatar_url'],
      members: groupMembers,
    );
    print('Successfully parsed group: ${group.name}');
    return group;
  }

  List<String> get memberIds => members.map((m) => m.userId).toList();
}

class GroupMember {
  final String id;
  final String groupId;
  final String userId;
  final DateTime createdAt;
  final String name;
  final UserProfile? profile;

  GroupMember({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.createdAt,
    required this.name,
    this.profile,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    print('Creating GroupMember from JSON: $json');
    
    final profileData = json['user_profiles'] as Map<String, dynamic>?;
    final name = profileData?['display_name'] ?? 'Unknown User';
    
    return GroupMember(
      id: json['id'],
      groupId: json['group_id'] ?? '',
      userId: json['user_id'],
      createdAt: DateTime.parse(json['created_at']),
      name: name,
      profile: profileData != null ? UserProfile.fromJson(profileData) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'group_id': groupId,
    'user_id': userId,
    'created_at': createdAt.toIso8601String(),
    'name': name,
    'profile': profile?.toJson(),
  };

  String get displayName => profile?.displayName ?? name;
}
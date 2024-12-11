import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/group.dart';

class GroupsService {
  final _supabase = Supabase.instance.client;

  Future<List<Group>> getUserGroups(String userId) async {
    try {
      final response = await _supabase
          .from('groups')
          .select('''
        *,
        group_members!inner(*)
      ''')
          .eq('group_members.user_id', userId);

      if (response == null) {
        print('No groups found for user: $userId');
        return [];
      }

      print('Raw groups response: $response'); // Debug print

      return (response as List)
          .map((group) => Group.fromJson(group))
          .toList();
    } catch (e) {
      print('Error fetching user groups: $e');
      return [];
    }
  }

  Future<Group?> createGroup({
    required String name,
    required String ownerId,
    String? description,
    String? avatarUrl,
  }) async {
    try {
      // First create the group
      final groupResponse = await _supabase
          .from('groups')
          .insert({
            'name': name,
            'owner_id': ownerId,
            'description': description,
            'avatar_url': avatarUrl,
          })
          .select()
          .single();

      // Then add the owner as a member
      await _supabase
          .from('group_members')
          .insert({
            'group_id': groupResponse['id'],
            'user_id': ownerId,
          });

      // Get the complete group data including members
      return getUserGroups(ownerId)
          .then((groups) => groups.firstWhere((g) => g.id == groupResponse['id']));
    } catch (e) {
      print('Error creating group: $e');
      return null;
    }
  }

  Future<bool> addMember(String groupId, String userId) async {
    try {
      await _supabase
          .from('group_members')
          .insert({
            'group_id': groupId,
            'user_id': userId,
          });
      return true;
    } catch (e) {
      print('Error adding member to group: $e');
      return false;
    }
  }

  Future<bool> removeMember(String groupId, String userId) async {
    try {
      await _supabase
          .from('group_members')
          .delete()
          .match({
            'group_id': groupId,
            'user_id': userId,
          });
      return true;
    } catch (e) {
      print('Error removing member from group: $e');
      return false;
    }
  }
} 
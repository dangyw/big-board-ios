import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:big_board/features/groups/models/group.dart';

class GroupsService {
  final _supabase = Supabase.instance.client;

  Future<List<Group>> getUserGroups(String userId) async {
    try {
      print('Fetching groups for user: $userId');
      
      final groupsResponse = await _supabase
          .from('group_members')
          .select('group_id')
          .eq('user_id', userId);

      print('Initial groups response: $groupsResponse');

      if (groupsResponse == null || groupsResponse.isEmpty) {
        print('No groups found in group_members table');
        return [];
      }

      final groupIds = (groupsResponse as List).map((g) => g['group_id']).toList();
      print('Found group IDs: $groupIds');

      final response = await _supabase
          .from('groups')
          .select('''
            *,
            group_members (
              id,
              user_id,
              created_at
            )
          ''')
          .inFilter('id', groupIds);

      print('Groups table response: $response');

      if (response != null && response is List && response.isNotEmpty) {
        for (var group in response) {
          if (group['group_members'] != null) {
            for (var member in group['group_members']) {
              final profileResponse = await _supabase
                  .from('user_profiles')
                  .select()
                  .eq('user_id', member['user_id'])
                  .single();
              
              
              if (profileResponse != null) {
                member['user_profiles'] = profileResponse;
              }
            }
          }
        }

        final groups = (response as List)
            .map((group) => Group.fromJson(group))
            .toList();
        
        return groups;
      }

      return [];
    } catch (e) {
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
      return false;
    }
  }
} 
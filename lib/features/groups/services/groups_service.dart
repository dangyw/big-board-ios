import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:big_board/features/groups/models/group.dart';

class GroupsService {
  final _supabase = Supabase.instance.client;

  Future<List<Group>> getUserGroups(String userId) async {
      print('\n=== Starting getUserGroups in GroupsService ===\n');  // Add this
    try {
     print('Fetching groups for user: $userId');  // Add this      
      final groupsResponse = await _supabase
          .from('group_members')
          .select('group_id')
          .eq('user_id', userId);

      print('DEBUG: Raw group_members response: $groupsResponse');

      if (groupsResponse == null || groupsResponse.isEmpty) {
        print('No groups found for user: $userId');
        return [];
      }

      final groupIds = (groupsResponse as List).map((g) => g['group_id']).toList();
      print('DEBUG: Found group IDs: $groupIds');

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

      print('\nDEBUG: Raw groups response: $response\n');

      if (response != null && response is List && response.isNotEmpty) {
        for (var group in response) {
          print('\nProcessing group: ${group['name']}');
          if (group['group_members'] != null) {
            for (var member in group['group_members']) {
              print('\nFetching profile for member: ${member['user_id']}');
              final profileResponse = await _supabase
                  .from('user_profiles')
                  .select()
                  .eq('user_id', member['user_id'])
                  .single();
              
              print('Profile response: $profileResponse');
              
              if (profileResponse != null) {
                member['user_profiles'] = profileResponse;
                print('Added profile to member: ${member['user_profiles']}');
              }
            }
          }
        }

        final groups = (response as List)
            .map((group) => Group.fromJson(group))
            .toList();
        
        print('\n=== Final processed groups: $groups ===\n');
        return groups;
      }

      return [];
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
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:big_board/features/parlays/models/saved_parlay.dart';
import 'package:big_board/features/parlays/models/parlay_invitation.dart';
import 'dart:async';
import 'package:big_board/features/parlays/models/placeholder_pick.dart';

class ParlayService {
  final _supabase = Supabase.instance.client;
  final _streamController = StreamController<List<SavedParlay>>.broadcast();

  Stream<List<SavedParlay>> getParlays({String? groupId}) async* {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      if (groupId != null) {
        final data = await _supabase
            .from('parlays')
            .select()
            .eq('group_id', groupId)
            .order('created_at', ascending: false);
        yield data.map((json) => SavedParlay.fromJson(json)).toList();
      } else {
        final data = await _supabase
            .from('parlays')
            .select()
            .eq('user_id', user.id)
            .order('created_at', ascending: false);
        yield data.map((json) => SavedParlay.fromJson(json)).toList();
      }

      // Set up real-time subscription
      await _initParlayStream(groupId);

    } catch (e) {
      print('Error in getParlays: $e');
      yield [];
    }
  }

  Future<void> _refreshParlays({String? groupId}) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final query = _supabase.from('parlays').select();
      
      if (groupId != null) {
        query.eq('group_id', groupId);
      } else {
        query.eq('user_id', user.id);
      }
      
      final data = await query.order('created_at', ascending: false);
      final parlays = data.map((json) => SavedParlay.fromJson(json)).toList();
      _streamController.add(parlays);
    } catch (e) {
      print('Error refreshing parlays: $e');
    }
  }

  Future<void> saveParlay(SavedParlay parlay) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final parlayJson = parlay.toJson();
      parlayJson.remove('id');  // Remove the id field and let Supabase generate it

      // First save the parlay
      final response = await _supabase
          .from('parlays')
          .insert(parlayJson)
          .select()
          .single();

      final parlayId = response['id'];

      // If this is a group parlay with placeholder picks, create the picks
      if (parlay.groupId != null && parlay.placeholderPicks != null) {
        for (var pick in parlay.placeholderPicks!) {
          await _supabase.from('parlay_picks').insert({
            'parlay_id': parlayId,
            'assigned_member_id': pick.assignedUserId,
            'status': 'pending',
            'team_name': pick.teamName,
            'opponent': pick.opponent,
            'bet_type': pick.betType,
            'spread_value': pick.spreadValue,
            'odds': pick.odds,
          });
        }
      }

      await _refreshParlays(groupId: parlay.groupId);
    } catch (e) {
      print('Error saving parlay: $e');
      rethrow;
    }
  }

  Future<void> deleteParlay(String parlayId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _supabase
          .from('parlays')
          .delete()
          .eq('id', parlayId);
        
      print('Parlay deleted successfully: $parlayId');
      
      // Force refresh after delete
      await _refreshParlays();
      
    } catch (e) {
      print('Error deleting parlay: $e');
      rethrow;
    }
  }

  Stream<List<SavedParlay>> getGroupParlays(String groupId) {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Initial load and setup stream
      _refreshGroupParlays(groupId);

      return _streamController.stream;
    } catch (e) {
      print('Error in getGroupParlays: $e');
      rethrow;
    }
  }

  Future<void> _refreshGroupParlays(String groupId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final data = await _supabase
          .from('parlays')
          .select()
          .eq('group_id', groupId)
          .order('created_at', ascending: false);

      final parlays = data.map((json) => SavedParlay.fromJson(json)).toList();
      _streamController.add(parlays);
    } catch (e) {
      print('Error refreshing group parlays: $e');
    }
  }

  void dispose() {
    _streamController.close();
  }

  Future<void> inviteToParlay({
    required String parlayId,
    required String inviteeId,
  }) async {
    try {
      await _supabase.from('parlay_invitations').insert({
        'parlay_id': parlayId,
        'inviter_id': _supabase.auth.currentUser!.id,
        'invitee_id': inviteeId,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error inviting to parlay: $e');
      rethrow;
    }
  }

  Future<void> acceptInvitation(String invitationId) async {
    try {
      await _supabase.rpc(
        'accept_parlay_invitation',
        params: {'invitation_id_param': invitationId},
      );
    } catch (e) {
      print('Error accepting invitation: $e');
      rethrow;
    }
  }

  Future<void> declineInvitation(String invitationId) async {
    try {
      await _supabase
          .from('parlay_invitations')
          .update({'status': 'declined'})
          .eq('id', invitationId);
    } catch (e) {
      print('Error declining invitation: $e');
      rethrow;
    }
  }

  Future<List<ParlayInvitation>> getPendingInvitations() async {
    try {
      final response = await _supabase
          .from('parlay_invitations')
          .select()
          .eq('invitee_id', _supabase.auth.currentUser!.id)
          .eq('status', 'pending');
      
      return (response as List)
          .map((data) => ParlayInvitation.fromMap(data))
          .toList();
    } catch (e) {
      print('Error getting pending invitations: $e');
      rethrow;
    }
  }

  Future<String> createGroupParlay(String creatorId, String groupId, List<PlaceholderPick> picks) async {
    final response = await _supabase.from('parlays').insert({
      'creator_id': creatorId,
      'group_id': groupId,
      'status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
    }).select().single();

    final parlayId = response['id'];

    // Create placeholder picks
    for (var pick in picks) {
      await _supabase.from('parlay_picks').insert({
        'parlay_id': parlayId,
        'assigned_member_id': pick.assignedUserId,
        'status': 'pending',
      });
    }

    return parlayId;
  }

  Future<void> submitPick(String parlayId, String memberId, String gameId, String team, String betType) async {
    await _supabase.from('parlay_picks')
        .update({
          'game_id': gameId,
          'selected_team': team,
          'bet_type': betType,
          'status': 'completed'
        })
        .eq('parlay_id', parlayId)
        .eq('assigned_member_id', memberId);
  }

  Future<void> _initParlayStream(String? groupId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        _streamController.add([]);
        return;
      }

      final channel = _supabase.channel('public:parlays');
      
      await channel.subscribe((status, [context]) {
        if (status == 'SUBSCRIBED') {
          // Initial subscription successful
          return;
        }

        if (context == null) return;

        final payload = context as Map<String, dynamic>;
        if (!payload.containsKey('new')) return;

        final newRecord = payload['new'] as Map<String, dynamic>;
        final recordGroupId = newRecord['group_id'] as String?;
        final recordUserId = newRecord['user_id'] as String?;

        if ((groupId != null && recordGroupId == groupId) ||
            (groupId == null && recordUserId == user.id)) {
          _refreshParlays(groupId: groupId);
        }
      });

    } catch (e) {
      print('Error in _initParlayStream: $e');
    }
  }

  Future<void> updatePlaceholderPick(
    String parlayId, 
    String memberId, 
    SavedPick pick
  ) async {
    try {
      await _supabase.from('parlay_picks').update({
        'team_name': pick.teamName,
        'opponent': pick.opponent,
        'bet_type': pick.betType,
        'spread_value': pick.spreadValue,
        'odds': pick.odds,
        'status': 'completed'
      })
      .eq('parlay_id', parlayId)
      .eq('assigned_member_id', memberId);

      await _refreshParlays();
    } catch (e) {
      print('Error updating placeholder pick: $e');
      rethrow;
    }
  }
} 